import 'package:carbon_voice_console/core/dtos/user_profile_dto.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart' show NetworkException, ServerException;

/// Abstract interface for user remote data operations
abstract class UserRemoteDataSource {
  /// Fetches a single user by ID from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<UserProfileDto> getUser(String userId);

  /// Fetches multiple users by their IDs (batch operation)
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<UserProfileDto>> getUsers(List<String> userIds);

}
