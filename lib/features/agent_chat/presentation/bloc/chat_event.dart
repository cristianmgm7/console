import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {

  const LoadMessages(this.sessionId);
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class SendMessageStreaming extends ChatEvent {

  const SendMessageStreaming({
    required this.sessionId,
    required this.content,
    this.context,
  });
  final String sessionId;
  final String content;
  final Map<String, dynamic>? context;

  @override
  List<Object?> get props => [sessionId, content, context];
}

class MessageReceived extends ChatEvent {

  const MessageReceived({
    required this.messageId,
    required this.content,
    this.subAgentName,
    this.subAgentIcon,
  });
  final String messageId;
  final String content;
  final String? subAgentName;
  final String? subAgentIcon;

  @override
  List<Object?> get props => [messageId, content, subAgentName, subAgentIcon];
}
