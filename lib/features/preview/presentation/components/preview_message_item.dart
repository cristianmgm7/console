import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_content.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_header.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/reply_indicator.dart';
import 'package:flutter/material.dart';

/// Displays a single message in the preview visualization
class PreviewMessageItem extends StatelessWidget {
  const PreviewMessageItem({
    required this.message,
    required this.participants,
    required this.parentMessages,
    super.key,
  });

  final MessageUiModel message;
  final List<ConversationParticipantUiModel> participants;
  final List<MessageUiModel> parentMessages;

  @override
  Widget build(BuildContext context) {
    // Find parent message if this is a reply
    MessageUiModel? parentMessage;
    if (message.parentMessageId != null) {
      try {
        parentMessage = parentMessages.firstWhere(
          (parent) => parent.id == message.parentMessageId,
        );
      } on Exception {
        parentMessage = null;
      }
    }

    return Card(
      shadowColor: AppColors.transparent,
      borderOnForeground: false,
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply indicator if this message is a reply
            if (parentMessage != null)
              ReplyIndicator(
                parentMessageText: parentMessage.text ?? parentMessage.notes,
              ),

            // Header with avatar and name
            MessageHeader(
              participants: participants,
              creatorId: message.creatorId,
            ), // Spacing between header and content
            // Message content below header
            MessageContent(message: message),
          ],
        ),
      ),
    );
  }
}
