import 'dart:async';

import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
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
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  final GetChatMessagesFromEventsUseCase _getChatMessagesUseCase;
  final Logger _logger;
  final Uuid _uuid = const Uuid();
  
  /// Callback to notify when authentication is required
  /// Set this from the UI layer to forward auth requests to McpAuthBloc
  void Function(String sessionId, List<AuthenticationRequest> requests)? onAuthenticationRequired;
  
  /// Callback for debug event logging (visualize streaming in real-time)
  void Function(String event)? onDebugEvent;



 

  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {
    _logger.i('📤 Sending message for session: ${event.sessionId}');

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

    try {
      _logger.i('🌊 Starting SSE stream for session: ${event.sessionId}');
      onDebugEvent?.call('🌊 Stream started');
      
      // Get categorized event stream from use case
      final eventStream = _getChatMessagesUseCase.call(
        sessionId: event.sessionId,
        message: event.content,
        context: event.context,
        streaming: false, // Message-level streaming (not token-level)
      );

      // Track auth requests and active status items
      final authRequests = <AuthenticationRequest>[];
      final activeStatusIds = <String, String>{}; // functionName -> itemId
      
      // Process events as they arrive
      await for (final categorizedEvent in eventStream) {
        _logger.d('📥 Processing categorized event: ${categorizedEvent.runtimeType}');
        onDebugEvent?.call('📥 Event: ${categorizedEvent.runtimeType}');
        
        var latestState = state;
        if (latestState is! ChatLoaded) break;

        // Handle different event types
        if (categorizedEvent is AuthenticationRequestEvent) {
          // Create auth request item
          authRequests.add(categorizedEvent.request);
          _logger.i('🔐 ChatBloc detected auth request for: ${categorizedEvent.request.provider}');
          onDebugEvent?.call('🔐 Auth request: ${categorizedEvent.request.provider}');
          
          final authItem = AuthRequestItem(
            id: categorizedEvent.sourceEvent.id,
            timestamp: categorizedEvent.sourceEvent.timestamp,
            request: categorizedEvent.request,
            subAgentName: _extractSubAgentName(categorizedEvent.sourceEvent.author),
            subAgentIcon: _extractSubAgentIcon(categorizedEvent.sourceEvent.author),
          );
          
          emit(latestState.copyWith(
            items: [...latestState.items, authItem],
          ));
        } else if (categorizedEvent is ChatMessageEvent) {
          // Create text message item
          final preview = categorizedEvent.text.length > 30 
              ? '${categorizedEvent.text.substring(0, 30)}...' 
              : categorizedEvent.text;
          onDebugEvent?.call('💬 Chat message: $preview');
          
          final messageItem = TextMessageItem(
            id: categorizedEvent.sourceEvent.id,
            timestamp: categorizedEvent.sourceEvent.timestamp,
            text: categorizedEvent.text,
            role: MessageRole.agent,
            isPartial: categorizedEvent.isPartial,
            subAgentName: _extractSubAgentName(categorizedEvent.sourceEvent.author),
            subAgentIcon: _extractSubAgentIcon(categorizedEvent.sourceEvent.author),
          );
          
          emit(latestState.copyWith(
            items: [...latestState.items, messageItem],
          ));
        } else if (categorizedEvent is FunctionCallEvent) {
          // Create/update system status item for "thinking..."
          onDebugEvent?.call('⚙️ Function call: ${categorizedEvent.functionName}');
          
          final statusId = 'status_${categorizedEvent.functionName}';
          activeStatusIds[categorizedEvent.functionName] = statusId;
          
          final statusItem = SystemStatusItem(
            id: statusId,
            timestamp: categorizedEvent.sourceEvent.timestamp,
            status: 'Calling ${categorizedEvent.functionName}...',
            type: StatusType.toolCall,
            subAgentName: _extractSubAgentName(categorizedEvent.sourceEvent.author),
            subAgentIcon: _extractSubAgentIcon(categorizedEvent.sourceEvent.author),
            metadata: {'functionName': categorizedEvent.functionName},
          );
          
          emit(latestState.copyWith(
            items: [...latestState.items, statusItem],
          ));
        } else if (categorizedEvent is FunctionResponseEvent) {
          // Remove the corresponding status item
          onDebugEvent?.call('✅ Function completed: ${categorizedEvent.functionName}');
          
          final statusId = activeStatusIds[categorizedEvent.functionName];
          if (statusId != null) {
            final updatedItems = latestState.items
                .where((item) => item.id != statusId)
                .toList();
            
            emit(latestState.copyWith(items: updatedItems));
            activeStatusIds.remove(categorizedEvent.functionName);
          }
        } else if (categorizedEvent is AgentErrorEvent) {
          // Create error status item
          onDebugEvent?.call('❌ Error: ${categorizedEvent.errorMessage}');
          
          final errorItem = SystemStatusItem(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            status: categorizedEvent.errorMessage,
            type: StatusType.error,
          );
          
          emit(latestState.copyWith(
            items: [...latestState.items, errorItem],
          ));
        }
      }
      
      onDebugEvent?.call('✅ Stream completed');

      // Stream completed - forward any auth requests
      if (authRequests.isNotEmpty && onAuthenticationRequired != null) {
        _logger.i('🔐 ChatBloc forwarding ${authRequests.length} auth requests');
        onAuthenticationRequired!(event.sessionId, authRequests);
      }

      // Mark sending as complete
      final latestState = state;
      if (latestState is ChatLoaded) {
        emit(latestState.copyWith(isSending: false));
      }

      _logger.i('✅ Message processing completed successfully');
    } on Exception catch (e, stackTrace) {
      _logger.e('❌ Error sending message', error: e, stackTrace: stackTrace);

      // Add error status item
      final latestState = state;
      if (latestState is ChatLoaded) {
        final errorItem = SystemStatusItem(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          status: 'Failed to send message: ${e.toString()}',
          type: StatusType.error,
        );

        emit(latestState.copyWith(
          items: [...latestState.items, errorItem],
          isSending: false,
        ));
      }
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
