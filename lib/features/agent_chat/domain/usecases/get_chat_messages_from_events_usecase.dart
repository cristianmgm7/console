import 'dart:async';

import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_content.dart';
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
            }

            // 2. Agent State Updates (Deltas)
            if (event.actions?.stateDelta != null) {
              _logger.d('State delta received');
              sink.add(StateUpdateEvent(
                sourceEvent: event,
                stateDelta: event.actions!.stateDelta!,
              ));
            }

            // 3. Artifact Updates (File changes)
            if (event.actions?.artifactDelta != null) {
              _logger.d('Artifact delta received');
              sink.add(ArtifactUpdateEvent(
                sourceEvent: event,
                artifactDelta: event.actions!.artifactDelta!,
              ));
            }

            // To encapsulate this logic we need to check if the event is a tool confirmation request and add the needed classes as authrequest 
            // 4. Tool Confirmations
            if (event.isToolConfirmationRequest) {
               // Map tool confirmations map to events
               event.actions!.requestedToolConfirmations!.forEach((key, value) {
                  if (value is Map<String, dynamic>) {
                      sink.add(ToolConfirmationEvent(
                        sourceEvent: event,
                        toolCallId: key, // Assuming key is toolCallId
                        functionName: value['name'] as String? ?? 'unknown',
                        args: value['args'] as Map<String, dynamic>? ?? {},
                      ));
                  }
               });
            }

            // 5. Processing Content Parts (Polymorphic)
            for (final part in event.content.parts) {
              // Function Calls (Thinking status)
              if (part is AdkFunctionCallPart) {
                _logger.d('Function call: ${part.name}');
                sink.add(FunctionCallEvent(
                  sourceEvent: event,
                  functionName: part.name,
                  args: part.args,
                ));
              }
              // Function Responses (Clear thinking status)
              else if (part is AdkFunctionResponsePart) {
                _logger.d('Function response: ${part.name}');
                sink.add(FunctionResponseEvent(
                  sourceEvent: event,
                  functionName: part.name,
                  response: part.response,
                ));
              }
              // Text Content
              else if (part is AdkTextPart) {
                 final text = part.text;
                 if (text.isNotEmpty) {
                    final preview = text.length > 50
                      ? '${text.substring(0, 50)}...'
                      : text;
                    _logger.d('Chat message: $preview');

                    sink.add(ChatMessageEvent(
                      sourceEvent: event,
                      text: text,
                      isPartial: event.partial,
                    ));
                 }
              }
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
            // Process events in batch (similar logic to streaming)

            // 1. Authentication
            if (event.isAuthenticationRequest) {
              categorizedEvents.add(AuthenticationRequestEvent(
                sourceEvent: event,
                request: event.authenticationRequest!,
              ));
            }

            // 2. State Deltas
            if (event.actions?.stateDelta != null) {
              categorizedEvents.add(StateUpdateEvent(
                sourceEvent: event,
                stateDelta: event.actions!.stateDelta!,
              ));
            }

             // 3. Artifact Deltas
            if (event.actions?.artifactDelta != null) {
              categorizedEvents.add(ArtifactUpdateEvent(
                sourceEvent: event,
                artifactDelta: event.actions!.artifactDelta!,
              ));
            }

             // 4. Tool Confirmations
            if (event.actions?.requestedToolConfirmations != null) {
               event.actions!.requestedToolConfirmations!.forEach((key, value) {
                  if (value is Map<String, dynamic>) {
                      categorizedEvents.add(ToolConfirmationEvent(
                        sourceEvent: event,
                        toolCallId: key,
                        functionName: value['name'] as String? ?? 'unknown',
                        args: value['args'] as Map<String, dynamic>? ?? {},
                      ));
                  }
               });
            }

            // 5. Content Parts
            for (final part in event.content.parts) {
              if (part is AdkFunctionCallPart) {
                _logger.d('Function call: ${part.name}');
                categorizedEvents.add(FunctionCallEvent(
                  sourceEvent: event,
                  functionName: part.name,
                  args: part.args,
                ));
              } else if (part is AdkFunctionResponsePart) {
                 _logger.d('Function response: ${part.name}');
                categorizedEvents.add(FunctionResponseEvent(
                  sourceEvent: event,
                  functionName: part.name,
                  response: part.response,
                ));
              } else if (part is AdkTextPart) {
                  final text = part.text;
                  if (text.isNotEmpty) {
                    categorizedEvents.add(ChatMessageEvent(
                      sourceEvent: event,
                      text: text,
                      isPartial: false,
                    ));
                  }
              }
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
