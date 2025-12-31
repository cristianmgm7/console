import 'dart:async';

import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter and categorize ADK events for the chat UI.
///
/// This use case processes ADK events as they stream in and categorizes
/// events relevant to the chat UI:
/// - ChatMessageEvent for text content (can be partial with streaming)
/// - [FunctionCallEvent] for "thinking..." status indicators
/// - FunctionResponseEvent for function completion (clears "thinking...")
/// - [AuthenticationRequestEvent] for OAuth requests
/// - [AgentErrorEvent] for errors that should be displayed in chat
///
/// The use case applies business logic to filter and transform raw ADK events
/// into categorized events that the UI can easily consume.
@injectable
class GetChatMessagesFromEventsUseCase {
  const GetChatMessagesFromEventsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process events for a session as a stream of categorized events.
  ///
  /// This method transforms the raw event stream from the repository into
  /// categorized events that are relevant for the chat UI. Events are
  /// processed and categorized in real-time as they arrive.
  ///
  /// [streaming] - If true, enables token-level streaming for partial messages.
  /// If false (default), streams complete messages as they become available.
  Stream<CategorizedEvent> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
    bool streaming = false,
  }) {
    try {
      _logger.d('📤 Starting event categorization stream');

      // Get raw event stream from repository
      final eventStream = _repository.sendMessageStream(
        sessionId: sessionId,
        content: message,
        context: context,
        streaming: streaming,
      );

      // Transform raw events into categorized events
      return eventStream.transform(
        StreamTransformer<AdkEvent, CategorizedEvent>.fromHandlers(
          handleData: (AdkEvent event, EventSink<CategorizedEvent> sink) {
            _logger.d('Processing event from ${event.author}');

            // --- Filtering & Categorization Logic (Business Rules) ---

            // 1. Authentication requests (high priority)
            if (event.isAuthenticationRequest) {
              _logger.d('Auth request detected for: ${event.authenticationRequest!.provider}');
              sink.add(AuthenticationRequestEvent(
                sourceEvent: event,
                request: event.authenticationRequest!,
              ));
              // Continue to check for other content in the same event
            }

            // 2. Function calls (for "thinking..." status indicators)
            if (event.functionCalls.isNotEmpty) {
              for (final call in event.functionCalls) {
                _logger.d('Function call: ${call.name}');
                sink.add(FunctionCallEvent(
                  sourceEvent: event,
                  functionName: call.name,
                  args: call.args,
                ));
              }
            }

            // 3. Function responses (to clear "thinking..." status)
            for (final part in event.content.parts) {
              if (part.functionResponse != null) {
                _logger.d('Function response: ${part.functionResponse!.name}');
                sink.add(FunctionResponseEvent(
                  sourceEvent: event,
                  functionName: part.functionResponse!.name,
                  response: part.functionResponse!.response,
                ));
              }
            }

            // 4. Text content (actual chat messages - can be partial)
            final textContent = event.textContent;
            if (textContent != null && textContent.isNotEmpty) {
              final preview = textContent.length > 50
                  ? '${textContent.substring(0, 50)}...'
                  : textContent;
              _logger.d('Chat message: $preview');

              sink.add(ChatMessageEvent(
                sourceEvent: event,
                text: textContent,
                isPartial: event.partial,
              ));
            }

            // Note: Internal events (state updates, etc.) are filtered out
            // by simply not emitting them to the sink
          },
          handleError: (error, stackTrace, sink) {
            _logger.e('Error in event stream', error: error, stackTrace: stackTrace);
            // Emit error as categorized event
            sink.add(AgentErrorEvent(
              sourceEvent: AdkEvent(
                id: 'error_${DateTime.now().millisecondsSinceEpoch}',
                invocationId: 'error',
                author: 'system',
                timestamp: DateTime.now(),
                content: const AdkContent(role: 'system', parts: []),
              ),
              errorMessage: error.toString(),
            ));
          },
          handleDone: (sink) {
            _logger.i('✅ Event stream completed');
            sink.close();
          },
        ),
      );
    } on Exception catch (e, stackTrace) {
      _logger.e('Error creating event stream', error: e, stackTrace: stackTrace);
      // Return a stream with a single error event
      return Stream.value(AgentErrorEvent(
        sourceEvent: AdkEvent(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          invocationId: 'error',
          author: 'system',
          timestamp: DateTime.now(),
          content: const AdkContent(role: 'system', parts: []),
        ),
        errorMessage: e.toString(),
      ));
    }
  }

  /// Legacy batch processing method (for backward compatibility)
  ///
  /// @deprecated Use the streaming version (call method) instead
  Future<Result<List<CategorizedEvent>>> callBatch({
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
              categorizedEvents.add(ChatMessageEvent(
                sourceEvent: event,
                text: textContent,
                isPartial: false,
              ));
            }
          }

          _logger.i('✅ Processed ${categorizedEvents.length} chat events');
          return success(categorizedEvents);
        },
        onFailure: (failure) {
          _logger.e('Failed to get events from repository', error: failure);
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
