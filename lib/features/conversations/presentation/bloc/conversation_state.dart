import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:equatable/equatable.dart';

sealed class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationLoaded extends ConversationState {
  const ConversationLoaded({
    required this.conversations,
    required this.selectedConversationIds,
    required this.conversationColorMap,
    this.isSearchOpen = false,
    this.searchQuery = '',
    this.searchMode = ConversationSearchMode.name,
    this.hasMoreConversations = false,  // NEW: Track if more conversations exist
    this.isLoadingMore = false,         // NEW: Track pagination loading state
    this.lastFetchedDate,                // NEW: Track last pagination cursor
  });
  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;

  // Search-related fields
  final bool isSearchOpen;
  final String searchQuery;
  final ConversationSearchMode searchMode;

  // Pagination-related fields
  final bool hasMoreConversations;     // NEW
  final bool isLoadingMore;            // NEW
  final String? lastFetchedDate;       // NEW

  /// Filtered conversations based on search query and mode
  List<Conversation> get filteredConversations {
    if (!isSearchOpen || searchQuery.isEmpty) {
      return conversations;
    }

    switch (searchMode) {
      case ConversationSearchMode.id:
        return conversations.where((c) => c.channelGuid == searchQuery).toList();
      case ConversationSearchMode.name:
        final lowerQuery = searchQuery.toLowerCase();
        return conversations.where((c) => (c.channelName ?? '').toLowerCase().contains(lowerQuery)).toList();
    }
  }

  @override
  List<Object?> get props => [
        conversations,
        selectedConversationIds,
        conversationColorMap,
        isSearchOpen,
        searchQuery,
        searchMode,
        hasMoreConversations,    // NEW
        isLoadingMore,           // NEW
        lastFetchedDate,         // NEW
      ];

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    Map<String, int>? conversationColorMap,
    bool? isSearchOpen,
    String? searchQuery,
    ConversationSearchMode? searchMode,
    bool? hasMoreConversations,     // NEW
    bool? isLoadingMore,            // NEW
    String? lastFetchedDate,        // NEW
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      searchQuery: searchQuery ?? this.searchQuery,
      searchMode: searchMode ?? this.searchMode,
      hasMoreConversations: hasMoreConversations ?? this.hasMoreConversations,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastFetchedDate: lastFetchedDate ?? this.lastFetchedDate,
    );
  }
}

class ConversationError extends ConversationState {
  const ConversationError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
