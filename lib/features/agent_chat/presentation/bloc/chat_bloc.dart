import 'dart:async';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
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
  }

  final GetChatMessagesFromEventsUseCase _getChatMessagesUseCase;
  final Logger _logger;
  final Uuid _uuid = const Uuid();
  
  /// Callback for debug event logging (visualize streaming in real-time)
  void Function(String event)? onDebugEvent;


  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {

    // onEach will automatically handle stream lifecycle

    // If we're in initial state, transition to loaded state first
    if (state is ChatInitial) {
      emit(ChatLoaded(
        items: const [],
        currentSessionId: event.sessionId,
      ));
    }

    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Create user message item
    final userId = _uuid.v4();
    final userMessageItem = TextMessageItem(
      id: userId,
      timestamp: DateTime.now(),
      text: event.content,
      role: MessageRole.user,
    );

    // Add to UI immediately
    emit(currentState.copyWith(
      items: [...currentState.items, userMessageItem],
      isSending: true,
    ));
    onDebugEvent?.call('🌊 Stream started');

    // Get categorized event stream from use case
    final eventStream = _getChatMessagesUseCase.call(
      sessionId: event.sessionId,
      message: event.content,
      context: event.context,
      streaming: true, // Message-level streaming (not token-level)
    );

    // Track active status items
    final activeStatusIds = <String, String>{}; // functionName -> itemId

    // Use emit.onEach to automatically handle stream subscription lifecycle
    await emit.onEach<CategorizedEvent>(
      eventStream,
      onData: (CategorizedEvent categorizedEvent) {
        onDebugEvent?.call('📥 Event: ${categorizedEvent.runtimeType}');

        final latestState = state;
        if (latestState is! ChatLoaded) return;

        // Handle different event types using dedicated handlers
        // Handle different event types using dedicated handlers
        if (categorizedEvent is AuthenticationRequestEvent) {
          _handleAuthenticationRequest(categorizedEvent, latestState, emit);
        } else if (categorizedEvent is ChatMessageEvent) {
          _handleChatMessage(categorizedEvent, latestState, emit);
        } else if (categorizedEvent is FunctionCallEvent) {
          _handleFunctionCall(categorizedEvent, latestState, activeStatusIds, emit);
        } else if (categorizedEvent is FunctionResponseEvent) {
          _handleFunctionResponse(categorizedEvent, latestState, activeStatusIds, emit);
        } else if (categorizedEvent is AgentErrorEvent) {
          _handleAgentError(categorizedEvent, latestState, emit);
        } else if (categorizedEvent is StateUpdateEvent) {
          _handleStateUpdate(categorizedEvent, latestState, emit);
        } else if (categorizedEvent is ArtifactUpdateEvent) {
          _handleArtifactUpdate(categorizedEvent, latestState, emit);
        } else if (categorizedEvent is ToolConfirmationEvent) {
          _handleToolConfirmation(categorizedEvent, latestState, emit);
        }
      },
        onError: (Object error, StackTrace? stackTrace) {
          _logger.e('❌ Error in stream', error: error, stackTrace: stackTrace);
          // Add error status item
          final latestState = state;
          if (latestState is ChatLoaded) {
            final errorItem = SystemStatusItem(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              status: 'Failed to send message: $error',
              type: StatusType.error,
            );

            emit(latestState.copyWith(
              items: [...latestState.items, errorItem],
              isSending: false,
            ));
          }
        },
      );

      // Stream completed
      onDebugEvent?.call('✅ Stream completed');

    // Mark sending as complete
    final latestState = state;
    if (latestState is ChatLoaded) {
      emit(latestState.copyWith(isSending: false));
    }
  }

   Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    // TODO: Load message history from backend/local storage
    emit(ChatLoaded(
      items: const [],
      currentSessionId: event.sessionId,
    ));
  }

  @override
  Future<void> close() {
    // onEach automatically handles stream cleanup
    return super.close();
  }

  void _handleStateUpdate(
    StateUpdateEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    _logger.d('🧠 State update received');
    // Merge new state with existing state
    final newState = Map<String, dynamic>.from(state.agentState);
    newState.addAll(event.stateDelta);
    emit(state.copyWith(agentState: newState));
  }

  void _handleArtifactUpdate(
    ArtifactUpdateEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    _logger.d('📂 Artifact update received');
    // Merge new artifacts with existing artifacts
    final newArtifacts = Map<String, dynamic>.from(state.artifacts);
    newArtifacts.addAll(event.artifactDelta);
    emit(state.copyWith(artifacts: newArtifacts));
  }

  void _handleToolConfirmation(
    ToolConfirmationEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    _logger.d('✋ Tool confirmation requested: ${event.functionName}');
    
    final confirmationItem = ToolConfirmationItem(
      id: event.sourceEvent.id,
      timestamp: event.sourceEvent.timestamp,
      toolCallId: event.toolCallId,
      functionName: event.functionName,
      args: event.args,
      subAgentName: _extractSubAgentName(event.sourceEvent.author),
      subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
    );

    emit(state.copyWith(items: [...state.items, confirmationItem]));
  }

  void _handleAuthenticationRequest(
    AuthenticationRequestEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    _logger.i('🔐 ChatBloc detected auth request for: ${event.request.provider}');
    onDebugEvent?.call('🔐 Auth request: ${event.request.provider}');

    final authItem = AuthRequestItem(
      id: event.sourceEvent.id,
      timestamp: event.sourceEvent.timestamp,
      request: event.request,
      subAgentName: _extractSubAgentName(event.sourceEvent.author),
      subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
    );

    emit(state.copyWith(items: [...state.items, authItem]));
  }

  void _handleChatMessage(
    ChatMessageEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    final preview = event.text.length > 30
        ? '${event.text.substring(0, 30)}...'
        : event.text;
    onDebugEvent?.call('💬 Chat message: $preview');

    // Use invocationId as the message ID to group streaming chunks
    final messageId = event.sourceEvent.invocationId;

    // Check if there's already a partial message for this invocation
    final existingMessageIndex = state.items.indexWhere(
      (item) => item is TextMessageItem &&
               item.id == messageId &&
               item.isPartial &&
               item.role == MessageRole.agent,
    );

    if (existingMessageIndex != -1) {
      // Update existing partial message with the new cumulative text
      final existingMessage = state.items[existingMessageIndex] as TextMessageItem;
      final updatedMessage = existingMessage.copyWith(
        text: event.text,
        isPartial: event.isPartial,
        hasA2Ui: event.hasA2Ui, // Update A2UI status if changed
        timestamp: event.sourceEvent.timestamp,
      );

      final updatedItems = List<ChatItem>.from(state.items);
      updatedItems[existingMessageIndex] = updatedMessage;

      emit(state.copyWith(items: updatedItems));
    } else {
      // Create new message item
      final messageItem = TextMessageItem(
        id: messageId,
        timestamp: event.sourceEvent.timestamp,
        text: event.text,
        role: MessageRole.agent,
        isPartial: event.isPartial,
        hasA2Ui: event.hasA2Ui,
        subAgentName: _extractSubAgentName(event.sourceEvent.author),
        subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
      );

      emit(state.copyWith(items: [...state.items, messageItem]));
    }
  }

  void _handleFunctionCall(
    FunctionCallEvent event,
    ChatLoaded state,
    Map<String, String> activeStatusIds,
    Emitter<ChatState> emit,
  ) {
    onDebugEvent?.call('⚙️ Function call: ${event.functionName}');

    final statusId = 'status_${event.functionName}';
    activeStatusIds[event.functionName] = statusId;

    final statusItem = SystemStatusItem(
      id: statusId,
      timestamp: event.sourceEvent.timestamp,
      status: 'Calling ${event.functionName}...',
      type: StatusType.toolCall,
      subAgentName: _extractSubAgentName(event.sourceEvent.author),
      subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
      metadata: {'functionName': event.functionName},
    );

    emit(state.copyWith(items: [...state.items, statusItem]));
  }

  void _handleFunctionResponse(
    FunctionResponseEvent event,
    ChatLoaded state,
    Map<String, String> activeStatusIds,
    Emitter<ChatState> emit,
  ) {
    onDebugEvent?.call('✅ Function completed: ${event.functionName}');

    final statusId = activeStatusIds[event.functionName];
    if (statusId != null) {
      final updatedItems = state.items
          .where((item) => item.id != statusId)
          .toList();

      emit(state.copyWith(items: updatedItems));
      activeStatusIds.remove(event.functionName);
    }
  }

  void _handleAgentError(
    AgentErrorEvent event,
    ChatLoaded state,
    Emitter<ChatState> emit,
  ) {
    onDebugEvent?.call('❌ Error: ${event.errorMessage}');

    final errorItem = SystemStatusItem(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      status: event.errorMessage,
      type: StatusType.error,
    );

    emit(state.copyWith(items: [...state.items, errorItem]));
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
