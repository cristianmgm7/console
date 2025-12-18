import 'package:equatable/equatable.dart';

/// Search mode for conversation search
enum ConversationSearchMode {
  id, // Search by exact conversation ID
  name, // Search by conversation name (case-insensitive, partial match)
}

sealed class ConversationSearchEvent extends Equatable {
  const ConversationSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Event to open the conversation search panel
class OpenConversationSearch extends ConversationSearchEvent {
  const OpenConversationSearch();
}

/// Event to close the conversation search panel
class CloseConversationSearch extends ConversationSearchEvent {
  const CloseConversationSearch();
}

/// Event to update search query
class UpdateSearchQuery extends ConversationSearchEvent {
  const UpdateSearchQuery(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Event to toggle search mode between ID and Name
class ToggleSearchMode extends ConversationSearchEvent {
  const ToggleSearchMode(this.searchMode);
  final ConversationSearchMode searchMode;

  @override
  List<Object?> get props => [searchMode];
}

/// Event to search for a conversation by ID (calls API)
class SearchConversationById extends ConversationSearchEvent {
  const SearchConversationById(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}
