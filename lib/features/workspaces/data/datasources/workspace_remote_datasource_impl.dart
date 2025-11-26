import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/workspace_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRemoteDataSource)
class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  WorkspaceRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<WorkspaceModel>> getWorkspaces() async {
    try {
      _logger.d('Fetching workspaces from API');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {workspaces: [...]} or just [...]
        final List<dynamic> workspacesJson;
        if (data is List) {
          workspacesJson = data;
        } else if (data is Map<String, dynamic>) {
          workspacesJson = data['workspaces'] as List<dynamic>? ?? data['data'] as List<dynamic>;
        } else {
          throw const FormatException('Unexpected response format');
        }

        final workspaces = workspacesJson
            .map((json) {
              final normalized = JsonNormalizer.normalizeWorkspace(json as Map<String, dynamic>);
              return WorkspaceModel.fromJson(normalized);
            })
            .toList();

        _logger.i('Fetched ${workspaces.length} workspaces');
        return workspaces;
      } else {
        _logger.e('Failed to fetch workspaces: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspaces',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspaces', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspaces: $e');
    }
  }

  @override
  Future<WorkspaceModel> getWorkspace(String workspaceId) async {
    try {
      _logger.d('Fetching workspace: $workspaceId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final normalized = JsonNormalizer.normalizeWorkspace(data);
        final workspace = WorkspaceModel.fromJson(normalized);
        _logger.i('Fetched workspace: ${workspace.name}');
        return workspace;
      } else {
        _logger.e('Failed to fetch workspace: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspace',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspace', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspace: $e');
    }
  }
}
