import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for chat messages and function call indicators
///
/// This use case processes the raw event stream and yields:
/// - ChatMessageEvent for text content (complete and partial)
/// - FunctionCallEvent for "thinking..." indicators
/// - FunctionResponseEvent for function completion
/// - AgentErrorEvent for errors
@injectable
class GetChatMessagesFromEventsUseCase {
  const GetChatMessagesFromEventsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process event stream for a session, yielding chat-relevant events
  Stream<CategorizedEvent> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.i('Starting chat event stream for session: $sessionId');

      final eventStream = _repository.sendMessageStreaming(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      await for (final event in eventStream) {
        _logger.d('Processing event from ${event.author}');

        // Skip authentication requests (handled by auth use case)
        if (event.isAuthenticationRequest) {
          _logger.d('Skipping auth request in chat stream');
          continue;
        }

        // 1. Function calls (for "thinking..." status)
        if (event.functionCalls.isNotEmpty) {
          for (final call in event.functionCalls) {
            _logger.d('Function call: ${call.name}');
            yield FunctionCallEvent(
              sourceEvent: event,
              functionName: call.name,
              args: call.args,
            );
          }
        }

        // 2. Function responses (to clear "thinking..." status)
        for (final part in event.content.parts) {
          if (part.functionResponse != null) {
            _logger.d('Function response: ${part.functionResponse!.name}');
            yield FunctionResponseEvent(
              sourceEvent: event,
              functionName: part.functionResponse!.name,
              response: part.functionResponse!.response,
            );
          }
        }

        // 3. Text content (actual chat messages)
        final textContent = event.textContent;
        if (textContent != null && textContent.isNotEmpty) {
          _logger.d('Chat message (${event.partial ? "partial" : "complete"}): '
              '${textContent.substring(0, textContent.length > 50 ? 50 : textContent.length)}...');
          yield ChatMessageEvent(
            sourceEvent: event,
            text: textContent,
            isPartial: event.partial,
          );
        }
      }

      _logger.i('Chat event stream completed for session: $sessionId');
    } catch (e, stackTrace) {
      _logger.e('Error in chat event stream', error: e, stackTrace: stackTrace);
      yield AgentErrorEvent(
        sourceEvent: AdkEvent(
          id: '',
          invocationId: '',
          author: 'system',
          timestamp: DateTime.now(),
          content: const AdkContent(role: 'system', parts: []),
        ),
        errorMessage: e.toString(),
      );
    }
  }
}
