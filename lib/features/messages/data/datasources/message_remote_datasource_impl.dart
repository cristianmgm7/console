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
    String direction = 'older',
    String? beforeTimestamp,
  }) async {
    try {
      // Build request body
      final requestBody = {
        'channel_guid': conversationId,
        'count': count,
        'direction': direction,
      };

      // Add optional beforeTimestamp for pagination cursor
      if (beforeTimestamp != null) {
        requestBody['before'] = beforeTimestamp;
      }

      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/recent',
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // API returns: [{message}, {message}, ...]
        if (data is! List) {
          throw FormatException(
            'Expected List but got ${data.runtimeType} for recent messages endpoint',
          );
        }

        try {
          final messageDtos = data
              .map((json) => MessageDto.fromJson(json as Map<String, dynamic>))
              .toList();
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
