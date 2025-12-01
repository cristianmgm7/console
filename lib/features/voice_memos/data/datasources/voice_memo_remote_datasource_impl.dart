import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/voice_memos/data/datasources/voice_memo_remote_datasource.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: VoiceMemoRemoteDataSource)
class VoiceMemoRemoteDataSourceImpl implements VoiceMemoRemoteDataSource {
  VoiceMemoRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<VoiceMemoDto>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'limit': limit,
        'direction': direction,
        'sort_direction': sortDirection,
        'include_deleted': includeDeleted,
      };

      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (folderId != null) queryParams['folder_id'] = folderId;
      if (date != null) queryParams['date'] = date.toIso8601String();

      // Build URL with query params
      final uri = Uri.parse(
        '${OAuthConfig.apiBaseUrl}/v4/messages/voicememo',
      ).replace(queryParameters: queryParams);

      _logger.d('Fetching voice memos from: $uri');

      final response = await _httpService.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API returns array of voice memos
        if (data is! List) {
          throw FormatException(
            'Expected List but got ${data.runtimeType} for voice memos endpoint',
          );
        }

        final voiceMemosJson = data;

        // Convert each voice memo JSON to DTO with error handling
        try {
          final voiceMemos = voiceMemosJson
              .map((json) => VoiceMemoDto.fromJson(json as Map<String, dynamic>))
              .toList();

          _logger.d('Fetched ${voiceMemos.length} voice memos');
          return voiceMemos;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse voice memos: $e', error: e, stackTrace: stack);
          throw ServerException(
            statusCode: 422,
            message: 'Failed to parse voice memos: $e',
          );
        }
      } else {
        _logger.e('Failed to fetch voice memos: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch voice memos',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching voice memos', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch voice memos: $e');
    }
  }
}
