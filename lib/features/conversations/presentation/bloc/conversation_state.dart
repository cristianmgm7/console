import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
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
    this.hasMoreConversations = false,
    this.isLoadingMore = false,
    this.lastFetchedDate,
  });

  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;

  // Pagination-related fields
  final bool hasMoreConversations;
  final bool isLoadingMore;
  final String? lastFetchedDate;

  @override
  List<Object?> get props => [
        conversations,
        selectedConversationIds,
        conversationColorMap,
        hasMoreConversations,
        isLoadingMore,
        lastFetchedDate,
      ];

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    Map<String, int>? conversationColorMap,
    bool? hasMoreConversations,
    bool? isLoadingMore,
    String? lastFetchedDate,
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
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
