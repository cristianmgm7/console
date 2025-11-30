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
  Future<List<MessageDto>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  }) async {
    try {
      final stop = start + count;

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
        // Convert each message JSON to DTO
        final messages = <MessageDto>[];
        for (final json in messagesJson) {
          try {
            if (json is! Map<String, dynamic>) {
              throw FormatException('Message item is not a Map: ${json.runtimeType}');
            }
            final messageDto = MessageDto.fromJson(json);
            messages.add(messageDto);
          } on Exception catch (e, stack) {
            _logger.e('Failed to parse message in list: $e', error: e, stackTrace: stack);
            throw ServerException(statusCode: 422, message: 'Failed to parse message in list: $e');
          }
        }

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
  Future<MessageDetailDto> getMessage(String messageId, {bool includePreSignedUrls = false}) async {
    try {
      // Build URL with optional pre-signed URLs parameter
      final queryParam = includePreSignedUrls ? '?include_presigned_urls=true' : '';

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
