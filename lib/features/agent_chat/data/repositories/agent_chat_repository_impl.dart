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

  // Track stream instances for debugging
  static int _streamCounter = 0;

  @override
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async* {
    final streamId = ++_streamCounter;
    try {
      _logger.d('🌊 [Stream #$streamId] Starting message streaming for session: $sessionId');

      await for (final eventDto in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      )) {
        _logger.d('🌊 [Stream #$streamId] Received EventDto from API: author=${eventDto.author}, partial=${eventDto.partial}');
        
        // Check if this MIGHT be an auth event by looking at function names
        final hasAuthLikeFunction = eventDto.content.parts.any((p) => 
          p.functionCall?.name.contains('credential') == true ||
          p.functionCall?.name.contains('auth') == true
        ) || (eventDto.actions?.functionCalls?.any((c) =>
          c.name.contains('credential') || c.name.contains('auth')
        ) ?? false);
        
        if (hasAuthLikeFunction) {
          _logger.i('🔐 [Stream #$streamId] ⚠️ EVENT HAS AUTH-LIKE FUNCTION - dumping full DTO JSON');
          try {
            _logger.i('🔐 [Stream #$streamId] Raw DTO JSON: ${eventDto.toJson()}');
          } catch (e) {
            _logger.e('Failed to serialize DTO', error: e);
          }
        }
        
        // Log raw DTO structure for debugging
        _logger.d('🌊 [Stream #$streamId]   DTO content.parts count: ${eventDto.content.parts.length}');
        for (var i = 0; i < eventDto.content.parts.length; i++) {
          final part = eventDto.content.parts[i];
          _logger.d('🌊 [Stream #$streamId]   Part $i: text=${part.text?.substring(0, 20) ?? "null"}, '
              'funcCall=${part.functionCall?.name ?? "null"}, '
              'funcResp=${part.functionResponse?.name ?? "null"}');
          
          // Log function call args if present
          if (part.functionCall != null) {
            _logger.d('🌊 [Stream #$streamId]     FunctionCall args: ${part.functionCall!.args}');
          }
        }
        if (eventDto.actions != null) {
          _logger.d('🌊 [Stream #$streamId]   DTO actions.functionCalls count: ${eventDto.actions!.functionCalls?.length ?? 0}');
          if (eventDto.actions!.functionCalls != null) {
            for (var call in eventDto.actions!.functionCalls!) {
              _logger.d('🌊 [Stream #$streamId]     Action function call: ${call.name}, args: ${call.args}');
            }
          }
        }

        // Map DTO to domain event (no filtering!)
        final adkEvent = eventDto.toAdkEvent();

        // Detailed logging for debugging
        _logger.d('🌊 [Stream #$streamId] Mapped to AdkEvent: author=${adkEvent.author}, '
            'text=${adkEvent.textContent?.substring(0, 50) ?? "none"}, '
            'functionCalls=${adkEvent.functionCalls.map((c) => c.name).join(", ")}, '
            'isAuthRequest=${adkEvent.isAuthenticationRequest}');
        
        // Extra logging for function calls
        if (adkEvent.functionCalls.isNotEmpty) {
          for (final call in adkEvent.functionCalls) {
            _logger.d('🌊 [Stream #$streamId]   Function call: ${call.name}, args: ${call.args}');
            if (call.name == 'adk_request_credential') {
              _logger.i('🔐 [Stream #$streamId] FOUND adk_request_credential in repository!');
              _logger.i('🔐 [Stream #$streamId] Auth request args: ${call.args}');
            }
          }
        }

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
