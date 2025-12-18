import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_event.dart';
import 'package:equatable/equatable.dart';

sealed class ConversationSearchState extends Equatable {
  const ConversationSearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state - search panel closed
class ConversationSearchClosed extends ConversationSearchState {
  const ConversationSearchClosed();
}

/// Search panel is open and ready for input
class ConversationSearchOpen extends ConversationSearchState {
  const ConversationSearchOpen({
    this.searchQuery = '',
    this.searchMode = ConversationSearchMode.name,
    this.filteredConversations = const [],
    this.isSearching = false,
  });

  final String searchQuery;
  final ConversationSearchMode searchMode;
  final List<Conversation> filteredConversations;
  final bool isSearching;

  @override
  List<Object?> get props => [
        searchQuery,
        searchMode,
        filteredConversations,
        isSearching,
      ];

  ConversationSearchOpen copyWith({
    String? searchQuery,
    ConversationSearchMode? searchMode,
    List<Conversation>? filteredConversations,
    bool? isSearching,
  }) {
    return ConversationSearchOpen(
      searchQuery: searchQuery ?? this.searchQuery,
      searchMode: searchMode ?? this.searchMode,
      filteredConversations: filteredConversations ?? this.filteredConversations,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Search completed with results
class ConversationSearchResults extends ConversationSearchState {
  const ConversationSearchResults({
    required this.searchQuery,
    required this.searchMode,
    required this.results,
  });

  final String searchQuery;
  final ConversationSearchMode searchMode;
  final List<Conversation> results;

  @override
  List<Object?> get props => [searchQuery, searchMode, results];
}

/// Error occurred during search
class ConversationSearchError extends ConversationSearchState {
  const ConversationSearchError({
    required this.message,
    required this.searchQuery,
    required this.searchMode,
  });

  final String message;
  final String searchQuery;
  final ConversationSearchMode searchMode;

  @override
  List<Object?> get props => [message, searchQuery, searchMode];
}
