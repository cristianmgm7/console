import 'dart:convert';

import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/data/dtos/conversation_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: ConversationRemoteDataSource)
class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  ConversationRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<ConversationDto>> getRecentChannelsBySource({
    required String sourceType,
    required String sourceValue,
    required int limit,
    String? date,
    String direction = 'older',
    bool includeDeleted = false,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'direction': direction,
        'includeDeleted': includeDeleted.toString(),
      };
      if (date != null && date.trim().isNotEmpty) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse(
        '${OAuthConfig.apiBaseUrl}/channels/recent/derived/$sourceType/$sourceValue',
      ).replace(queryParameters: queryParams);

      final response = await _httpService.get(uri.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // API might return {channels: [...]} or just [...]
        final List<dynamic> conversationsJson;
        if (data is List) {
          conversationsJson = data;
        } else if (data is Map<String, dynamic>) {
          conversationsJson =
              data['channels'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
        } else {
          throw const FormatException('Unexpected response format');
        }

        final conversations = conversationsJson
            .map((json) => ConversationDto.fromJson(json as Map<String, dynamic>))
            .toList();

        return conversations;
      } else {
        _logger.e('Failed to fetch recent channels by source: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch recent channels by source',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching recent channels by source', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch recent channels by source: $e');
    }
  }

  @override
  Future<ConversationDto> getConversation(String conversationId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/channel/$conversationId',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final conversation = ConversationDto.fromJson(data);
        return conversation;
      } else {
        // Log only errors or exceptions
        _logger.e('Failed to fetch conversation: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch conversation',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching conversation', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch conversation: $e');
    }
  }
}
