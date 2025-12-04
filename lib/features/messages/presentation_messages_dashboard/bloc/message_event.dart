import 'package:equatable/equatable.dart';

sealed class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends MessageEvent {
  const LoadMessages(this.conversationIds);
  final Set<String> conversationIds;

  @override
  List<Object?> get props => [conversationIds];
}

class LoadMoreMessages extends MessageEvent {
  const LoadMoreMessages();
}

class RefreshMessages extends MessageEvent {
  const RefreshMessages();
}

// Internal event for reacting to conversation changes
class ConversationSelectedEvent extends MessageEvent {
  const ConversationSelectedEvent(this.conversationIds);
  final Set<String> conversationIds;

  @override
  List<Object?> get props => [conversationIds];
}

class LoadMessageDetail extends MessageEvent {
  const LoadMessageDetail(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}
