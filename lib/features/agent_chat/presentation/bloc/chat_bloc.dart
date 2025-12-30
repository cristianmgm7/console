import 'dart:async';

import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
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
  
  /// Callback to notify when authentication is required
  /// Set this from the UI layer to forward auth requests to McpAuthBloc
  void Function(String sessionId, List<AuthenticationRequest> requests)? onAuthenticationRequired;



 

  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {
    _logger.i('📤 Sending message for session: ${event.sessionId}');

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

    try {
      // Get all events at once (categorized + raw)
      final eventsResult = await _getChatMessagesUseCase(
        sessionId: event.sessionId,
        message: event.content,
        context: event.context,
      );

      await eventsResult.fold(
        onSuccess: (categorizedEvents) async {
          _logger.i('📥 Processing ${categorizedEvents.length} categorized events');
          
          // Check for authentication requests in the raw events
          final authRequests = <AuthenticationRequest>[];
          for (final categorizedEvent in categorizedEvents) {
            if (categorizedEvent is AuthenticationRequestEvent) {
              authRequests.add(categorizedEvent.request);
              _logger.i('🔐 ChatBloc detected auth request for: ${categorizedEvent.request.provider}');
            }
          }
          
          // Forward auth requests to McpAuthBloc via callback
          if (authRequests.isNotEmpty && onAuthenticationRequired != null) {
            _logger.i('🔐 ChatBloc forwarding ${authRequests.length} auth requests');
            onAuthenticationRequired!(event.sessionId, authRequests);
          }

          var latestState = state as ChatLoaded;

          // Process each event
          for (final categorizedEvent in categorizedEvents) {
            ChatState newState;
            if (categorizedEvent is ChatMessageEvent) {
              newState = _handleChatMessage(categorizedEvent, latestState);
            } else if (categorizedEvent is FunctionCallEvent) {
              newState = _handleFunctionCall(categorizedEvent, latestState);
            } else if (categorizedEvent is FunctionResponseEvent) {
              newState = _handleFunctionResponse(categorizedEvent, latestState);
            } else if (categorizedEvent is AgentErrorEvent) {
              newState = _handleError(categorizedEvent, latestState);
            } else {
              continue; // Skip unknown event types
            }
            
            // Update latestState and emit
            if (newState is ChatLoaded) {
              latestState = newState;
              emit(latestState);
            }
          }

          // Mark user message as sent
          final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
          final updatedMessages = latestState.messages
              .map((m) => m.id == userMessage.id ? updatedUserMessage : m)
              .toList();

          emit(latestState.copyWith(
            messages: updatedMessages,
            isSending: false,
          ));

          _logger.i('✅ Message processing completed successfully');
        },
        onFailure: (failure) async {
          _logger.e('❌ Failed to send message', error: failure);

          // Mark user message as error
          final errorUserMessage = userMessage.copyWith(status: MessageStatus.error);
          final updatedMessages = (state as ChatLoaded).messages
              .map((m) => m.id == userMessage.id ? errorUserMessage : m)
              .toList();

          emit((state as ChatLoaded).copyWith(
            messages: updatedMessages,
            isSending: false,
          ));
        },
      );
    } on Exception catch (e, stackTrace) {
      _logger.e('❌ Error sending message', error: e, stackTrace: stackTrace);

      // Mark user message as error
      final errorUserMessage = userMessage.copyWith(status: MessageStatus.error);
      final updatedMessages = (state as ChatLoaded).messages
          .map((m) => m.id == userMessage.id ? errorUserMessage : m)
          .toList();

      emit((state as ChatLoaded).copyWith(
        messages: updatedMessages,
        isSending: false,
      ));
    }
  }

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

  /// Handle chat message events (returns new state)
  ChatState _handleChatMessage(ChatMessageEvent event, ChatLoaded currentState) {
    // With /run endpoint, all messages are complete (no partial streaming)
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
