import 'dart:async';

import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/get_chat_messages_from_events_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(
    this._getChatMessagesUseCase,
    this._logger,
  ) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageStreaming>(_onSendMessageStreaming);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  final GetChatMessagesFromEventsUseCase _getChatMessagesUseCase;
  final Logger _logger;
  final Uuid _uuid = const Uuid();


  // Track streaming message accumulation
  String? _currentStreamingMessageId;
  final StringBuffer _streamingTextBuffer = StringBuffer();



  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    // TODO: Load message history from backend/local storage
    emit(ChatLoaded(
      messages: const [],
      currentSessionId: event.sessionId,
    ));
  }

  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {
    // If we're in initial state, transition to loaded state first
    if (state is ChatInitial) {
      emit(ChatLoaded(
        messages: const [],
        currentSessionId: event.sessionId,
      ));
    }

    final currentState = state;
    if (currentState is! ChatLoaded) return;

     // Create user message
    final userMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: event.sessionId,
      role: MessageRole.user,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add to UI immediately
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isSending: true,
      activeSessionId: event.sessionId,
    ));

    // Reset streaming state
    _currentStreamingMessageId = null;
    _streamingTextBuffer.clear();

    // Start use case stream using emit.forEach pattern
    try {
      final eventStream = _getChatMessagesUseCase(
        sessionId: event.sessionId,
        message: event.content,
        context: event.context,
      );

      // Process each event using emit.forEach (no manual subscription!)
      await emit.forEach<CategorizedEvent>(
        eventStream,
        onData: (categorizedEvent) {
          // Handle each categorized event
          if (categorizedEvent is ChatMessageEvent) {
            return _handleChatMessage(categorizedEvent, currentState);
          } else if (categorizedEvent is FunctionCallEvent) {
            return _handleFunctionCall(categorizedEvent, currentState);
          } else if (categorizedEvent is FunctionResponseEvent) {
            return _handleFunctionResponse(categorizedEvent, currentState);
          } else if (categorizedEvent is AgentErrorEvent) {
            return _handleError(categorizedEvent, currentState);
          }
          return currentState; // Unknown event type
        },
        onError: (error, stackTrace) {
          _logger.e('Error in event stream', error: error, stackTrace: stackTrace);

          // Create error message
          final errorMessage = AgentChatMessage(
            id: _uuid.v4(),
            sessionId: event.sessionId,
            role: MessageRole.agent,
            content: '⚠️ Error: $error',
            timestamp: DateTime.now(),
            status: MessageStatus.error,
          );

          return ChatLoaded(
            messages: [...currentState.messages, errorMessage],
            currentSessionId: event.sessionId,
            isSending: false,
          );
        },
      );

      // Stream completed - mark user message as sent
      final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
      final updatedMessages = currentState.messages
          .map((m) => m.id == userMessage.id ? updatedUserMessage : m)
          .toList();

      emit(ChatLoaded(
        messages: updatedMessages,
        currentSessionId: event.sessionId,
        isSending: false,
      ));
    } catch (e) {
      _logger.e('Error starting session', error: e);

      // Check if this is a stale session error that might resolve on retry
      final errorMessage = e.toString();
      if (errorMessage.contains('stale session') || errorMessage.contains('last_update_time')) {
        _logger.w('Detected stale session error, the session may need refreshing');

        // Update user message to indicate the error but don't mark as permanent failure
        final retryMessage = userMessage.copyWith(
          status: MessageStatus.error,
          content: '${userMessage.content}\n\n⚠️ Session synchronization issue. Please try again.',
        );
        final updatedMessages = currentState.messages
            .map((m) => m.id == userMessage.id ? retryMessage : m)
            .toList();

        emit(ChatLoaded(
          messages: updatedMessages,
          currentSessionId: event.sessionId,
          isSending: false,
        ));
      } else {
        // For other errors, mark as permanent failure
        final errorMessageObj = userMessage.copyWith(status: MessageStatus.error);
        final updatedMessages = currentState.messages
            .map((m) => m.id == userMessage.id ? errorMessageObj : m)
            .toList();

        emit(ChatLoaded(
          messages: updatedMessages,
          currentSessionId: event.sessionId,
          isSending: false,
        ));
      }
    }
  }

  /// Handle chat message events (returns new state)
  ChatState _handleChatMessage(ChatMessageEvent event, ChatLoaded currentState) {

    // Only process if this is for the active session
    if (currentState.activeSessionId != currentState.currentSessionId) return currentState;

    if (event.isPartial) {
      // Accumulate partial text
      _streamingTextBuffer.write(event.text);

      // Create or update streaming message
      if (_currentStreamingMessageId == null) {
        _currentStreamingMessageId = _uuid.v4();

        final streamingMessage = AgentChatMessage(
          id: _currentStreamingMessageId!,
          sessionId: currentState.currentSessionId,
          role: MessageRole.agent,
          content: _streamingTextBuffer.toString(),
          timestamp: event.sourceEvent.timestamp,
          subAgentName: _extractSubAgentName(event.sourceEvent.author),
          subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
          metadata: {
            'invocationId': event.sourceEvent.invocationId,
            'author': event.sourceEvent.author,
          },
        );

        return currentState.copyWith(
          messages: [...currentState.messages, streamingMessage],
          clearStatus: true,
        );
      } else {
        // Update existing streaming message
        final updatedMessages = currentState.messages.map((m) {
          if (m.id == _currentStreamingMessageId) {
            return m.copyWith(content: _streamingTextBuffer.toString());
          }
          return m;
        }).toList();

        return currentState.copyWith(messages: updatedMessages);
      }
    } else {
      // Complete message
      if (_currentStreamingMessageId != null) {
        // Update final version of streaming message
        final updatedMessages = currentState.messages.map((m) {
          if (m.id == _currentStreamingMessageId) {
            return m.copyWith(content: event.text);
          }
          return m;
        }).toList();

        // Reset streaming state
        _currentStreamingMessageId = null;
        _streamingTextBuffer.clear();

        return currentState.copyWith(
          messages: updatedMessages,
          clearStatus: true,
        );
      } else {
        // Single complete message (non-streaming)
        final agentMessage = AgentChatMessage(
          id: event.sourceEvent.id,
          sessionId: currentState.currentSessionId,
          role: MessageRole.agent,
          content: event.text,
          timestamp: event.sourceEvent.timestamp,
          subAgentName: _extractSubAgentName(event.sourceEvent.author),
          subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
          metadata: {
            'invocationId': event.sourceEvent.invocationId,
            'author': event.sourceEvent.author,
          },
        );

        return currentState.copyWith(
          messages: [...currentState.messages, agentMessage],
          clearStatus: true,
        );
      }
    }
  }

  /// Handle function call events (for "thinking..." indicators)
  ChatState _handleFunctionCall(FunctionCallEvent event, ChatLoaded currentState) {
    // Show "thinking..." status indicator
    final statusMessage = 'Calling ${event.functionName}...';
    final subAgent = _extractSubAgentName(event.sourceEvent.author);

    return currentState.copyWith(
      statusMessage: statusMessage,
      statusSubAgent: subAgent,
    );
  }

  /// Handle function response events (to clear "thinking..." indicator)
  ChatState _handleFunctionResponse(FunctionResponseEvent event, ChatLoaded currentState) {
    // Clear status indicator when function completes
    return currentState.copyWith(clearStatus: true);
  }

  /// Handle error events
  ChatState _handleError(AgentErrorEvent event, ChatLoaded currentState) {
    _logger.e('Agent error: ${event.errorMessage}');

    // Show error message in chat
    final errorMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: currentState.currentSessionId,
      role: MessageRole.agent,
      content: '⚠️ Error: ${event.errorMessage}',
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );

    return currentState.copyWith(
      messages: [...currentState.messages, errorMessage],
      isSending: false,
      clearStatus: true,
    );
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    // This event is now deprecated - messages come through coordinator
    _logger.w('MessageReceived event is deprecated, use coordinator instead');
  }

  Future<void> _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) async {
    _currentStreamingMessageId = null;
    _streamingTextBuffer.clear();
    emit(const ChatInitial());
  }

  /// Extract sub-agent name from author field
  String? _extractSubAgentName(String author) {
    if (author.contains('github')) {
      return 'GitHub Agent';
    } else if (author.contains('carbon')) {
      return 'Carbon Voice Agent';
    } else if (author.contains('market') || author.contains('analyzer')) {
      return 'Market Analyzer';
    }
    return null;
  }

  /// Extract sub-agent icon from author field
  String? _extractSubAgentIcon(String author) {
    if (author.contains('github')) {
      return 'github';
    } else if (author.contains('carbon')) {
      return 'chat';
    } else if (author.contains('market') || author.contains('analyzer')) {
      return 'chart_line';
    }
    return null;
  }
}
