import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for chat messages and function call indicators.
///
/// This use case processes ADK events and categorizes events relevant to the chat UI:
/// - ChatMessageEvent for text content
/// - [FunctionCallEvent] for "thinking..." status indicators
/// - FunctionResponseEvent for function completion (clears "thinking...")
/// - [AgentErrorEvent] for errors that should be displayed in chat
///
/// Authentication requests are explicitly filtered out and handled by
/// GetAuthenticationRequestsUseCase instead.
///
/// Used by ChatBloc to maintain chat UI state and show appropriate
/// status indicators during agent execution.
@injectable
class GetChatMessagesFromEventsUseCase {
  const GetChatMessagesFromEventsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process events for a session, returning chat-relevant events
  Future<Result<List<CategorizedEvent>>> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {

      final eventsResult = await _repository.sendMessage(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      return eventsResult.fold(
        onSuccess: (events) {
          final categorizedEvents = <CategorizedEvent>[];

          for (final event in events) {
            _logger.d('Processing event from ${event.author}');

            // Include authentication requests (will be forwarded by ChatBloc)
            if (event.isAuthenticationRequest) {
              _logger.d('Including auth request in categorized events');
              final authRequest = event.authenticationRequest!;
              categorizedEvents.add(AuthenticationRequestEvent(
                sourceEvent: event,
                request: authRequest,
              ));
              // Continue to check for other content in the same event
            }

            // 1. Function calls (for "thinking..." status)
            if (event.functionCalls.isNotEmpty) {
              for (final call in event.functionCalls) {
                _logger.d('Function call: ${call.name}');
                categorizedEvents.add(FunctionCallEvent(
                  sourceEvent: event,
                  functionName: call.name,
                  args: call.args,
                ));
              }
            }

            // 2. Function responses (to clear "thinking..." status)
            for (final part in event.content.parts) {
              if (part.functionResponse != null) {
                _logger.d('Function response: ${part.functionResponse!.name}');
                categorizedEvents.add(FunctionResponseEvent(
                  sourceEvent: event,
                  functionName: part.functionResponse!.name,
                  response: part.functionResponse!.response,
                ));
              }
            }

            // 3. Text content (actual chat messages)
            final textContent = event.textContent;
            if (textContent != null && textContent.isNotEmpty) {
              _logger.d('Chat message: ${textContent.substring(0, textContent.length > 50 ? 50 : textContent.length)}...');
              categorizedEvents.add(ChatMessageEvent(
                sourceEvent: event,
                text: textContent,
                isPartial: false, // No partial messages with /run endpoint
              ));
            }
          }

          _logger.i('✅ Processed ${categorizedEvents.length} chat events');
          return success(categorizedEvents);
        },
        onFailure: (failure) {
          _logger.e('Failed to get events from repository', error: failure);
          // Return error as a categorized event
          final errorEvent = AgentErrorEvent(
            sourceEvent: AdkEvent(
              id: '',
              invocationId: '',
              author: 'system',
              timestamp: DateTime.now(),
              content: const AdkContent(role: 'system', parts: []),
            ),
            errorMessage: failure.failure.details ?? 'Failed to get events',
          );
          return success([errorEvent]);
        },
      );
    } on Exception catch (e, stackTrace) {
      _logger.e('Error processing chat events', error: e, stackTrace: stackTrace);
      // Return error as a categorized event
      final errorEvent = AgentErrorEvent(
        sourceEvent: AdkEvent(
          id: '',
          invocationId: '',
          author: 'system',
          timestamp: DateTime.now(),
          content: const AdkContent(role: 'system', parts: []),
        ),
        errorMessage: e.toString(),
      );
      return success([errorEvent]);
    }
  }
}
