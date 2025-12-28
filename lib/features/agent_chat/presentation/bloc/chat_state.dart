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
  final String? statusMessage;
  final String? statusSubAgent;

  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
    this.statusMessage,
    this.statusSubAgent,
  });

  @override
  List<Object?> get props => [
        messages,
        currentSessionId,
        isSending,
        statusMessage,
        statusSubAgent,
      ];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
    String? statusMessage,
    String? statusSubAgent,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
      statusMessage: statusMessage ?? this.statusMessage,
      statusSubAgent: statusSubAgent ?? this.statusSubAgent,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
