import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
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

      final userModel = await _remoteDataSource.getUser(userId);
      final user = userModel.toEntity();

      // Cache the result
      _cachedUsers[userId] = user;

      return success(user);
    } on ServerException catch (e) {
      _logger.e('Server error fetching user', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching user', error: e);
      return failure(NetworkFailure(details: e.message));
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
        _logger.d('Fetching ${uncachedIds.length} uncached users');
        final userModels = await _remoteDataSource.getUsers(uncachedIds);
        final users = userModels.map((model) => model.toEntity()).toList();

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
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching users', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getWorkspaceUsers(String workspaceId) async {
    try {
      final userModels = await _remoteDataSource.getWorkspaceUsers(workspaceId);
      final users = userModels.map((model) => model.toEntity()).toList();

      // Cache all workspace users
      for (final user in users) {
        _cachedUsers[user.id] = user;
      }

      return success(users);
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspace users', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspace users', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspace users', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the user cache
  void clearCache() {
    _cachedUsers.clear();
  }
}


