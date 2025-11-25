import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import '../config/oauth_config.dart';

@module
abstract class RegisterModule {
  // Mantener Dio SOLO para llamadas públicas (no autenticadas)
  // Para llamadas autenticadas, usar AuthenticatedHttpService
  @LazySingleton()
  @Named('publicDio')
  Dio publicDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: OAuthConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        receiveTimeout: const Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }

  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 2, // Number of method calls to be displayed
          errorMethodCount: 8, // Number of method calls if stacktrace is provided
          lineLength: 120, // Width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          dateTimeFormat:
              DateTimeFormat.onlyTimeAndSinceStart, // Should each log print contain a timestamp
        ),
      );

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
}
