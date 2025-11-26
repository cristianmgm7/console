import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/workspace_model.dart';

/// Abstract interface for workspace remote data operations
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<WorkspaceModel>> getWorkspaces();

  /// Fetches a single workspace by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<WorkspaceModel> getWorkspace(String workspaceId);
}
