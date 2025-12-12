import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_gradients.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_date.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/audio_controls.dart';
import 'package:flutter/material.dart';

/// Component for displaying message text content
class MessageContent extends StatelessWidget {
  const MessageContent({
    required this.message,
    this.isOwner = false,
    super.key,
  });

  final MessageUiModel message;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    if (message.textModels.isEmpty) return const SizedBox.shrink();

    // Find the transcript text model
    final transcriptModel = message.textModels.firstWhere(
      (model) => model.type == 'transcript',
      orElse: () => message.textModels.first, // Fallback to first if no transcript found
    );

    return Container(
      decoration: BoxDecoration(
        gradient: isOwner ? AppGradients.ownerMessage : null,
        color: isOwner ? null : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
        spacing: 16,
        children: [
          Text(
            transcriptModel.text,
            style: isOwner
                ? AppTextStyle.bodyMediumBlack.copyWith(color: AppColors.onPrimary)
                : AppTextStyle.bodyMediumBlack,
            // Removed maxLines and overflow to show full text
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AudioControls(message: message, isOwner: isOwner),
                MessageDate(createdAt: message.createdAt, isOwner: isOwner),
              ],
              ),
          ],
        ),
      ),
    );
  }
}
