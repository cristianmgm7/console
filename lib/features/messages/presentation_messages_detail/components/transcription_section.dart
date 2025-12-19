import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/widgets/copy_transcription_button.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/widgets/transcription_play_button.dart';
import 'package:flutter/material.dart';

class TranscriptionSection extends StatelessWidget {
  const TranscriptionSection({
    required this.message,
    super.key,
  });

  final MessageUiModel message;

  @override
  Widget build(BuildContext context) {
    final transcription = message.transcriptText?.trim() ?? '';
    final hasTranscription = transcription.isNotEmpty;
    final hasPlayableAudio = message.hasPlayableAudio;

    if (!hasTranscription && !hasPlayableAudio) {
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
        child: Center(
          child: Text(
            'No transcription or audio available',
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
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
          // Header with title and actions
          Row(
            children: [
              Text(
                'Transcription',
                style: AppTextStyle.bodyMedium,
              ),
              const Spacer(),
              if (hasTranscription) ...[
                CopyTranscriptionButton(transcription: transcription),
                const SizedBox(width: 8),
              ],
              if (hasPlayableAudio && message.playableAudioModel != null) ...[
                TranscriptionPlayButton(
                  messageId: message.id,
                  audioModel: message.playableAudioModel!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Transcription content
          if (hasTranscription) ...[
            Text(
              transcription,
              style: AppTextStyle.bodyMediumBlack,
            ),
          ] else ...[
            Text(
              'Audio transcription not available',
              style: AppTextStyle.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
