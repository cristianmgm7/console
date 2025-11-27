import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/json_normalizer.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/message_detail_response_dto.dart';
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
        print (data[0]);

        // List endpoint returns: [{message}, {message}, ...]
        // Detail endpoint returns: {"channel_id": "...", "messages": [{message}]}
        final List<dynamic> messagesJson;

        if (data is List) {
          // Direct array format (list endpoint)
          messagesJson = data;
          _logger.d('Received direct array with ${data.length} messages');
        } else if (data is Map<String, dynamic>) {
          // Wrapped format - try 'messages' field first, fallback to 'data'
          final messages = data['messages'] as List<dynamic>?;
          final dataField = data['data'] as List<dynamic>?;

          if (messages != null) {
            messagesJson = messages;
            _logger.d('Received wrapped response with ${messages.length} messages');
          } else if (dataField != null) {
            messagesJson = dataField;
            _logger.d('Received wrapped response (data field) with ${dataField.length} messages');
          } else {
            throw FormatException(
              'Wrapped response missing messages/data array. Keys: ${data.keys.join(", ")}',
            );
          }
        } else {
          throw FormatException(
            'Unexpected response type: ${data.runtimeType}. Expected List or Map.',
          );
        }

        // Normalize and convert each message
        final messages = messagesJson
            .map((json) {
              if (json is! Map<String, dynamic>) {
                throw FormatException('Message item is not a Map: ${json.runtimeType}');
              }
              final normalized = JsonNormalizer.normalizeMessage(json);
              return MessageModel.fromJson(normalized);
            })
            .toList();

        _logger.i('Successfully fetched and normalized ${messages.length} messages');
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

        // Detail endpoint can return two formats:
        // 1. Wrapped: {"channel_id": "...", "messages": [{...}]}
        // 2. Direct: {message object with all fields}
        final messagesJson = data['messages'] as List<dynamic>?;
        print (jsonEncode(data));

        if (messagesJson != null && messagesJson.isNotEmpty) {
          // Wrapped format - extract first message
          final firstMessageJson = messagesJson.first as Map<String, dynamic>;
          final normalized = JsonNormalizer.normalizeMessage(firstMessageJson);
          final messageModel = MessageModel.fromJson(normalized);

          // Create typed DTO (for validation) then extract the message
          final detailResponse = MessageDetailResponseDto.fromJson(
            data,
            [messageModel],
          );

          _logger.i('Fetched message: ${detailResponse.firstMessage.id} from channel: ${detailResponse.channelId}');
          return detailResponse.firstMessage;
        } else {
          // Direct format - normalize the entire response as a message
          final normalized = JsonNormalizer.normalizeMessage(data);
          final message = MessageModel.fromJson(normalized);
          _logger.i('Fetched message: ${message.id}');
          return message;
        }
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

}
