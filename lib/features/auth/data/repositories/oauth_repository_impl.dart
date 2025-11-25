import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import '../../../../core/config/oauth_config.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/oauth_repository.dart';
import '../datasources/oauth_local_datasource.dart';

@LazySingleton(as: OAuthRepository)
class OAuthRepositoryImpl implements OAuthRepository {
  final OAuthLocalDataSource _localDataSource;
  final Logger _logger;

  oauth2.AuthorizationCodeGrant? _grant;
  oauth2.Client? _client;

  OAuthRepositoryImpl(
    this._localDataSource,
    this._logger,
  );

  @override
  Future<Result<String>> getAuthorizationUrl() async {
    try {
      _logger.d('Creating authorization URL');

      // Crear nuevo grant con PKCE automático
      _grant = oauth2.AuthorizationCodeGrant(
        OAuthConfig.clientId,
        OAuthConfig.authorizationEndpointUri,
        OAuthConfig.tokenEndpointUri,
        secret: OAuthConfig.clientSecret,
        // PKCE se habilita automáticamente
      );

      // Generar URL de autorización
      final authUrl = _grant!.getAuthorizationUrl(
        OAuthConfig.redirectUri,
        scopes: OAuthConfig.scopes,
      );

      _logger.i('Authorization URL created: $authUrl');
      return success(authUrl.toString());
    } catch (e, stack) {
      _logger.e('Error creating authorization URL', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl) async {
    try {
      _logger.d('Handling authorization response');

      if (_grant == null) {
        return failure(const AuthFailure(
          code: 'NO_GRANT',
          details: 'No authorization grant found. Start login flow first.',
        ));
      }

      // Parsear la URL de respuesta
      final responseUri = Uri.parse(responseUrl);

      // Intercambiar código por token (con PKCE automático)
      _client = await _grant!.handleAuthorizationResponse(
        responseUri.queryParameters,
      );

      // Guardar credentials
      await _localDataSource.saveCredentials(_client!.credentials);

      // Limpiar grant
      _grant = null;

      _logger.i('Authorization successful, client created');
      return success(_client!);
    } on oauth2.AuthorizationException catch (e) {
      _logger.e('OAuth authorization error', error: e);
      return failure(AuthFailure(
        code: e.error,
        details: e.description ?? 'Authorization failed',
      ));
    } catch (e, stack) {
      _logger.e('Error handling authorization response', error: e, stackTrace: stack);
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
    } catch (e, stack) {
      _logger.e('Error loading saved client', error: e, stackTrace: stack);
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
    } catch (e) {
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
      _grant = null;

      // Eliminar credentials guardadas
      await _localDataSource.deleteCredentials();

      _logger.i('Logout successful');
      return success(null);
    } catch (e, stack) {
      _logger.e('Error during logout', error: e, stackTrace: stack);
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
    } catch (e) {
      _logger.e('Error getting client', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
