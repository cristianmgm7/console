import 'package:equatable/equatable.dart';

/// Search mode for conversation search
enum ConversationSearchMode {
  id, // Search by exact conversation ID
  name, // Search by conversation name (case-insensitive, partial match)
}

sealed class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
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
  const WorkspaceSelectedEvent(this.workspaceGuid);
  final String workspaceGuid;

  @override
  List<Object?> get props => [workspaceGuid];
}

/// Event to open the conversation search panel
class OpenConversationSearch extends ConversationEvent {
  const OpenConversationSearch();
}

/// Event to close the conversation search panel
class CloseConversationSearch extends ConversationEvent {
  const CloseConversationSearch();
}

/// Event to update search query
class UpdateSearchQuery extends ConversationEvent {
  const UpdateSearchQuery(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Event to toggle search mode between ID and Name
class ToggleSearchMode extends ConversationEvent {
  const ToggleSearchMode(this.searchMode);
  final ConversationSearchMode searchMode;

  @override
  List<Object?> get props => [searchMode];
}

/// Event to select a conversation from search results
class SelectConversationFromSearch extends ConversationEvent {
  const SelectConversationFromSearch(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Event to load recent conversations with pagination
class LoadRecentConversations extends ConversationEvent {
  const LoadRecentConversations({
    required this.workspaceId,
    this.beforeDate,
  });

  final String workspaceId;
  final String? beforeDate; // For pagination

  @override
  List<Object?> get props => [workspaceId, beforeDate];
}

/// Event to load more recent conversations (pagination)
class LoadMoreRecentConversations extends ConversationEvent {
  const LoadMoreRecentConversations();
}
