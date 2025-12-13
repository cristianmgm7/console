import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRemoteDataSource)
class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  WorkspaceRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<WorkspaceDto>> getWorkspaces() async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/workspaces',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        List<dynamic> workspacesList;

        workspacesList = data as List<dynamic>;

        try {
          final workspaceDtos = workspacesList
              .map((json) => WorkspaceDto.fromJson(json as Map<String, dynamic>))
              .toList();
          return workspaceDtos;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse workspaces: $e', error: e, stackTrace: stack);
          throw ServerException(statusCode: 422, message: 'Failed to parse workspaces: $e');
        }
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
  Future<WorkspaceDto> getWorkspace(String workspaceId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          final workspaceDto = WorkspaceDto.fromJson(data);
          return workspaceDto;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse workspace JSON: $e', error: e, stackTrace: stack);
          throw ServerException(statusCode: 422, message: 'Invalid workspace JSON structure: $e');
        }
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
