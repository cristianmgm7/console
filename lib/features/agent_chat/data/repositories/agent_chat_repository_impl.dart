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
        
        // Check if this MIGHT be an auth event by looking at function names
        final hasAuthLikeFunction = eventDto.content.parts.any((p) => 
          p.functionCall?.name.contains('credential') == true ||
          p.functionCall?.name.contains('auth') == true
        ) || (eventDto.actions?.functionCalls?.any((c) =>
          c.name.contains('credential') || c.name.contains('auth')
        ) ?? false);
        
        if (hasAuthLikeFunction) {
          _logger.i('🔐 [Event #$i] ⚠️ EVENT HAS AUTH-LIKE FUNCTION - dumping full DTO JSON');
          try {
            _logger.i('🔐 [Event #$i] Raw DTO JSON: ${eventDto.toJson()}');
          } catch (e) {
            _logger.e('Failed to serialize DTO', error: e);
          }
        }

        // Map DTO to domain event
        final adkEvent = eventDto.toAdkEvent();

        // Detailed logging for debugging
        _logger.d('📋 [Event #$i] Mapped AdkEvent: author=${adkEvent.author}, '
            'text=${adkEvent.textContent?.substring(0, 50) ?? "none"}, '
            'functionCalls=${adkEvent.functionCalls.map((c) => c.name).join(", ")}, '
            'isAuthRequest=${adkEvent.isAuthenticationRequest}');
        
        // Extra logging for function calls
        if (adkEvent.functionCalls.isNotEmpty) {
          for (final call in adkEvent.functionCalls) {
            _logger.d('📋 [Event #$i]   Function call: ${call.name}, args: ${call.args}');
            if (call.name == 'adk_request_credential') {
              _logger.i('🔐 [Event #$i] FOUND adk_request_credential in repository!');
              _logger.i('🔐 [Event #$i] Auth request args: ${call.args}');
            }
          }
        }

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
    } catch (e, stackTrace) {
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
        message: '', // Empty text, function response in parts
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
    } catch (e, stackTrace) {
      _logger.e('Unexpected error sending credentials', error: e, stackTrace: stackTrace);
      return failure(UnknownFailure(details: 'Failed to send credentials: $e'));
    }
  }
}
