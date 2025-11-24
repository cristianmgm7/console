import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/token.dart';
import '../../domain/entities/oauth_flow_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/services/pkce_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/token_model.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final PKCEService _pkceService;
  final Logger _logger;

  OAuthFlowState? _currentFlowState;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._pkceService,
    this._logger,
  );

  @override
  Future<Result<String>> generateAuthorizationUrl() async {
    _logger.d('Generating authorization URL');
    try {
      final codeVerifier = _pkceService.generateCodeVerifier();
      final codeChallenge = _pkceService.generateCodeChallenge(codeVerifier);
      final state = _pkceService.generateState();

      _currentFlowState = OAuthFlowState(
        codeVerifier: codeVerifier,
        state: state,
      );

      final url = await _remoteDataSource.buildAuthorizationUrl(
        codeChallenge: codeChallenge,
        state: state,
      );

      _logger.i('Authorization URL generated successfully');
      return success(url);
    } on OAuthException catch (e) {
      _logger.e('OAuth error generating URL', error: e);
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
      _logger.e('Unknown error generating URL', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<OAuthFlowState?>> getCurrentFlowState() async {
    // FIXED: Now async for consistency
    try {
      return success(_currentFlowState);
    } catch (e) {
      _logger.e('Error getting current flow state', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Token>> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    _logger.d('Exchanging code for token');
    try {
      final tokenModel = await _remoteDataSource.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
      );

      _currentFlowState = null; // Clear flow state

      _logger.i('Token exchange successful');
      return success(tokenModel.toDomain());
    } on NetworkException catch (e) {
      _logger.w('Network error exchanging token', error: e);
      return failure(NetworkFailure(details: e.message));
    } on ServerException catch (e) {
      _logger.e('Server error exchanging token: ${e.statusCode}', error: e);
      if (e.statusCode == 401) {
        return failure(const InvalidCredentialsFailure());
      }
      return failure(ServerFailure(
        statusCode: e.statusCode,
        details: e.message,
      ));
    } on OAuthException catch (e) {
      _logger.e('OAuth error exchanging token', error: e);
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
      _logger.e('Unknown error exchanging token', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Token>> refreshToken(String refreshToken) async {
    _logger.d('Refreshing token');
    try {
      final tokenModel = await _remoteDataSource.refreshAccessToken(
        refreshToken,
      );

      _logger.i('Token refresh successful');
      return success(tokenModel.toDomain());
    } on NetworkException catch (e) {
      _logger.w('Network error refreshing token', error: e);
      return failure(NetworkFailure(details: e.message));
    } on ServerException catch (e) {
      _logger.e('Server error refreshing token: ${e.statusCode}', error: e);
      if (e.statusCode == 401 || e.code == 'invalid_grant') {
        return failure(const TokenExpiredFailure());
      }
      return failure(ServerFailure(
        statusCode: e.statusCode,
        details: e.message,
      ));
    } on OAuthException catch (e) {
      _logger.e('OAuth error refreshing token', error: e);
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
      _logger.e('Unknown error refreshing token', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveToken(Token token) async {
    try {
      final tokenModel = TokenModel.fromDomain(token);
      await _localDataSource.saveToken(tokenModel);
      return success(null);
    } on StorageException catch (e) {
      _logger.e('Storage error saving token', error: e);
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      _logger.e('Unknown error saving token', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Token?>> loadSavedToken() async {
    try {
      final tokenModel = await _localDataSource.loadToken();

      if (tokenModel == null) {
        return success(null);
      }

      return success(tokenModel.toDomain());
    } on StorageException catch (e) {
      _logger.e('Storage error loading token', error: e);
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      _logger.e('Unknown error loading token', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    _logger.d('Logging out');
    try {
      final tokenModel = await _localDataSource.loadToken();

      if (tokenModel != null) {
        await _remoteDataSource.revokeToken(tokenModel.accessToken);
      }

      await _localDataSource.deleteToken();
      _currentFlowState = null;

      _logger.i('Logout successful');
      return success(null);
    } on StorageException catch (e) {
      _logger.e('Storage error during logout', error: e);
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      _logger.e('Error during logout', error: e);
      // Even on error, try to clear local data
      try {
        await _localDataSource.deleteToken();
        _currentFlowState = null;
        return success(null);
      } catch (_) {
        return failure(UnknownFailure(details: e.toString()));
      }
    }
  }

  @override
  Future<Result<void>> clearAuthData() async {
    try {
      await _localDataSource.clearAllData();
      _currentFlowState = null;
      return success(null);
    } on StorageException catch (e) {
      _logger.e('Storage error clearing auth data', error: e);
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      _logger.e('Unknown error clearing auth data', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
