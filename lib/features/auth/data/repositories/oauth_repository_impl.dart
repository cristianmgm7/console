import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/oauth_desktop_server.dart';
import 'package:carbon_voice_console/core/utils/pkce_generator.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/auth/data/datasources/oauth_local_datasource.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/oauth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

@LazySingleton(as: OAuthRepository)
class OAuthRepositoryImpl implements OAuthRepository {

  OAuthRepositoryImpl(
    this._localDataSource,
    this._logger,
  ) : _desktopServer = kIsWeb ? null : OAuthDesktopServer();

  final OAuthLocalDataSource _localDataSource;
  final OAuthDesktopServer? _desktopServer;
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

      // Determine redirect URI according to platform
      const redirectUri = kIsWeb ? OAuthConfig.redirectUrl : 'http://localhost:3000/auth/callback';

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

  /// Desktop OAuth flow - handles everything including opening browser and capturing callback
  @override
  Future<Result<oauth2.Client>> loginWithDesktop() async {
    if (_desktopServer == null || kIsWeb) {
      _logger.e('Desktop server not available (kIsWeb: $kIsWeb)');
      return failure(const ConfigurationFailure(
        details: 'Desktop OAuth is only available on desktop platforms',
      ),);
    }
    try {
      final urlResult = await getAuthorizationUrl();
      
      return urlResult.fold(
        onSuccess: (authUrl) async {
          final callbackUrl = await _desktopServer.authenticate(authUrl);
          return handleAuthorizationResponse(callbackUrl);
        },
        onFailure: (error) {
          return failure(error.failure);
        },
      );
    } on Exception catch (e, stack) {
      _logger.e('❌ Desktop OAuth failed', error: e, stackTrace: stack);
      await _desktopServer.close(); // Cleanup
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

      // Use the correct redirect URI according to the platform
      const redirectUri = kIsWeb ? OAuthConfig.redirectUrl : 'http://localhost:3000/auth/callback';

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
  Future<Result<String>> getPxToken() async {
    try {
      final clientResult = await getClient();
      final client = clientResult.fold(
        onSuccess: (client) => client,
        onFailure: (_) => null,
      );

      if (client == null) {
        return failure(const UnknownFailure(details: 'Not authenticated'));
      }

      final accessToken = client.credentials.accessToken;

      // Try POST request with token in JSON body (avoiding URL encoding issues)
      const exchangeUrl = '${OAuthConfig.apiBaseUrl}/token/access/exchange';
      _logger.d('Fetching PX token from exchange endpoint (POST): $exchangeUrl');
      _logger.d('Sending access token in JSON body');

      _logger.d('About to make HTTP POST request to /token/access/exchange...');
      http.Response? response;
      try {
        response = await http.post(
          Uri.parse(exchangeUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': accessToken}),
        ).timeout(const Duration(seconds: 10));
        _logger.d('HTTP request completed, got response');
        _logger.d('Exchange response status: ${response.statusCode}');
      } on Exception catch (e) {
        _logger.e('Network error during exchange request: $e');
        if (e is http.ClientException) {
          _logger.e('ClientException details: ${e.message}');
          _logger.e('URI that failed: ${e.uri}');
        }
        return failure(UnknownFailure(details: 'Network error during token exchange: $e'));
      }

      if (response.statusCode != 200) {
        _logger.e('Exchange request failed: ${response.body}');
        return failure(UnknownFailure(details: 'Failed to get PX token: ${response.statusCode} - ${response.body}'));
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      _logger.d('Exchange response keys: ${responseData.keys.toList()}');

      final pxToken = responseData['pxtoken'] as String?;

      if (pxToken == null || pxToken.isEmpty) {
        _logger.e('Available keys: ${responseData.keys.toList()}');
        return failure(UnknownFailure(details: 'PX token not found in response. Available keys: ${responseData.keys.toList()}'));
      }

      _logger.i('Successfully obtained PX token');
      return success(pxToken);
    } on Exception catch (e, stack) {
      _logger.e('Error fetching PX token', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: 'Error fetching PX token: $e'));
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

  /// Decodes a JWT token and returns the payload
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      // Add padding if needed
      final normalizedPayload = base64Url.normalize(payload);
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error decoding JWT token', error: e);
      return null;
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserInfo() async {
    try {
      final clientResult = await getClient();
      final client = clientResult.fold(
        onSuccess: (client) => client,
        onFailure: (_) => null,
      );

      if (client == null) {
        return failure(const UnknownFailure(details: 'Not authenticated'));
      }

      // Try /whoami endpoint first - this should return current user profile directly
      const whoamiUrl = '${OAuthConfig.apiBaseUrl}/whoami';
      _logger.d('Fetching current user profile from: $whoamiUrl');

      try {
        final response = await client.get(Uri.parse(whoamiUrl));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          _logger.d('Raw response from /whoami: $responseData');

          // Extract user data from the "user" key
          final userData = responseData['user'] as Map<String, dynamic>;
          _logger.d('Extracted user data with ${userData.length} fields');

          return success(userData);
        } else {
          _logger.d('Failed to fetch from /whoami endpoint: ${response.statusCode}');
        }
      } on Exception catch (e) {
        _logger.d('Failed to fetch from /whoami endpoint, trying JWT decoding', error: e);
        return failure(UnknownFailure(details: 'Failed to fetch user info: $e'));
      }

      // Fallback: Decode JWT token to get user info
      final accessToken = client.credentials.accessToken;
      final payload = _decodeJwtPayload(accessToken);

      if (payload != null) {
        _logger.d('User info extracted from JWT token');
        _logger.d('JWT payload: $payload'); // Debug logging
        return success(payload);
      } else {
        return failure(const UnknownFailure(details: 'Failed to decode JWT token'));
      }
    } on Exception catch (e) {
      _logger.e('Error fetching user info', error: e);
      return failure(UnknownFailure(details: 'Failed to fetch user info: $e'));
    }
  }
}
