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
  });
  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;

  @override
  List<Object?> get props => [conversations, selectedConversationIds, conversationColorMap];

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    Map<String, int>? conversationColorMap,
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
    );
  }
}

class ConversationError extends ConversationState {
  const ConversationError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
