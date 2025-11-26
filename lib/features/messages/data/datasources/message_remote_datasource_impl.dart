import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/message_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  }) async {
    try {
      final stop = start + count;
      _logger.d('Fetching messages [$start-$stop] for conversation: $conversationId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/messages/$conversationId/sequential/$start/$stop',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {messages: [...]} or just [...]
        final List<dynamic> messagesJson;
        if (data is List) {
          messagesJson = data;
        } else if (data is Map<String, dynamic>) {
          messagesJson = data['messages'] as List<dynamic>? ?? data['data'] as List<dynamic>;
        } else {
          throw const FormatException('Unexpected response format');
        }

        final messages = messagesJson
            .map((json) {
              final normalized = JsonNormalizer.normalizeMessage(json as Map<String, dynamic>);
              return MessageModel.fromJson(normalized);
            })
            .toList();

        _logger.i('Fetched ${messages.length} messages');
        return messages;
      } else {
        _logger.e('Failed to fetch messages: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch messages',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching messages', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch messages: $e');
    }
  }

  @override
  Future<MessageModel> getMessage(String messageId) async {
    try {
      _logger.d('Fetching message: $messageId');

      // Try v5 endpoint first, fallback to v4
      var response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v5/messages/$messageId',
      );

      if (response.statusCode == 404) {
        _logger.d('Message not found in v5, trying v4');
        response = await _httpService.get(
          '${OAuthConfig.apiBaseUrl}/v4/messages/$messageId',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final normalized = JsonNormalizer.normalizeMessage(data);
        final message = MessageModel.fromJson(normalized);
        _logger.i('Fetched message: ${message.id}');
        return message;
      } else {
        _logger.e('Failed to fetch message: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch message',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching message', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch message: $e');
    }
  }

  @override
  Future<List<MessageModel>> getRecentMessages({
    required String conversationId,
    int count = 50,
  }) async {
    try {
      _logger.d('Fetching $count recent messages for conversation: $conversationId');

      // API expects channel_guid (snake_case) and direction parameter
      // direction must be "older" or "newer" - using "newer" for recent messages
      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/recent',
        body: {
          'channel_guid': conversationId,
          'count': count,
          'direction': 'newer', // Required: "older" or "newer"
        },
      );

      // API returns 201 (Created) for successful POST requests
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // API might return {messages: [...]} or just [...]
        final List<dynamic> messagesJson;
        if (data is List) {
          messagesJson = data;
        } else if (data is Map<String, dynamic>) {
          messagesJson = data['messages'] as List<dynamic>? ?? data['data'] as List<dynamic>;
        } else {
          throw const FormatException('Unexpected response format');
        }

        final messages = messagesJson
            .map((json) {
              final normalized = JsonNormalizer.normalizeMessage(json as Map<String, dynamic>);
              return MessageModel.fromJson(normalized);
            })
            .toList();

        _logger.i('Fetched ${messages.length} recent messages');
        return messages;
      } else {
        _logger.e(
          'Failed to fetch recent messages: ${response.statusCode}',
          error: response.body,
        );
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch recent messages: ${response.body}',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching recent messages', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch recent messages: $e');
    }
  }
}
