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

  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
    this.statusMessage,
    this.statusSubAgent,
    this.activeSessionId, // NEW: Track which session is actively streaming
  });
  final List<AgentChatMessage> messages;
  final String currentSessionId;
  final bool isSending;
  final String? statusMessage;
  final String? statusSubAgent;
  final String? activeSessionId; // NEW

  @override
  List<Object?> get props => [
        messages,
        currentSessionId,
        isSending,
        statusMessage,
        statusSubAgent,
        activeSessionId, // NEW
      ];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
    String? statusMessage,
    String? statusSubAgent,
    String? activeSessionId,
    bool clearStatus = false, // NEW: Allow clearing status
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      statusSubAgent: clearStatus ? null : (statusSubAgent ?? this.statusSubAgent),
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}

class ChatError extends ChatState {

  const ChatError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
