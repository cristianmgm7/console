import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/chat_message_item.dart';
import 'package:flutter/material.dart';

/// Component that displays the selected messages section in chat style
class MessagesSection extends StatelessWidget {
  const MessagesSection({
    required this.messages,
    required this.conversation,
    required this.parentMessages,
    super.key,
  });

  final List<MessageUiModel> messages;
  final ConversationUiModel conversation;
  final List<MessageUiModel> parentMessages;

  /// Get the conversation owner ID (first participant with 'owner' permissions, or 'owner' role as fallback)
  String? get _conversationOwnerId {
    ConversationParticipantUiModel? ownerParticipant;
    try {
      // First try to find by permissions = owner
      ownerParticipant = conversation.participants.firstWhere(
        (participant) => participant.permissions?.toLowerCase() == 'owner',
      );
    } on Exception {
      try {
        // Fallback to role = owner
        ownerParticipant = conversation.participants.firstWhere(
          (participant) => participant.role?.toLowerCase() == 'owner',
        );
      } on Exception {
        // No owner found, use first participant if available
        ownerParticipant = conversation.participants.isNotEmpty
            ? conversation.participants.first
            : null;
      }
    }
    return ownerParticipant?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ...messages.map((message) {
            final isOwner = message.creatorId == _conversationOwnerId;
            return ChatMessageItem(
              message: message,
              participants: conversation.participants,
              parentMessages: parentMessages,
              isOwner: isOwner,
            );
          }),
        ],
      ),
    );
  }
}
