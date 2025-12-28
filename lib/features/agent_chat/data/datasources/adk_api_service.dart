import 'dart:async';
import 'dart:convert';

import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/agent_chat/data/config/adk_config.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@lazySingleton
class AdkApiService {

  AdkApiService(this._client, this._logger);

  final http.Client _client;
  final Logger _logger;

  /// Create a new session
  Future<Map<String, dynamic>> createSession({
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
        return jsonDecode(response.body) as Map<String, dynamic>;
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
  Future<Map<String, dynamic>> getSession({
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
        return jsonDecode(response.body) as Map<String, dynamic>;
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

  /// Send message to agent (streaming with SSE)
  Stream<Map<String, dynamic>> sendMessageStreaming({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async* {
    final url = Uri.parse('${AdkConfig.baseUrl}/chat/stream');

    final requestBody = {
      'user_id': userId,
      'message': message,
      if (sessionId.isNotEmpty) 'session_id': sessionId,
      if (context != null) 'context': context,
    };

    _logger.d('Sending streaming message: $url');
    _logger.d('Request body: ${jsonEncode(requestBody)}');

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw ServerException(
          statusCode: streamedResponse.statusCode,
          message: 'Failed to send streaming message',
        );
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // SSE format: "event: event_name\ndata: {...}\n\n"
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6); // Remove "data: " prefix
            try {
              final event = jsonDecode(jsonData) as Map<String, dynamic>;
              yield event;
            } catch (e) {
              _logger.w('Failed to parse SSE event: $line', error: e);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error in streaming message', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to stream message: $e');
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
    } catch (e) {
      _logger.w('Health check failed', error: e);
      return false;
    }
  }
}
