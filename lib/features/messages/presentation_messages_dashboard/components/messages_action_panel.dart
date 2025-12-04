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
      opacity: 0.2,
      width: 150,
      height: 180,
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
          const SizedBox(height: 16),

          // Download Dropdown
          SizedBox(
            width: 180,
            height: 40,
            child: AppDropdown<String>(
              value: null, // No default selection
              hint: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.download, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Download',
                    style: AppTextStyle.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              dropdownKey: const Key('download_dropdown'),
              items: [
                DropdownMenuItem<String>(
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
                DropdownMenuItem<String>(
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
                DropdownMenuItem<String>(
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
              onChanged: (String? value) {
                switch (value) {
                  case 'audio':
                    onDownloadAudio();
                  case 'transcript':
                    onDownloadTranscript();
                  case 'both':
                    onSummarize();
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),

          const SizedBox(height: 12),

          // AI Chat Button
          AppButton(
            onPressed: onAIChat,
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
