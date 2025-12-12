import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_message_item.dart';
import 'package:flutter/material.dart';

/// Component that displays the selected messages section
class MessagesSection extends StatelessWidget {
  const MessagesSection({
    required this.messages,
    super.key,
  });

  final List<MessageUiModel> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Messages',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...messages.map((message) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PreviewMessageItem(message: message),
          );
        }),
      ],
    );
  }
}
