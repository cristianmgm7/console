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
  final Logger _logger;
  final OAuthDesktopServer? _desktopServer;

  oauth2.Client? _client;
  
  // Store code verifiers for desktop OAuth (since we can't use sessionStorage)
  final Map<String, String> _desktopOAuthStates = {};

  @override
  Future<Result<String>> getAuthorizationUrl() async {
    try {
      _logger.d('Creating authorization URL');

      // Debug: Log client_id to verify it's set correctly
      _logger.w('OAuth Config - Client ID: ${OAuthConfig.clientId}');
      _logger.w('OAuth Config - Client ID length: ${OAuthConfig.clientId.length}');
      _logger.w('OAuth Config - Client ID is default: ${OAuthConfig.clientId == "YOUR_CLIENT_ID"}');
      _logger.w('OAuth Config - Authorization Endpoint: ${OAuthConfig.authorizationEndpoint}');
      _logger.w('OAuth Config - Redirect URI: ${OAuthConfig.redirectUrl}');

      // Validate client_id is not the default value
      if (OAuthConfig.clientId == 'YOUR_CLIENT_ID' || OAuthConfig.clientId.isEmpty) {
        _logger.e('Invalid client_id: ${OAuthConfig.clientId}');
        return failure(const ConfigurationFailure(
          details:
              'OAuth client_id is not configured. Please set OAUTH_CLIENT_ID environment variable.',
        ),);
      }

      // Generar PKCE codes manualmente para poder guardarlos
      final codeVerifier = PKCEGenerator.generateCodeVerifier();
      final codeChallenge = PKCEGenerator.generateCodeChallenge(codeVerifier);
      final state = PKCEGenerator.generateState();

      // Guardar el codeVerifier y state
      if (kIsWeb) {
        // En web, usar sessionStorage
        await _localDataSource.saveOAuthState(state, codeVerifier);
      } else {
        // En desktop, usar Map en memoria
        _desktopOAuthStates[state] = codeVerifier;
        _logger.d('Saved desktop OAuth state for: $state');
      }

      // Determinar redirect URI según plataforma
      const redirectUri = kIsWeb ? OAuthConfig.redirectUrl : 'http://localhost:3000/auth/callback';
      _logger.i('Using redirect URI: $redirectUri (kIsWeb: $kIsWeb)');

      // Construir la URL de autorización manualmente con PKCE
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

      _logger.i('Authorization URL created: $authUrl');
      _logger.w('Authorization URL query params: ${authUrl.queryParameters}');

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
      _logger.i('🖥️  Starting desktop OAuth flow...');

      // Get authorization URL (will use desktop redirect URI)
      final urlResult = await getAuthorizationUrl();
      
      return urlResult.fold(
        onSuccess: (authUrl) async {
          _logger.i('🌐 Opening browser with: $authUrl');

          // Use desktop server to handle the flow
          // This will: open browser, wait for callback, return callback URL
          final callbackUrl = await _desktopServer.authenticate(authUrl);
          _logger.i('✅ Received callback: $callbackUrl');

          // Now handle the authorization response
          return handleAuthorizationResponse(callbackUrl);
        },
        onFailure: (error) {
          return failure(error.failure);
        },
      );
    } on Exception catch (e, stack) {
      _logger.e('❌ Desktop OAuth failed', error: e, stackTrace: stack);
      _desktopServer.close(); // Cleanup
      return failure(AuthFailure(
        code: 'DESKTOP_OAUTH_FAILED',
        details: 'Desktop OAuth flow failed: $e',
      ),);
    }
  }

  @override
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl) async {
    try {
      // Log directo a consola del navegador

      _logger.d('Handling authorization response');
      _logger.w('Response URL: $responseUrl');

      // Parsear la URL de respuesta
      final responseUri = Uri.parse(responseUrl);
      final code = responseUri.queryParameters['code'];
      final state = responseUri.queryParameters['state'];
      final error = responseUri.queryParameters['error'];

      _logger.w('Parsed URI - Code: $code');
      _logger.w('Parsed URI - State: $state');
      _logger.w('Parsed URI - Error: $error');
      _logger.w('Token endpoint: ${OAuthConfig.tokenEndpoint}');
      _logger.w('Client ID: ${OAuthConfig.clientId}');
      _logger.w('Redirect URI: ${OAuthConfig.redirectUrl}');

      // Si hay error en la respuesta
      if (error != null) {
        return failure(AuthFailure(
          code: error,
          details: responseUri.queryParameters['error_description'] ?? 'Authorization failed',
        ),);
      }

      // Si no hay código de autorización
      if (code == null) {
        return failure(const AuthFailure(
          code: 'NO_CODE',
          details: 'No authorization code received',
        ),);
      }

      // Recuperar el codeVerifier usando el state
      if (state == null) {
        return failure(const AuthFailure(
          code: 'NO_STATE',
          details: 'No state parameter received',
        ),);
      }

      String? codeVerifier;
      
      if (kIsWeb) {
        // En web, cargar de sessionStorage
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
        // En desktop, cargar del Map en memoria
        codeVerifier = _desktopOAuthStates[state];
        if (codeVerifier == null || codeVerifier.isEmpty) {
          _logger.e('No codeVerifier found in memory for state: $state');
          _logger.w('Available states: ${_desktopOAuthStates.keys}');
          return failure(const AuthFailure(
            code: 'NO_CODE_VERIFIER',
            details: 'No authorization grant found. Please try logging in again.',
          ),);
        }
        _logger.d('Retrieved codeVerifier from memory for state: $state');
        // Limpiar el state usado
        _desktopOAuthStates.remove(state);
      }

      _logger.d('Code verifier found: ${codeVerifier!.substring(0, 10)}...');

      // Hacer token exchange manualmente con HTTP
      _logger.d('Attempting manual token exchange...');
      _logger.i('Token endpoint: ${OAuthConfig.tokenEndpointUri}');

      // Usar el redirect URI correcto según la plataforma
      const redirectUri = kIsWeb ? OAuthConfig.redirectUrl : 'http://localhost:3000/auth/callback';
      _logger.i('Using redirect URI for token exchange: $redirectUri');
      _logger.d('Code: $code (length: ${code.length})');
      _logger.d('State: $state');

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
              Duration(seconds: OAuthConfig.apiTimeoutSeconds),
              onTimeout: () {
                _logger.e('Token exchange timeout after ${OAuthConfig.apiTimeoutSeconds}s');
                throw TimeoutException(
                  'Token exchange timed out after ${OAuthConfig.apiTimeoutSeconds} seconds',
                  Duration(seconds: OAuthConfig.apiTimeoutSeconds),
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
        return failure(NetworkFailure(
          details: 'Request timed out. Please check your internet connection and try again.',
        ),);
      } on Exception catch (e) {
        _logger.e('Unexpected error during token exchange', error: e);
        return failure(NetworkFailure(
          details: 'An unexpected network error occurred: ${e.toString()}',
        ),);
      }

      _logger.w('Token response status: ${tokenResponse.statusCode}');

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

      // Parsear la respuesta del token
      final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;

      _logger.i('Token exchange successful!');

      // Transformar la respuesta del backend (snake_case) al formato esperado por oauth2 (camelCase)
      final expiresIn = tokenJson['expires_in'] as int? ?? 3600; // Default a 1 hora si no viene

      final credentialsJson = <String, dynamic>{
        'accessToken': tokenJson['access_token'] as String,
        'tokenType': tokenJson['token_type'] as String? ?? 'Bearer',
        'expiresIn': expiresIn, // Asegurar que no sea null
        // The oauth2 package expects 'scopes' as a List<String>, not 'scope'
        'scopes': tokenJson['scope'] is List
            ? (tokenJson['scope'] as List).map((e) => e.toString()).toList()
            : (tokenJson['scope'] as String?)?.split(' ') ?? [],
      };

      // Agregar refresh token si existe
      if (tokenJson.containsKey('refresh_token') && tokenJson['refresh_token'] != null) {
        credentialsJson['refreshToken'] = tokenJson['refresh_token'] as String;
      }

      // Calcular expiration - el paquete oauth2 espera expiration como timestamp Unix en milisegundos (int)
      final expirationDateTime = DateTime.now().add(Duration(seconds: expiresIn));
      credentialsJson['expiration'] =
          expirationDateTime.millisecondsSinceEpoch; // Timestamp en milisegundos

      _logger.w('Transformed credentials JSON keys: ${credentialsJson.keys}');

      // Crear credentials desde la respuesta transformada
      // Intentar parsear el JSON primero para verificar el formato
      final jsonString = jsonEncode(credentialsJson);

      oauth2.Credentials credentials;
      try {
        credentials = oauth2.Credentials.fromJson(jsonString);
      } on Exception catch (e) {
        _logger.e('Error creating credentials', error: e);
        // Intentar crear credentials directamente con el constructor
        // Nota: oauth2.Credentials no tiene constructor público, así que debemos usar fromJson
        // El problema podría ser el formato del JSON
        rethrow;
      }

      _logger.w('Access token received: ${credentials.accessToken.substring(0, 20)}...');
      _logger.w('Token expires: ${credentials.expiration}');

      // Crear cliente OAuth2
      _client = oauth2.Client(
        credentials,
        identifier: OAuthConfig.clientId,
        secret: OAuthConfig.clientSecret,
      );

      // Guardar credentials
      await _localDataSource.saveCredentials(credentials);

      // Limpiar el state del sessionStorage
      await _localDataSource.clearOAuthState(state);

      // Limpiar grant

      _logger.i('Authorization successful, client created');
      return success(_client!);
    } on oauth2.AuthorizationException catch (e) {
      _logger.e('OAuth authorization error', error: e);
      _logger.e('Error code: ${e.error}');
      _logger.e('Error description: ${e.description}');
      _logger.e('Error URI: ${e.uri}');
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
      _logger.d('Loading saved client');

      final credentials = await _localDataSource.loadCredentials();
      if (credentials == null) {
        _logger.d('No saved credentials found');
        return success(null);
      }

      // Crear cliente desde credentials guardadas
      _client = oauth2.Client(
        credentials,
        identifier: OAuthConfig.clientId,
        secret: OAuthConfig.clientSecret,
      );

      _logger.i('Client loaded from saved credentials');
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

      // Intentar cargar cliente guardado
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
      _logger.d('Logging out');

      // Cerrar cliente si existe
      _client?.close();
      _client = null;

      // Eliminar credentials guardadas
      await _localDataSource.deleteCredentials();

      _logger.i('Logout successful');
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

      // Intentar cargar cliente guardado
      return await loadSavedClient();
    } on Exception catch (e) {
      _logger.e('Error getting client', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
