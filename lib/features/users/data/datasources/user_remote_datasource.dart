import 'package:carbon_voice_console/features/users/data/models/user_model.dart';

/// Abstract interface for user remote data operations
abstract class UserRemoteDataSource {
  /// Fetches a single user by ID from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<UserModel> getUser(String userId);

  /// Fetches multiple users by their IDs (batch operation)
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<UserModel>> getUsers(List<String> userIds);

  /// Fetches all users in a workspace
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<UserModel>> getWorkspaceUsers(String workspaceId);
}
