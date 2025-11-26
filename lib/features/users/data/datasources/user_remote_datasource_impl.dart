import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
import 'package:carbon_voice_console/features/users/data/datasources/user_remote_datasource.dart';
import 'package:carbon_voice_console/features/users/data/models/user_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<UserModel> getUser(String userId) async {
    try {
      _logger.d('Fetching user: $userId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/users/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final normalized = JsonNormalizer.normalizeUser(data);
        final user = UserModel.fromJson(normalized);
        _logger.i('Fetched user: ${user.name}');
        return user;
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
  Future<List<UserModel>> getUsers(List<String> userIds) async {
    try {
      _logger.d('Fetching ${userIds.length} users');

      // If API supports batch fetching, use it
      // For now, fetch individually (can be optimized later)
      final users = <UserModel>[];
      for (final userId in userIds) {
        try {
          final user = await getUser(userId);
          users.add(user);
        } on Exception catch (e) {
          _logger.w('Failed to fetch user $userId: $e');
          // Continue with other users
        }
      }

      _logger.i('Fetched ${users.length}/${userIds.length} users');
      return users;
    } on Exception catch (e, stack) {
      _logger.e('Error fetching users', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch users: $e');
    }
  }

  @override
  Future<List<UserModel>> getWorkspaceUsers(String workspaceId) async {
    try {
      _logger.d('Fetching users for workspace: $workspaceId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces/$workspaceId/users',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {users: [...]} or just [...]
        final List<dynamic> usersJson;
        if (data is List) {
          usersJson = data;
        } else if (data is Map<String, dynamic>) {
          usersJson = data['users'] as List<dynamic>? ?? data['data'] as List<dynamic>;
        } else {
          throw const FormatException('Unexpected response format');
        }

        final users = usersJson
            .map((json) {
              final normalized = JsonNormalizer.normalizeUser(json as Map<String, dynamic>);
              return UserModel.fromJson(normalized);
            })
            .toList();

        _logger.i('Fetched ${users.length} workspace users');
        return users;
      } else {
        _logger.e('Failed to fetch workspace users: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspace users',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspace users', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspace users: $e');
    }
  }
}
