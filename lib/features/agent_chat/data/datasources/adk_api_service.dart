import 'dart:async';
import 'dart:convert';

import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/agent_chat/data/config/adk_config.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/session_dto.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class AdkApiService {

  AdkApiService(this._client, this._logger);

  final http.Client _client;
  final Logger _logger;

  /// Create a new session
  Future<SessionDto> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? initialState,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Creating session: $url');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(initialState ?? {}),
          )
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SessionDto.fromJson(data);
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to create session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error creating session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to create session: $e');
    }
  }

  /// Get session details
  Future<SessionDto> getSession({
    required String userId,
    required String sessionId,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Getting session: $url');

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SessionDto.fromJson(data);
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to get session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error getting session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to get session: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession({
    required String userId,
    required String sessionId,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Deleting session: $url');

    try {
      final response = await _client
          .delete(url)
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to delete session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error deleting session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to delete session: $e');
    }
  }

  /// Send message to agent using SSE streaming endpoint
  Stream<EventDto> sendMessageStream({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
    bool streaming = false,
  }) async* {
    final url = Uri.parse('${AdkConfig.baseUrl}/run_sse');

    final requestBody = {
      'appName': AdkConfig.appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message},
          if (context != null) {'metadata': context},
        ],
      },
      'streaming': streaming, // false = message-level, true = token-level
    };

    _logger.d('Sending message to /run_sse: $url');
    _logger.d('Request body: ${jsonEncode(requestBody)}');

    try {
      final request = http.Request('POST', url)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode(requestBody);

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw ServerException(
          statusCode: streamedResponse.statusCode,
          message: 'Failed to send message: $body',
        );
      }

      // Parse SSE stream
      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        
        // SSE format: "data: {json}"
        if (chunk.startsWith('data: ')) {
          final jsonString = chunk.substring(6); // Remove "data: " prefix
          
          if (jsonString.trim().isEmpty) continue;
          
          try {
            final eventJson = jsonDecode(jsonString) as Map<String, dynamic>;
            final eventDto = EventDto.fromJson(eventJson);
            _logger.d('📥 Received event from ${eventDto.author}');
            yield eventDto;
          } on Exception catch (e) {
            _logger.w('Failed to parse event: $jsonString', error: e);
          }
        }
      }

      _logger.d('✅ Stream completed');
    } catch (e) {
      _logger.e('Error in message stream', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to stream message: $e');
    }
  }

  /// Send message to agent (single response - kept for backward compatibility)
  Future<List<EventDto>> sendMessage({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final url = Uri.parse('${AdkConfig.baseUrl}/run');

    final requestBody = {
      'appName': AdkConfig.appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message},
          if (context != null) {'metadata': context},
        ],
      },
    };

    _logger.d('Sending message to /run: $url');
    _logger.d('Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final eventsJson = jsonDecode(response.body) as List;
        _logger.d('✅ Received ${eventsJson.length} events from agent');
        return eventsJson.map((e) => EventDto.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to send message: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error sending message', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to send message: $e');
    }
  }

  /// Check if ADK server is reachable
  Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('${AdkConfig.baseUrl}/health');
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } on Exception catch (e) {
      _logger.w('Health check failed', error: e);
      return false;
    }
  }
}
