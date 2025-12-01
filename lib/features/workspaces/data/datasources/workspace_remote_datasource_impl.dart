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
      _logger.d('Fetching workspaces from: ${OAuthConfig.apiBaseUrl}/workspaces');
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces',
      );
      _logger.d('Workspaces response status: ${response.statusCode}');

      // Parse response body to check for error details
      Map<String, dynamic>? errorData;
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          errorData = parsed;
        }
      } on Exception catch (e) {
        _logger.e('Failed to parse response body', error: e.toString());
        // If parsing fails, we'll use the raw body
      }

      if (response.statusCode != 200) {
        // Extract error message from JSON if available
        var errorMessage = 'Failed to fetch workspaces';
        if (errorData != null) {
          final errmsg = errorData['errmsg'] as String?;
          if (errmsg != null) {
            errorMessage = errmsg;
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } else {
          errorMessage = response.body;
        }

        _logger.e(
          'Failed to fetch workspaces: ${response.statusCode}',
          error: errorMessage,
        );
        throw ServerException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }

      final data = jsonDecode(response.body);

      // API might return {workspaces: [...]}, {data: [...]}, or just [...]
      final List<dynamic> workspacesJson;
      if (data is List) {
        workspacesJson = data;
      } else if (data is Map<String, dynamic>) {
        // Check success field if present
        if (data.containsKey('success') && data['success'] != true) {
          // Extract error message if available
          final errmsg = data['errmsg'] as String?;
          final errorMsg = errmsg ?? 'API returned success=false';
          _logger.e('API returned success=false: $errorMsg');
          throw ServerException(
            statusCode: response.statusCode,
            message: errorMsg,
          );
        }
        
        workspacesJson = (data['workspaces'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            [];
      } else {
        throw const FormatException('Unexpected response format');
      }

      if (workspacesJson.isEmpty) {
        return [];
      }

      final workspaces = workspacesJson
          .map((json) {
            final normalized = JsonNormalizer.normalizeWorkspace(json as Map<String, dynamic>);
            return WorkspaceModel.fromJson(normalized);
          })
          .toList();

      return workspaces;
    } on ServerException {
      rethrow;
    } on FormatException catch (e, stack) {
      _logger.e('Format error parsing workspaces response', error: e, stackTrace: stack);
      throw FormatException('Failed to parse workspaces response: $e');
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspaces', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspaces: $e');
    }
  }

  @override
  Future<WorkspaceModel> getWorkspace(String workspaceId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final normalized = JsonNormalizer.normalizeWorkspace(data);
        final workspace = WorkspaceModel.fromJson(normalized);
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
