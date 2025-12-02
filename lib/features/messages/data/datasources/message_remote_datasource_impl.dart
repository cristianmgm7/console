import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_detail_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<MessageDto>> getRecentMessages({
    required String conversationId,
    int count = 50,
    String direction = 'older',  // Use 'older' to get most recent messages (newest → oldest)
    String? beforeTimestamp,
  }) async {
    try {
      // Build request body according to actual API specification
      final requestBody = {
        'date': beforeTimestamp,
        'channel_id': conversationId,
        'limit': count,
        'direction': direction,
        'use_last_updated': true,
      };
      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/recent',
        body: requestBody, // AuthenticatedHttpService handles JSON encoding
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // API returns: [{message}, {message}, ...]
        // But might be wrapped in an object like {messages: [...]} or {items: [...]}
        List<dynamic> messagesList;

        if (data is List) {
          messagesList = data;
        } else if (data is Map<String, dynamic>) {
          // Check for common wrapper keys
          if (data.containsKey('messages')) {
            messagesList = data['messages'] as List<dynamic>;
            _logger.d('🔵 Found messages array with ${messagesList.length} items');
          } else if (data.containsKey('items')) {
            messagesList = data['items'] as List<dynamic>;
            _logger.d('🔵 Found items array with ${messagesList.length} items');
          } else if (data.containsKey('data')) {
            messagesList = data['data'] as List<dynamic>;
            _logger.d('🔵 Found data array with ${messagesList.length} items');
          } else {
            _logger.e('🔴 Unknown response structure. Keys found: ${data.keys.join(", ")}');
            throw FormatException(
              'Expected array or object with messages/items/data key, got: ${data.keys.join(", ")}',
            );
          }
        } else {
          throw FormatException(
            'Expected List or Map but got ${data.runtimeType} for recent messages endpoint',
          );
        }

        try {
          final messageDtos = messagesList
              .map((json) => MessageDto.fromJson(json as Map<String, dynamic>))
              .toList();

          _logger.d('Successfully parsed ${messageDtos.length} messages');

          // DEBUG: Log message order from API
          if (messageDtos.isNotEmpty) {
            _logger.d('🔵 Message order from API (direction: $direction):');
            for (var i = 0; i < messageDtos.length && i < 3; i++) {
              final dto = messageDtos[i];
              _logger.d('🔵   Position $i: ${dto.createdAt} (ID: ${dto.messageId})');
            }
            if (messageDtos.length > 3) {
              _logger.d('🔵   ... (${messageDtos.length - 3} more messages)');
            }
          }

          return messageDtos;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse recent messages: $e', error: e, stackTrace: stack);
          throw ServerException(statusCode: 422, message: 'Failed to parse messages: $e');
        }
      } else {
        _logger.e('Failed to fetch recent messages: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch recent messages',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching recent messages', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch recent messages: $e');
    }
  }

  @override
  Future<MessageDetailDto> getMessage(String messageId, {bool includePreSignedUrls = false}) async {
    try {
      // Build URL with optional pre-signed URLs parameter
      final queryParam = includePreSignedUrls ? '?presigned_url=true' : '';

      // Try v5 endpoint first, fallback to v4
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v5/messages/$messageId$queryParam',
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // Extract the actual message data from the nested structure
          final Map<String, dynamic> messageData;
          if (data.containsKey('message') && data['message'] is Map<String, dynamic>) {
            messageData = data['message'] as Map<String, dynamic>;
          } else {
            messageData = data;
          }

          // Parse the message data into MessageDetailDto
          final messageDetailDto = MessageDetailDto.fromJson(messageData);
          return messageDetailDto;
        } catch (e, stack) {
          _logger.e('Failed to parse message JSON: $e', error: e, stackTrace: stack);
          _logger.d('Message data that failed parsing: $data');
          throw ServerException(statusCode: 422, message: 'Invalid message JSON structure: $e');
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
