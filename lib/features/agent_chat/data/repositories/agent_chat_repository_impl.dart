import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
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
  Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
    required String sessionId,
    required String content,
    required void Function(String status, String? subAgent) onStatus, Map<String, dynamic>? context,
    void Function(String chunk)? onMessageChunk,
  }) async {
    try {
      final agentMessages = <AgentChatMessage>[];

      await for (final eventDto in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      )) {
        // Check for status updates (function calls)
        final statusMsg = eventDto.getStatusMessage();
        if (statusMsg != null) {
          String? subAgent;
          if (eventDto.author.contains('github')) {
            subAgent = 'GitHub Agent';
          } else if (eventDto.author.contains('carbon')) {
            subAgent = 'Carbon Voice Agent';
          } else if (eventDto.author.contains('market') || eventDto.author.contains('analyzer')) {
            subAgent = 'Market Analyzer';
          }

          onStatus(statusMsg, subAgent);
        }

        // Convert to message
        final message = eventDto.toDomain(sessionId);
        if (message != null) {
          agentMessages.add(message);
        }
      }

      return success(agentMessages);
    } on ServerException catch (e) {
      _logger.e('Server error streaming message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error streaming message', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error streaming message', error: e);
      return failure(const UnknownFailure(details: 'Failed to stream message'));
    }
  }
}
