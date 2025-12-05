import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';

/// Abstract interface for workspace remote data operations
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<WorkspaceDto>> getWorkspaces();

  /// Fetches a single workspace by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<WorkspaceDto> getWorkspace(String workspaceId);
}
