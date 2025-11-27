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
        _logger.d('Messages API raw response: ${response.body}');
        final data = jsonDecode(response.body);
        _logger.d('Parsed messages data type: ${data.runtimeType}');

        // API returns: [{message}, {message}, ...]
        if (data is! List) {
          throw FormatException(
            'Expected List but got ${data.runtimeType} for messages endpoint',
          );
        }

        final messagesJson = data;
        _logger.d('Received ${messagesJson.length} messages from API');

        // Convert each message JSON to DTO
        final messages = <MessageDto>[];
        for (final json in messagesJson) {
          try {
            if (json is! Map<String, dynamic>) {
              throw FormatException('Message item is not a Map: ${json.runtimeType}');
            }
            final messageDto = MessageDto.fromJson(json);
            messages.add(messageDto);
          } catch (e, stack) {
            _logger.e('Failed to parse message in list: $e', error: e, stackTrace: stack);
            _logger.d('Failed message JSON: $json');
            // Continue with other messages instead of failing completely
          }
        }

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
        _logger.d('API Response keys: ${data.keys.toList()}');

        // Check if response has a 'message' key with the actual message data
        if (data.containsKey('message') && data['message'] != null && data['message'] is Map<String, dynamic>) {
          // Wrapped format: {"message": {...}, ...}
          _logger.d('Using wrapped message format');
          final messageData = data['message'] as Map<String, dynamic>;
          _logger.d('messageData type: ${messageData.runtimeType}');
          _logger.d('messageData keys: ${messageData.keys.toList()}');
          _logger.d('messageData isEmpty: ${messageData.isEmpty}');

          // Check if message data is not empty
          if (messageData.isNotEmpty) {
            try {
              // Handle field name differences between APIs
              // Single message API uses 'id', list API uses 'message_id'
              final normalizedData = Map<String, dynamic>.from(messageData);
              if (normalizedData.containsKey('id') && !normalizedData.containsKey('message_id')) {
                normalizedData['message_id'] = normalizedData['id'];
                normalizedData.remove('id');
              }

              final messageDto = MessageDto.fromJson(normalizedData);

              // Log channel info if available
              final channelId = data['channel_id'] as String?;
              _logger.i('Fetched message: ${messageDto.messageId ?? "null"}${channelId != null ? ' from channel: $channelId' : ''}');
              return messageDto;
            } catch (e, stack) {
              _logger.e('Failed to parse message JSON: $e', error: e, stackTrace: stack);
              _logger.d('Message data that failed parsing: $messageData');
              throw ServerException(statusCode: 422, message: 'Invalid message JSON structure: $e');
            }
          } else {
            _logger.w('Message data is empty');
            throw ServerException(statusCode: 422, message: 'Message data is empty');
          }
        } else {
          // Direct format: {message object with all fields}
          _logger.d('Using direct message format');

          // Check if data contains message fields (not just wrapper fields)
          final messageKeys = ['message_id', 'creator_id', 'created_at'];
          final hasMessageFields = messageKeys.any((key) => data.containsKey(key));

          if (hasMessageFields) {
            try {
              // Handle field name differences between APIs
              // Single message API uses 'id', list API uses 'message_id'
              final normalizedData = Map<String, dynamic>.from(data);
              if (normalizedData.containsKey('id') && !normalizedData.containsKey('message_id')) {
                normalizedData['message_id'] = normalizedData['id'];
                normalizedData.remove('id');
              }

              final messageDto = MessageDto.fromJson(normalizedData);
              _logger.i('Fetched message: ${messageDto.messageId ?? "null"}');
              return messageDto;
            } catch (e, stack) {
              _logger.e('Failed to parse direct message JSON: $e', error: e, stackTrace: stack);
              _logger.d('Direct message data that failed parsing: $data');
              throw ServerException(statusCode: 422, message: 'Invalid direct message JSON structure: $e');
            }
          } else {
            _logger.w('Response does not contain message data');
            throw ServerException(statusCode: 422, message: 'Response does not contain valid message data');
          }
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
