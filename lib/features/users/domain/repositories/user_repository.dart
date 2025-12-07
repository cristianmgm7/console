import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Fetches a single user by ID
  Future<Result<User>> getUser(String userId);

  /// Fetches multiple users by their IDs (batch operation)
  Future<Result<List<User>>> getUsers(List<String> userIds);

  /// Fetches current user information from /whoami endpoint
  Future<Result<User>> getCurrentUserInfo();

}
