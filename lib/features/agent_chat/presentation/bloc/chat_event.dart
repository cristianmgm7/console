import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String sessionId;

  const LoadMessages(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class SendMessage extends ChatEvent {
  final String sessionId;
  final String content;
  final Map<String, dynamic>? context;

  const SendMessage({
    required this.sessionId,
    required this.content,
    this.context,
  });

  @override
  List<Object?> get props => [sessionId, content, context];
}

class MessageReceived extends ChatEvent {
  final String messageId;
  final String content;
  final String? subAgentName;
  final String? subAgentIcon;

  const MessageReceived({
    required this.messageId,
    required this.content,
    this.subAgentName,
    this.subAgentIcon,
  });

  @override
  List<Object?> get props => [messageId, content, subAgentName, subAgentIcon];
}

class ClearMessages extends ChatEvent {
  const ClearMessages();
}
