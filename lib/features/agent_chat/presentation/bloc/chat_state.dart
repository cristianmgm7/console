import 'package:equatable/equatable.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<AgentChatMessage> messages;
  final String currentSessionId;
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
  });

  @override
  List<Object?> get props => [messages, currentSessionId, isSending];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
