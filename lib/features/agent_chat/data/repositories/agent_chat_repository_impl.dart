import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/adk_event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {
  AgentChatRepositoryImpl(
    this._apiService,
    this._logger,
  );

  final AdkApiService _apiService;
  final Logger _logger;

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'test_user'; // Placeholder - matches ADK test user
  }

  @override
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.d('Streaming message for session: $sessionId');

      await for (final eventDto in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      )) {
        // Map DTO to domain event (no filtering!)
        final adkEvent = eventDto.toAdkEvent();

        _logger.d('Event from ${adkEvent.author}: '
            'text=${adkEvent.textContent?.substring(0, 50) ?? "none"}, '
            'functionCalls=${adkEvent.functionCalls.map((c) => c.name).join(", ")}');

        yield adkEvent;
      }
    } on ServerException catch (e) {
      _logger.e('Server error streaming message', error: e);
      throw ServerException(statusCode: e.statusCode, message: e.message);
    } on NetworkException catch (e) {
      _logger.e('Network error streaming message', error: e);
      throw NetworkException(message: e.message);
    } catch (e) {
      _logger.e('Unexpected error streaming message', error: e);
      throw NetworkException(message: 'Failed to stream message: $e');
    }
  }

  @override
  Future<void> sendAuthenticationCredentials({
    required String sessionId,
    required String provider,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    try {
      _logger.i('Sending authentication credentials for provider: $provider');

      // Construct credential message to send back to agent
      final response = <String, dynamic>{
        'provider': provider,
        'access_token': accessToken,
      };

      if (refreshToken != null) {
        response['refresh_token'] = refreshToken;
      }
      if (expiresAt != null) {
        response['expires_at'] = expiresAt.toIso8601String();
      }

      final credentialMessage = {
        'role': 'user',
        'parts': [
          {
            'functionResponse': {
              'name': 'adk_request_credential',
              'response': response,
            },
          },
        ],
      };

      // Send credential as a message back to the agent
      await _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: '', // Empty text, function response in parts
        context: credentialMessage,
      ).forEach((_) {
        // Consume the stream but don't need to process response
        // The agent will acknowledge receipt
      });

      _logger.i('Authentication credentials sent successfully');
    } on ServerException catch (e) {
      _logger.e('Server error sending credentials', error: e);
      throw ServerException(statusCode: e.statusCode, message: e.message);
    } on NetworkException catch (e) {
      _logger.e('Network error sending credentials', error: e);
      throw NetworkException(message: e.message);
    } catch (e) {
      _logger.e('Unexpected error sending credentials', error: e);
      throw NetworkException(message: 'Failed to send credentials: $e');
    }
  }
}
