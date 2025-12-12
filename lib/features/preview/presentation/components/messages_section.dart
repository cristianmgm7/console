import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_message_item.dart';
import 'package:flutter/material.dart';

/// Component that displays the selected messages section
class MessagesSection extends StatelessWidget {
  const MessagesSection({
    required this.messages,
    required this.conversation,
    super.key,
  });

  final List<MessageUiModel> messages;
  final ConversationUiModel conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...messages.map((message) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PreviewMessageItem(
              message: message,
              participants: conversation.participants,
            ),
          );
        }),
      ],
    );
  }
}
