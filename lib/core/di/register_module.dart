import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/oauth_config.dart';
import '../network/auth_interceptor.dart';

@module
abstract class RegisterModule {
  @LazySingleton()
  Dio dio(AuthInterceptor authInterceptor) {
    final dio = Dio(
      BaseOptions(
        baseUrl: OAuthConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor (gets use cases lazily to avoid circular dependency)
    dio.interceptors.add(authInterceptor);

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }
}
