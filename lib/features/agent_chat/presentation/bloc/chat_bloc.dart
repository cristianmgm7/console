import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {

  ChatBloc(this._repository, this._logger) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageStreaming>(_onSendMessageStreaming);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }
  final AgentChatRepository _repository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await _repository.loadMessages(event.sessionId);

    result.fold(
      onSuccess: (messages) {
        emit(ChatLoaded(
          messages: messages,
          currentSessionId: event.sessionId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to load messages', error: failure);
        emit(ChatError(failure.failure.details ?? 'Failed to load messages'));
      },
    );
  }

  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {
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
    ));

    try {
      // Send with streaming
      final result = await _repository.sendMessageStreaming(
        sessionId: event.sessionId,
        content: event.content,
        context: event.context,
        onStatus: (status, subAgent) {
          // Update status in real-time
          final currentState = state;
          if (currentState is ChatLoaded) {
            emit(currentState.copyWith(
              statusMessage: status,
              statusSubAgent: subAgent,
            ));
          }
        },
        onMessageChunk: (chunk) {
          // Handle streaming text chunks if needed
          // For now, we'll wait for complete messages
        },
      );

      result.fold(
        onSuccess: (agentMessages) {
          // Update user message to sent
          final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
          final allMessages = [
            ...currentState.messages.where((m) => m.id != userMessage.id),
            updatedUserMessage,
            ...agentMessages,
          ];

          emit(ChatLoaded(
            messages: allMessages,
            currentSessionId: event.sessionId,
            isSending: false,
            statusMessage: null,
            statusSubAgent: null,
          ));
        },
        onFailure: (failure) {
          _logger.e('Failed to send streaming message', error: failure);

          // Update user message to error
          final errorMessage = userMessage.copyWith(status: MessageStatus.error);
          final updatedMessages = currentState.messages
              .map((m) => m.id == userMessage.id ? errorMessage : m)
              .toList();

          emit(ChatLoaded(
            messages: updatedMessages,
            currentSessionId: event.sessionId,
            isSending: false,
            statusMessage: null,
            statusSubAgent: null,
          ));
        },
      );
    } catch (e) {
      _logger.e('Error in streaming', error: e);

      // Update user message to error
      final errorMessage = userMessage.copyWith(status: MessageStatus.error);
      final updatedMessages = currentState.messages
          .map((m) => m.id == userMessage.id ? errorMessage : m)
          .toList();

      emit(ChatLoaded(
        messages: updatedMessages,
        currentSessionId: event.sessionId,
        isSending: false,
        statusMessage: null,
        statusSubAgent: null,
      ));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final agentMessage = AgentChatMessage(
      id: event.messageId,
      sessionId: currentState.currentSessionId,
      role: MessageRole.agent,
      content: event.content,
      timestamp: DateTime.now(),
      subAgentName: event.subAgentName,
      subAgentIcon: event.subAgentIcon,
    );

    emit(currentState.copyWith(
      messages: [...currentState.messages, agentMessage],
    ));
  }

  Future<void> _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatInitial());
  }
}
