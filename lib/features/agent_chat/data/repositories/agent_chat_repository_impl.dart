import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
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
  Stream<AdkEvent> sendMessageStream({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
    bool streaming = true,
  }) async* {
    try {
      // Get event stream from API
      final eventStream = _apiService.sendMessageStream(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
        streaming: streaming,
      );

      // Transform DTOs to domain events as they arrive
      await for (final eventDto in eventStream) {
        try {
          final adkEvent = eventDto.toAdkEvent();
          _logger.d('📥 Yielding event from ${adkEvent.author}');
          yield adkEvent;
        } on Exception catch (e) {
          _logger.e('Error mapping event DTO', error: e);
          // Continue processing other events
        }
      }
      

      _logger.i('✅ Stream completed successfully');
    } on ServerException catch (e) {
      _logger.e('Server error in message stream', error: e);
      // Yield error event
      yield _createErrorEvent('Server error: ${e.message}');
    } on NetworkException catch (e) {
      _logger.e('Network error in message stream', error: e);
      // Yield error event
      yield _createErrorEvent('Network error: ${e.message}');
    } on Exception catch (e, stackTrace) {
      _logger.e('Unexpected error in message stream', error: e, stackTrace: stackTrace);
      // Yield error event
      yield _createErrorEvent('Unexpected error: $e');
    }
  }

  /// Helper to create an error event
  AdkEvent _createErrorEvent(String message) {
    return AdkEvent(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      invocationId: 'error',
      author: 'system',
      timestamp: DateTime.now(),
      content: AdkContent(
        role: 'model',
        parts: [
          AdkPart(text: '⚠️ $message'),
        ],
      ),
    );
  }

  @override
  Future<Result<List<AdkEvent>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async {
    try {
      _logger.d('📤 Sending message for session: $sessionId');

      // Get all events at once from API
      final eventDtos = await _apiService.sendMessage(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      );

      _logger.d('📥 Received ${eventDtos.length} events from API');

      // Convert all DTOs to domain events
      final adkEvents = <AdkEvent>[];
      for (var i = 0; i < eventDtos.length; i++) {
        final eventDto = eventDtos[i];

        // Map DTO to domain event
        final adkEvent = eventDto.toAdkEvent();

        adkEvents.add(adkEvent);
      }

      _logger.i('✅ Successfully processed ${adkEvents.length} events');
      return success(adkEvents);
    } on ServerException catch (e) {
      _logger.e('Server error sending message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error sending message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stackTrace) {
      _logger.e('Unexpected error sending message', error: e, stackTrace: stackTrace);
      return failure(UnknownFailure(details: 'Failed to send message: $e'));
    }
  }

  @override
  Future<Result<void>> sendAuthenticationCredentials({
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
      await _apiService.sendMessage(
        userId: _userId,
        sessionId: sessionId,
        message: credentialMessage.toString(), // Empty text, function response in parts
        context: credentialMessage,
      );

      _logger.i('Authentication credentials sent successfully');
      return success(null);
    } on ServerException catch (e) {
      _logger.e('Server error sending credentials', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error sending credentials', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stackTrace) {
      _logger.e('Unexpected error sending credentials', error: e, stackTrace: stackTrace);
      return failure(UnknownFailure(details: 'Failed to send credentials: $e'));
    }
  }
}
