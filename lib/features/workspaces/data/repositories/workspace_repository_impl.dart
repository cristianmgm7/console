import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/mappers/workspace_dto_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRepository)
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._remoteDataSource, this._logger);

  final WorkspaceRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache for workspaces
  List<Workspace>? _cachedWorkspaces;

  @override
  Future<Result<List<Workspace>>> getWorkspaces() async {
    try {
      // Return cached workspaces if available
      if (_cachedWorkspaces != null) {
        _logger.d('Returning cached workspaces');
        return success(_cachedWorkspaces!);
      }

      final workspaceDtos = await _remoteDataSource.getWorkspaces();
      final workspaces = workspaceDtos.map((dto) => (dto as WorkspaceDto).toDomain()).toList() as List<Workspace>;

      // Cache the result
      _cachedWorkspaces = workspaces;

      return success(workspaces);
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspaces', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspaces', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspaces', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Workspace>> getWorkspace(String workspaceId) async {
    try {
      // Check cache first
      if (_cachedWorkspaces != null) {
        final cached = _cachedWorkspaces!.where((w) => w.id == workspaceId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached workspace: $workspaceId');
          return success(cached);
        }
      }

      final workspaceDto = await _remoteDataSource.getWorkspace(workspaceId);
      return success((workspaceDto as WorkspaceDto).toDomain());
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspace', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspace', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspace', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }


  /// Clears the workspace cache (useful for refresh)
  void clearCache() {
    _cachedWorkspaces = null;
  }
}
