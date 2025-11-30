import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    required this.message,
    required this.isSelected,
    required this.onSelected,
    this.onViewDetail,
    super.key,
  });

  final MessageUiModel message;
  final bool isSelected;
  final ValueChanged<bool?> onSelected;
  final ValueChanged<String>? onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            AppCheckbox(
              value: isSelected,
              onChanged: onSelected,
            ),

            const SizedBox(width: 8),

            // Date
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(message.createdAt),
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Owner
            SizedBox(
              width: 140,
              child: Text(
                message.creator?.name ?? message.creatorId,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text ?? 'No content',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.text?.isNotEmpty ?? false) const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(width: 16),
            // Duration
            SizedBox(
              width: 60,
              child: Text(
                _formatDuration(message.duration),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 16),

            // Play button - only show if message has playable audio
            if (message.hasPlayableAudio) ...[
              AppIconButton(
                icon: AppIcons.play,
                tooltip: 'Play audio',
                onPressed: () => _handlePlayAudio(context, message),
                foregroundColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
            ],

            // Menu
            PopupMenuButton(
              icon: Icon(AppIcons.moreVertical, color: AppColors.textSecondary),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(AppIcons.eye, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text('View Details', style: AppTextStyle.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(AppIcons.edit, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text('Edit', style: AppTextStyle.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(AppIcons.download, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text('Download', style: AppTextStyle.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(AppIcons.archive, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text('Archive', style: AppTextStyle.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(AppIcons.delete, size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    onViewDetail?.call(message.id);
                  // TODO: Implement other menu actions (edit, download, archive, delete)
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handlePlayAudio(BuildContext context, MessageUiModel message) {
    if (!message.hasPlayableAudio) return;

    // Get the audio player BLoC
    final audioBloc = context.read<AudioPlayerBloc>();

    // Stop any currently playing audio (ensure only one audio at a time)
    audioBloc.add(const StopAudio());

    // Load new audio - let the BLoC fetch the pre-signed URL
    audioBloc.add(
      LoadAudio(
        messageId: message.id,
        waveformData: message.playableAudioModel?.waveformData ?? [],
      ),
    );

    // Auto-play after loading
    audioBloc.add(const PlayAudio());

    // Panel will appear automatically via DashboardPanels
  }
}
