import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_content.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_header.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/reply_indicator.dart';
import 'package:flutter/material.dart';

/// Chat-style message item with left/right alignment and different styling for conversation owner
class ChatMessageItem extends StatelessWidget {
  const ChatMessageItem({
    required this.message,
    required this.participants,
    required this.parentMessages,
    required this.isOwner,
    super.key,
  });

  final MessageUiModel message;
  final List<ConversationParticipantUiModel> participants;
  final List<MessageUiModel> parentMessages;
  final bool isOwner;

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

    // Determine alignment based on whether this is the owner
    final isRightAligned = isOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit width to 75% of screen
              ),
              child: Column(
                crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Reply indicator if this message is a reply
                  if (parentMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ReplyIndicator(
                        parentMessageText: parentMessage.text ?? parentMessage.notes,
                        isDarkTheme: isOwner,
                      ),
                    ),

                  // Header with avatar and name for all messages
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: MessageHeader(
                      participants: participants,
                      creatorId: message.creatorId,
                    ),
                  ),

                  // Message content with owner styling
                  MessageContent(
                    message: message,
                    isOwner: isOwner,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
