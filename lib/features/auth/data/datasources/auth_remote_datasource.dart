import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
  });

  Future<TokenModel> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  });

  Future<TokenModel> refreshAccessToken(String refreshToken);

  Future<void> revokeToken(String accessToken);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<String> buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
  }) async {
    final uri = Uri.parse(OAuthConfig.authUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': OAuthConfig.clientId,
      'redirect_uri': OAuthConfig.redirectUrl,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'scope': OAuthConfig.scopes.join(' '),
    });

    return uri.toString();
  }

  @override
  Future<TokenModel> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final response = await _dio.post(
        OAuthConfig.tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'client_id': OAuthConfig.clientId,
          'client_secret': OAuthConfig.clientSecret,
          'code': code,
          'redirect_uri': OAuthConfig.redirectUrl,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return TokenModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<TokenModel> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        OAuthConfig.tokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'client_id': OAuthConfig.clientId,
          'client_secret': OAuthConfig.clientSecret,
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return TokenModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<void> revokeToken(String accessToken) async {
    try {
      // Note: Not all providers support revocation
      // This is a generic implementation
      await _dio.post(
        '${OAuthConfig.apiBaseUrl}/oauth/revoke',
        data: {
          'token': accessToken,
          'client_id': OAuthConfig.clientId,
          'client_secret': OAuthConfig.clientSecret,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
    } catch (_) {
      // Ignore revocation errors
    }
  }
}
