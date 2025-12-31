import 'dart:async';
import 'dart:convert';

import 'package:carbon_voice_console/core/api/generated/lib/api.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/agent_chat/data/config/adk_config.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/adk_event_mapper.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class AdkApiService {

  AdkApiService(this._client, this._logger) : _api = DefaultApi();

  final http.Client _client;
  final Logger _logger;
  final DefaultApi _api;

  /// Create a new session
  Future<Session> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? initialState,
  }) async {
    _logger.d('Creating session for user: $userId, session: $sessionId');

    try {
      final request = CreateSessionRequest(
        sessionId: sessionId,
        state: (initialState ?? {}).cast<String, Object>(),
        events: [],
      );

      final session = await _api.appsAppNameUsersUserIdSessionsPost(
        AdkConfig.appName,
        userId,
        createSessionRequest: request,
      );

      if (session != null) {
        return session;
      } else {
        throw ServerException(
          statusCode: 500,
          message: 'Failed to create session: API returned null',
        );
      }
    } catch (e) {
      _logger.e('Error creating session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to create session: $e');
    }
  }

  /// Get session details
  Future<Session> getSession({
    required String userId,
    required String sessionId,
  }) async {
    _logger.d('Getting session for user: $userId, session: $sessionId');

    try {
      final session = await _api.appsAppNameUsersUserIdSessionsSessionIdGet(
        AdkConfig.appName,
        userId,
        sessionId,
      );

      if (session != null) {
        return session;
      } else {
        throw ServerException(
          statusCode: 404,
          message: 'Session not found',
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
    _logger.d('Deleting session for user: $userId, session: $sessionId');

    try {
      await _api.appsAppNameUsersUserIdSessionsSessionIdDelete(
        AdkConfig.appName,
        userId,
        sessionId,
      );
    } catch (e) {
      _logger.e('Error deleting session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to delete session: $e');
    }
  }

  /// Send message to agent using SSE streaming endpoint
  Stream<Event> sendMessageStream({
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
            // Use extended actions parsing to support authentication fields
            final event = parseEventWithExtendedActions(eventJson);
            if (event != null) {
              _logger.d('📥 Received event from ${event.author}');
              yield event;
            }
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
  Future<List<Event>> sendMessage({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    _logger.d('Sending message to agent for user: $userId, session: $sessionId');

    try {
      // Create content with text message
      final contentPart = ContentPartsInner(text: message);
      final content = Content(
        role: ContentRoleEnum.user,
        parts: [contentPart],
      );

      final request = RunAgentRequest(
        appName: AdkConfig.appName,
        userId: userId,
        sessionId: sessionId,
        newMessage: content,
      );

      final events = await _api.runPost(request);

      if (events != null) {
        _logger.d('✅ Received ${events.length} events from agent');
        return events;
      } else {
        throw ServerException(
          statusCode: 500,
          message: 'Failed to send message: API returned null',
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
