import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../features/auth/domain/usecases/load_saved_token_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';

/// Dio interceptor for automatic token management
/// - Adds Authorization header
/// - Refreshes token on 401
/// - Retries failed request once
@LazySingleton()
class AuthInterceptor extends Interceptor {
  // Get use cases lazily to break circular dependency
  // Dio → AuthInterceptor → UseCases → Repository → RemoteDataSource → Dio
  LoadSavedTokenUseCase get _loadToken => GetIt.instance<LoadSavedTokenUseCase>();
  RefreshTokenUseCase get _refreshToken => GetIt.instance<RefreshTokenUseCase>();

  // Prevent concurrent refresh
  bool _isRefreshing = false;
  final List<void Function()> _refreshQueue = [];

  AuthInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for OAuth token endpoint
    if (options.path.contains('/oauth/token')) {
      return handler.next(options);
    }

    // Load and attach token
    final tokenResult = await _loadToken();

    tokenResult.fold(
      onSuccess: (token) {
        if (token != null && token.isValid) {
          options.headers['Authorization'] = token.authorizationHeader;
        }
      },
      onFailure: (_) {
        // No token - continue without auth header
      },
    );

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized or invalid_grant
    if (err.response?.statusCode == 401 || _isInvalidGrantError(err)) {
      // Try refresh and retry
      final success = await _refreshTokenAndRetry(err, handler);
      if (success) {
        return; // Request retried successfully
      }
    }

    // Continue with error
    handler.next(err);
  }

  bool _isInvalidGrantError(DioException err) {
    if (err.response?.data is Map) {
      final error = err.response!.data['error'];
      return error == 'invalid_grant' || error == 'invalid_token';
    }
    return false;
  }

  Future<bool> _refreshTokenAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Wait if refresh already in progress
    if (_isRefreshing) {
      await _waitForRefresh();
    } else {
      // Perform refresh
      _isRefreshing = true;

      try {
        final refreshResult = await _refreshToken();

        final refreshed = refreshResult.fold(
          onSuccess: (_) => true,
          onFailure: (_) => false,
        );

        // Notify queued requests
        for (final callback in _refreshQueue) {
          callback();
        }
        _refreshQueue.clear();

        if (!refreshed) {
          _isRefreshing = false;
          return false;
        }
      } catch (e) {
        _isRefreshing = false;
        return false;
      } finally {
        _isRefreshing = false;
      }
    }

    // Retry original request with new token
    try {
      final tokenResult = await _loadToken();

      return tokenResult.fold(
        onSuccess: (token) async {
          if (token == null) return false;

          final options = err.requestOptions;
          options.headers['Authorization'] = token.authorizationHeader;

          final dio = Dio();
          final response = await dio.fetch(options);
          handler.resolve(response);
          return true;
        },
        onFailure: (_) => false,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> _waitForRefresh() async {
    final completer = Completer<void>();
    _refreshQueue.add(completer.complete);
    await completer.future;
  }
}
