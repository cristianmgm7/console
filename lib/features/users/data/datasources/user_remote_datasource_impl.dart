import 'dart:convert';

import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/dtos/user_profile_dto.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/users/data/datasources/user_remote_datasource.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<UserProfileDto> getUser(String userId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/user/profile/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Parse using DTO
        final userProfileDto = UserProfileDto.fromJson(data);
        return userProfileDto;
      } else {
        _logger.e('Failed to fetch user: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch user',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching user', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch user: $e');
    }
  }

  @override
  Future<List<UserProfileDto>> getUsers(List<String> userIds) async {
    try {
      final users = <UserProfileDto>[];
      for (final userId in userIds) {
        try {
          final user = await getUser(userId);
          users.add(user);
        } on Exception catch (e) {
          _logger.w('Failed to fetch user $userId: $e');
          // Continue with other users
        }
      }

      return users;
    } on Exception catch (e, stack) {
      _logger.e('Error fetching users', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch users: $e');
    }
  }

}
