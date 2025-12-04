import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class MessagesActionPanel extends StatelessWidget {
  const MessagesActionPanel({
    required this.selectedCount,
    required this.onDownloadAudio,
    required this.onDownloadTranscript,
    required this.onSummarize,
    required this.onAIChat,
    required this.onCancel,
    super.key,
  });
  final int selectedCount;
  final VoidCallback onDownloadAudio;
  final VoidCallback onDownloadTranscript;
  final VoidCallback onSummarize;
  final VoidCallback onAIChat;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      opacity: 0.2,
      width: 150,
      height: 170,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.checkCircle,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$selectedCount',
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Download Menu Button
            PopupMenuButton<String>(
              key: const Key('download_dropdown'),
              onSelected: (String value) {
                switch (value) {
                  case 'audio':
                    onDownloadAudio();
                  case 'transcript':
                    onDownloadTranscript();
                  case 'both':
                    onSummarize();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'audio',
                  child: Row(
                    children: [
                      Icon(AppIcons.audioTrack, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Audio',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'transcript',
                  child: Row(
                    children: [
                      Icon(AppIcons.message, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Transcript',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'both',
                  child: Row(
                    children: [
                      Icon(AppIcons.download, size: 18, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Both',
                        style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 90,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AppIcons.download, size: 18, color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 8),
            // Cancel Button
            AppButton(
              onPressed: onCancel,
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.close, size: 18),
                  const SizedBox(width: 8),
                  const Text('Cancel'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
