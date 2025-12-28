import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@module
abstract class RegisterModule {
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
    ),);

    return dio;
  }

  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          dateTimeFormat:
              DateTimeFormat.onlyTimeAndSinceStart, // Should each log print contain a timestamp
        ),
      );

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
        mOptions: MacOsOptions(
          // Use user's keychain instead of app-specific keychain group
          // This allows the app to work when ad-hoc signed
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

  @lazySingleton
  http.Client get httpClient => http.Client();
}
