import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/audio_controls.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_date.dart';
import 'package:flutter/material.dart';

/// Component for displaying message text content
class MessageContent extends StatelessWidget {
  const MessageContent({
    required this.text,
    required this.message,
    super.key,
  });

  final String? text;
  final MessageUiModel message;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();

    return Card(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          Text(
            text!,
            style: AppTextStyle.bodyMedium,
            // Removed maxLines and overflow to show full text
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AudioControls(message: message),
                MessageDate(createdAt: message.createdAt),
              ],
            ),
        ],
      ),
    );
  }
}
