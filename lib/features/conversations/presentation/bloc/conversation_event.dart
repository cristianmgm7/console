import 'package:equatable/equatable.dart';

sealed class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationEvent {
  const LoadConversations(this.workspaceId);
  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}

class ToggleConversation extends ConversationEvent {
  const ToggleConversation(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class SelectMultipleConversations extends ConversationEvent {
  const SelectMultipleConversations(this.conversationIds);
  final Set<String> conversationIds;

  @override
  List<Object?> get props => [conversationIds];
}

class ClearConversationSelection extends ConversationEvent {
  const ClearConversationSelection();
}

// Internal event for reacting to workspace changes
class WorkspaceSelectedEvent extends ConversationEvent {
  const WorkspaceSelectedEvent(this.workspaceId);
  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}

// Internal event emitted by bloc to notify other blocs
class ConversationSelectedEvent extends ConversationEvent {
  const ConversationSelectedEvent(this.conversationIds);
  final Set<String> conversationIds;

  @override
  List<Object?> get props => [conversationIds];
}
