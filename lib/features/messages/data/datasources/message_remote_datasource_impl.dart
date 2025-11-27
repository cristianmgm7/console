import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<MessageDto>> getMessages({
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

        // API returns: [{message}, {message}, ...]
        if (data is! List) {
          throw FormatException(
            'Expected List but got ${data.runtimeType} for messages endpoint',
          );
        }

        final messagesJson = data;
        _logger.d('Received ${messagesJson.length} messages');

        // Convert each message JSON to DTO
        final messages = messagesJson
            .map((json) {
              if (json is! Map<String, dynamic>) {
                throw FormatException('Message item is not a Map: ${json.runtimeType}');
              }
              return MessageDto.fromJson(json);
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
  Future<MessageDto> getMessage(String messageId) async {
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
        // 1. Channel format: {"channel_id": "...", "messages": [{message1}, {message2}, ...]}
        // 2. Direct format: {message object with all fields}
        final messagesArray = data['messages'] as List<dynamic>?;

        if (messagesArray != null && messagesArray.isNotEmpty) {
          // Wrapped format - extract first message from messages array
          final firstMessageJson = messagesArray.first as Map<String, dynamic>;
          final messageDto = MessageDto.fromJson(firstMessageJson);

          // Log channel info if available
          final channelId = data['channel_id'] as String?;
          _logger.i('Fetched message: ${messageDto.messageId}${channelId != null ? ' from channel: $channelId' : ''}');
          return messageDto;
        } else {
          // Direct format - parse the entire response as a message
          final messageDto = MessageDto.fromJson(data);
          _logger.i('Fetched message: ${messageDto.messageId}');
          return messageDto;
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
