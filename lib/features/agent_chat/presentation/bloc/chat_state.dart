import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:equatable/equatable.dart';

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
    required this.items,
    required this.currentSessionId,
    this.isSending = false,
    this.activeStatus,
    this.agentState = const {},
    this.artifacts = const {},
  });

  /// Polymorphic list of chat items (messages, auth requests, status indicators)
  final List<ChatItem> items;
  
  /// The current session ID
  final String currentSessionId;
  
  /// Whether a message is currently being sent
  final bool isSending;
  
  /// Optional global status bar message (e.g., "Connecting...", "Agent thinking...")
  final String? activeStatus;

  /// Current agent state (key-value pairs)
  final Map<String, dynamic> agentState;

  /// Current artifacts (key-value pairs of file paths/content)
  final Map<String, dynamic> artifacts;

  @override
  List<Object?> get props => [
        items,
        currentSessionId,
        isSending,
        activeStatus,
        agentState,
        artifacts,
      ];

  ChatLoaded copyWith({
    List<ChatItem>? items,
    String? currentSessionId,
    bool? isSending,
    String? activeStatus,
    bool clearStatus = false,
    Map<String, dynamic>? agentState,
    Map<String, dynamic>? artifacts,
  }) {
    return ChatLoaded(
      items: items ?? this.items,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
      activeStatus: clearStatus ? null : (activeStatus ?? this.activeStatus),
      agentState: agentState ?? this.agentState,
      artifacts: artifacts ?? this.artifacts,
    );
  }
}

class ChatError extends ChatState {

  const ChatError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
