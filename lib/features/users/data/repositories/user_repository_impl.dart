import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/dtos/user_profile_mapper.dart';
import 'package:carbon_voice_console/features/users/data/datasources/user_remote_datasource.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource, this._logger);

  final UserRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: userId -> user
  final Map<String, User> _cachedUsers = {};

  @override
  Future<Result<User>> getUser(String userId) async {
    try {
      // Return cached user if available
      if (_cachedUsers.containsKey(userId)) {
        _logger.d('Returning cached user: $userId');
        return success(_cachedUsers[userId]!);
      }

      final userProfileDto = await _remoteDataSource.getUser(userId);
      final userProfile = userProfileDto.toDomain(userId);
      final user = User(
        id: userProfile.id,
        name: userProfile.fullName,
        email: userProfile.email,
        // avatarUrl and workspaceId can be added later if available in API
      );

      // Cache the result
      _cachedUsers[userId] = user;

      return success(user);
    } on ServerException catch (e) {
      _logger.e('Server error fetching user', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching user', error: e);
      return failure(NetworkFailure(details: e.message));
    } on FormatException catch (e) {
      _logger.e('Invalid user data format', error: e);
      return failure(UnknownFailure(details: 'Invalid user data format: ${e.message}'));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching user', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getUsers(List<String> userIds) async {
    try {
      // Separate cached and uncached user IDs
      final cachedUsers = <User>[];
      final uncachedIds = <String>[];

      for (final userId in userIds) {
        if (_cachedUsers.containsKey(userId)) {
          cachedUsers.add(_cachedUsers[userId]!);
        } else {
          uncachedIds.add(userId);
        }
      }

      // Fetch uncached users
      if (uncachedIds.isNotEmpty) {
        final userProfileDtos = await _remoteDataSource.getUsers(uncachedIds);
        final users = <User>[];
        for (var i = 0; i < userProfileDtos.length; i++) {
          final dto = userProfileDtos[i];
          final userId = uncachedIds[i];
          final userProfile = dto.toDomain(userId);
          users.add(User(
            id: userProfile.id,
            name: userProfile.fullName,
            email: userProfile.email,
            // avatarUrl and workspaceId can be added later if available in API
          ),);
        }

        // Cache the results
        for (final user in users) {
          _cachedUsers[user.id] = user;
        }

        cachedUsers.addAll(users);
      }

      return success(cachedUsers);
    } on ServerException catch (e) {
      _logger.e('Server error fetching users', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching users', error: e);
      return failure(NetworkFailure(details: e.message));
    } on FormatException catch (e) {
      _logger.e('Invalid user data format', error: e);
      return failure(UnknownFailure(details: 'Invalid user data format: ${e.message}'));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching users', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }


  /// Clears the user cache
  void clearCache() {
    _cachedUsers.clear();
  }
}
