import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_shadows.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';

class MessagesActionPanel extends StatelessWidget {

  const MessagesActionPanel({
    required this.selectedCount,
    required this.onDownloadAudio,
    required this.onDownloadTranscript,
    required this.onSummarize,
    required this.onAIChat,
    super.key,
  });
  final int selectedCount;
  final VoidCallback onDownloadAudio;
  final VoidCallback onDownloadTranscript;
  final VoidCallback onSummarize;
  final VoidCallback onAIChat;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      opacity: 0.8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.checkCircle,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount items selected',
            style: AppTextStyle.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 24),

          // Download Audio Button
          AppOutlinedButton(
            onPressed: onDownloadAudio,
            size: AppOutlinedButtonSize.medium,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.audioTrack, size: 18),
                const SizedBox(width: 8),
                const Text('Download Audio'),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Download Transcript Button
          AppOutlinedButton(
            onPressed: onDownloadTranscript,
            size: AppOutlinedButtonSize.medium,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.message, size: 18),
                const SizedBox(width: 8),
                const Text('Download Transcript'),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Download Both Button
          AppOutlinedButton(
            onPressed: onSummarize,
            size: AppOutlinedButtonSize.medium,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.download, size: 18),
                const SizedBox(width: 8),
                const Text('Both'),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // AI Chat Button
          AppButton(
            onPressed: onAIChat,
            size: AppButtonSize.medium,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.sparkles, size: 18),
                const SizedBox(width: 8),
                const Text('AI Chat'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
