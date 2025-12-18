import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_detail_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/send_message_request_dto.dart';
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
      final requestBody = {
        'date': beforeTimestamp,
        'channel_id': conversationId,
        'limit': count,
        'direction': direction,
        'use_last_updated': true,
      };
      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/recent',
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        List<dynamic> messagesList;

        messagesList = data as List<dynamic>;

        try {
          final messageDtos = messagesList
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
      final queryParam = includePreSignedUrls ? '?presigned_url=true' : '';

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v5/messages/$messageId$queryParam',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          final Map<String, dynamic> messageData;
          if (data.containsKey('message') && data['message'] is Map<String, dynamic>) {
            messageData = data['message'] as Map<String, dynamic>;
          } else {
            messageData = data;
          }
          final messageDetailDto = MessageDetailDto.fromJson(messageData);
          return messageDetailDto;
        } catch (e, stack) {
          _logger.e('Failed to parse message JSON: $e', error: e, stackTrace: stack);
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

  @override
  Future<MessageDto> sendMessage(SendMessageRequestDto request) async {
    try {
      final requestBody = request.toJson();

      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/start',
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          final messageDto = MessageDto.fromJson(data);
          return messageDto;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse send message response: $e', error: e, stackTrace: stack);
          throw ServerException(statusCode: 422, message: 'Failed to parse response: $e');
        }
      } else {
        _logger.e('Failed to send message: ${response.statusCode}');
        _logger.e('Response headers: ${response.headers}');
        _logger.e('Response body: ${response.body}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to send message: ${response.body}',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error sending message', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to send message: $e');
    }
  }
}
