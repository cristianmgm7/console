import 'package:injectable/injectable.dart';
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

  OAuthFlowState? _currentFlowState;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._pkceService,
  );

  @override
  Future<Result<String>> generateAuthorizationUrl() async {
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

      return success(url);
    } on OAuthException catch (e) {
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<OAuthFlowState?>> getCurrentFlowState() async {
    // FIXED: Now async for consistency
    try {
      return success(_currentFlowState);
    } catch (e) {
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Token>> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
      );

      _currentFlowState = null; // Clear flow state

      return success(tokenModel.toDomain());
    } on NetworkException catch (e) {
      return failure(NetworkFailure(details: e.message));
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return failure(const InvalidCredentialsFailure());
      }
      return failure(ServerFailure(
        statusCode: e.statusCode,
        details: e.message,
      ));
    } on OAuthException catch (e) {
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Token>> refreshToken(String refreshToken) async {
    try {
      final tokenModel = await _remoteDataSource.refreshAccessToken(
        refreshToken,
      );

      return success(tokenModel.toDomain());
    } on NetworkException catch (e) {
      return failure(NetworkFailure(details: e.message));
    } on ServerException catch (e) {
      if (e.statusCode == 401 || e.code == 'invalid_grant') {
        return failure(const TokenExpiredFailure());
      }
      return failure(ServerFailure(
        statusCode: e.statusCode,
        details: e.message,
      ));
    } on OAuthException catch (e) {
      return failure(AuthFailure(code: e.code ?? 'OAUTH_ERROR', details: e.message));
    } catch (e) {
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
      return failure(StorageFailure(details: e.message));
    } catch (e) {
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
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final tokenModel = await _localDataSource.loadToken();

      if (tokenModel != null) {
        await _remoteDataSource.revokeToken(tokenModel.accessToken);
      }

      await _localDataSource.deleteToken();
      _currentFlowState = null;

      return success(null);
    } on StorageException catch (e) {
      return failure(StorageFailure(details: e.message));
    } catch (e) {
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
      return failure(StorageFailure(details: e.message));
    } catch (e) {
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
