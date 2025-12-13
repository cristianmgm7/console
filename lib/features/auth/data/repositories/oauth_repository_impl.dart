import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/pkce_generator.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/auth/data/datasources/oauth_local_datasource.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

@LazySingleton(as: OAuthRepository)
class OAuthRepositoryImpl implements OAuthRepository {

  OAuthRepositoryImpl(
    this._localDataSource,
    this._logger,
  );

  final OAuthLocalDataSource _localDataSource;
  final Logger _logger;

  oauth2.Client? _client;

  // Store code verifiers for desktop OAuth (since we can't use sessionStorage)
  final Map<String, String> _desktopOAuthStates = {};

  // This method is used to get the authorization URL for the web platform
  @override
  Future<Result<String>> getAuthorizationUrl() async {
    try {
      // Validate client_id is not the default value
      if (OAuthConfig.clientId == 'YOUR_CLIENT_ID' || OAuthConfig.clientId.isEmpty) {
        _logger.e('Invalid client_id: ${OAuthConfig.clientId}');
        return failure(const ConfigurationFailure(
          details:
              'OAuth client_id is not configured. Please set OAUTH_CLIENT_ID environment variable.',
        ),);
      }

      // Generate PKCE codes manually to be able to save them
      final codeVerifier = PKCEGenerator.generateCodeVerifier();
      final codeChallenge = PKCEGenerator.generateCodeChallenge(codeVerifier);
      final state = PKCEGenerator.generateState();

      // Save the codeVerifier and state
      if (kIsWeb) {
        await _localDataSource.saveOAuthState(state, codeVerifier);
      } else {
        _desktopOAuthStates[state] = codeVerifier;
      }

      // Use configured redirect URI for all platforms
      const redirectUri = OAuthConfig.redirectUrl;

      // Manually build the authorization URL with PKCE
      final authUrl = Uri.parse(OAuthConfig.authorizationEndpoint).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': OAuthConfig.clientId,
          'redirect_uri': redirectUri,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'scope': OAuthConfig.scopes.join(' '),
          'state': state,
        },
      );
      return success(authUrl.toString());
    } on Exception catch (e, stack) {
      _logger.e('Error creating authorization URL', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    } on StackTrace catch (e) {
      _logger.e('Error creating authorization URL', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Desktop OAuth flow - opens browser and waits for deep link callback
  @override
  Future<Result<oauth2.Client>> loginWithDesktop() async {
    if (kIsWeb) {
      _logger.e('Desktop OAuth not available on web');
      return failure(const ConfigurationFailure(
        details: 'Desktop OAuth is only available on desktop platforms',
      ),);
    }
    try {
      final urlResult = await getAuthorizationUrl();

      return urlResult.fold(
        onSuccess: (authUrl) async {
          // Just open the browser - the callback will be handled via deep linking
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched) {
              return failure(const AuthFailure(
                code: 'LAUNCH_FAILED',
                details: 'Could not open browser for authentication',
              ),);
            }
            // Return a pending state - the actual auth will complete via deep link
            return failure(const AuthFailure(
              code: 'PENDING',
              details: 'Waiting for browser authentication...',
            ),);
          } else {
            return failure(AuthFailure(
              code: 'CANNOT_LAUNCH',
              details: 'Could not launch URL: $authUrl',
            ),);
          }
        },
        onFailure: (error) {
          return failure(error.failure);
        },
      );
    } on Exception catch (e, stack) {
      _logger.e('❌ Desktop OAuth failed', error: e, stackTrace: stack);
      return failure(AuthFailure(
        code: 'DESKTOP_OAUTH_FAILED',
        details: 'Desktop OAuth flow failed: $e',
      ),);
    }
  }

  @override
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl) async {
    try {
      final responseUri = Uri.parse(responseUrl);
      final code = responseUri.queryParameters['code'];
      final state = responseUri.queryParameters['state'];
      final error = responseUri.queryParameters['error'];

      // If there is an error in the response
      if (error != null) {
        return failure(AuthFailure(
          code: error,
          details: responseUri.queryParameters['error_description'] ?? 'Authorization failed',
        ),);
      }

      // If there is no authorization code
      if (code == null) {
        return failure(const AuthFailure(
          code: 'NO_CODE',
          details: 'No authorization code received',
        ),);
      }

      // Retrieve the codeVerifier using the state
      if (state == null) {
        return failure(const AuthFailure(
          code: 'NO_STATE',
          details: 'No state parameter received',
        ),);
      }

      String? codeVerifier;
      
      if (kIsWeb) {
        final oauthState = await _localDataSource.loadOAuthState(state);
        if (oauthState == null ||
            oauthState['codeVerifier'] == null ||
            oauthState['codeVerifier']!.isEmpty) {
          _logger.e('No codeVerifier found in sessionStorage for state: $state');
          return failure(const AuthFailure(
            code: 'NO_CODE_VERIFIER',
            details: 'No authorization grant found. Please try logging in again.',
          ),);
        }
        codeVerifier = oauthState['codeVerifier'];
      } else {
        codeVerifier = _desktopOAuthStates[state];
        if (codeVerifier == null || codeVerifier.isEmpty) {
          _logger.e('No codeVerifier found in memory for state: $state');
          return failure(const AuthFailure(
            code: 'NO_CODE_VERIFIER',
            details: 'No authorization grant found. Please try logging in again.',
          ),);
        }
        _desktopOAuthStates.remove(state);
      }

      // Use configured redirect URI for all platforms
      const redirectUri = OAuthConfig.redirectUrl;

      final tokenBody = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': OAuthConfig.clientId,
        'client_secret': OAuthConfig.clientSecret,
        'code_verifier': codeVerifier,
      };

      http.Response tokenResponse;
      try {
        tokenResponse = await http
            .post(
              OAuthConfig.tokenEndpointUri,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: tokenBody,
            )
            .timeout(
              const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
              onTimeout: () {
                _logger.e('Token exchange timeout after ${OAuthConfig.apiTimeoutSeconds}s');
                throw TimeoutException(
                  'Token exchange timed out after ${OAuthConfig.apiTimeoutSeconds} seconds',
                  const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
                );
              },
            );
      } on SocketException catch (e) {
        _logger.e('Network error during token exchange', error: e);
        final errorMessage = e.message.toLowerCase();
        String details;
        
        if (errorMessage.contains('operation not permitted') || 
            errorMessage.contains('errno = 1')) {
          details = 'macOS Firewall is blocking the connection. '
              'Please go to System Settings → Network → Firewall and temporarily disable it for development. '
              'See MACOS_NETWORK_PERMISSIONS.md for details.';
        } else {
          details = 'Failed to connect to the server. Please check your internet connection and try again. '
              'If the problem persists, it may be a macOS network permission issue.';
        }
        
        return failure(NetworkFailure(details: details));
      } on TimeoutException catch (e) {
        _logger.e('Token exchange timeout', error: e);
        return failure(const NetworkFailure(
          details: 'Request timed out. Please check your internet connection and try again.',
        ),);
      } on Exception catch (e) {
        _logger.e('Unexpected error during token exchange', error: e);
        return failure(NetworkFailure(
          details: 'An unexpected network error occurred: $e',
        ),);
      }

      if (tokenResponse.statusCode != 200) {
        _logger.e('Token exchange failed', error: tokenResponse.body);

        try {
          final errorJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
          return failure(AuthFailure(
            code: errorJson['error']?.toString() ?? 'TOKEN_EXCHANGE_FAILED',
            details: errorJson['error_description']?.toString() ?? 'Token exchange failed',
          ),);
        } on Exception catch (e) {
          _logger.e('Error parsing token response', error: e);
          return failure(AuthFailure(
            code: 'TOKEN_EXCHANGE_FAILED',
            details: 'Token exchange failed: ${tokenResponse.body}',
          ),);
        }
      }

      // Parse the token response
      final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;

      final expiresIn = tokenJson['expires_in'] as int? ?? 3600;

      final credentialsJson = <String, dynamic>{
        'accessToken': tokenJson['access_token'] as String,
        'tokenType': tokenJson['token_type'] as String? ?? 'Bearer',
        'expiresIn': expiresIn,
        'scopes': tokenJson['scope'] is List
            ? (tokenJson['scope'] as List).map((e) => e.toString()).toList()
            : (tokenJson['scope'] as String?)?.split(' ') ?? [],
      };

      if (tokenJson.containsKey('refresh_token') && tokenJson['refresh_token'] != null) {
        credentialsJson['refreshToken'] = tokenJson['refresh_token'] as String;
      }

      final expirationDateTime = DateTime.now().add(Duration(seconds: expiresIn));
      credentialsJson['expiration'] =
          expirationDateTime.millisecondsSinceEpoch;

      final jsonString = jsonEncode(credentialsJson);

      oauth2.Credentials credentials;
      try {
        credentials = oauth2.Credentials.fromJson(jsonString);
      } on Exception catch (e) {
        _logger.e('Error creating credentials', error: e);
        rethrow;
      }

      _client = oauth2.Client(
        credentials,
        identifier: OAuthConfig.clientId,
        secret: OAuthConfig.clientSecret,
      );

      await _localDataSource.saveCredentials(credentials);

      await _localDataSource.clearOAuthState(state);

      return success(_client!);
    } on oauth2.AuthorizationException catch (e) {
      _logger.e('OAuth authorization error', error: e);
      return failure(AuthFailure(
        code: e.error,
        details: e.description ?? 'Authorization failed',
      ),);
    } on Exception catch (e) {
      _logger.e('Error handling authorization response', error: e);
      _logger.e('Error type: ${e.runtimeType}');
      _logger.e('Error message: $e');
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client?>> loadSavedClient() async {
    try {
      final credentials = await _localDataSource.loadCredentials();
      if (credentials == null) {
        return success(null);
      }

      _client = oauth2.Client(
        credentials,
        identifier: OAuthConfig.clientId,
        secret: OAuthConfig.clientSecret,
      );

      return success(_client);
    } on Exception catch (e) {
      _logger.e('Error loading saved client', error: e);
      return success(null); // Return null on error, not failure
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      if (_client != null && !_client!.credentials.isExpired) {
        return success(true);
      }

      final result = await loadSavedClient();
      return result.fold(
        onSuccess: (client) => success(client != null && !client.credentials.isExpired),
        onFailure: (_) => success(false),
      );
    } on Exception catch (e) {
      _logger.e('Error checking authentication', error: e);
      return success(false);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      _client?.close();
      _client = null;

      await _localDataSource.deleteCredentials();

      return success(null);
    } on Exception catch (e) {
      _logger.e('Error during logout', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client?>> getClient() async {
    try {
      if (_client != null) {
        return success(_client);
      }
      return await loadSavedClient();
    } on Exception catch (e) {
      _logger.e('Error getting client', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

}
