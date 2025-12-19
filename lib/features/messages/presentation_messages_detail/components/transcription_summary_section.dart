import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:flutter/material.dart';

class TranscriptionSummarySection extends StatelessWidget {
  const TranscriptionSummarySection({
    required this.message,
    super.key,
  });

  final MessageUiModel message;

  @override
  Widget build(BuildContext context) {
    // Use the notes field as the summary
    final summary = message.notes.trim();

    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppBorders.radiustiny)),
        border: Border.fromBorderSide(
          BorderSide(
            color: AppColors.divider,
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: AppTextStyle.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTextStyle.bodyMediumBlack,
          ),
        ],
      ),
    );
  }
}
