import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Repository interface for workspace operations
abstract class WorkspaceRepository {
  /// Fetches all workspaces for the current authenticated user
  Future<Result<List<Workspace>>> getWorkspaces();

  /// Fetches a single workspace by ID
  Future<Result<Workspace>> getWorkspace(String workspaceId);
}


