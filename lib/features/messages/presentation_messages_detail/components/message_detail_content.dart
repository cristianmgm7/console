import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailContent extends StatelessWidget {
  const MessageDetailContent({required this.state, super.key});

  final MessageDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentSection(),
          const SizedBox(height: 24),
          _buildMetadataSection(),
          const SizedBox(height: 24),
          _buildBasicInfoSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', message.id),
            _buildInfoRow('Creator', message.creatorId),
            _buildInfoRow('Created', _formatDate(message.createdAt)),
            _buildInfoRow('Duration', _formatDuration(message.duration)),
            _buildInfoRow('Status', message.status),
            _buildInfoRow('Type', message.type),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            if (message.transcriptText != null) ...[
              Text(
                'Transcript',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message.transcriptText!,
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'No transcript available',
                style: TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
            ],

            if (message.text != null) ...[
              Text(
                'Text',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message.text!,
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ] else if (message.transcriptText == null) ...[
              const Text(
                'No text content available',
                style: TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
            ],
            if (message.hasPlayableAudio) ...[
              const SizedBox(height: 8),
              _buildAudioPlayerButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (message.lastHeardAt != null)
              _buildInfoRow('Last Heard', _formatDate(message.lastHeardAt!)),
            if (message.heardDuration != null)
              _buildInfoRow('Heard Duration',
                  _formatDuration(message.heardDuration!),),
            if (message.totalHeardDuration != null)
              _buildInfoRow('Total Heard Duration',
                  _formatDuration(message.totalHeardDuration!),),
            if (message.lastUpdatedAt != null)
              _buildInfoRow('Last Updated',
                  _formatDate(message.lastUpdatedAt!),),
            _buildInfoRow('Workspace IDs',
                message.workspaceIds.join(', ')),
            _buildInfoRow('Channel IDs',
                message.channelIds.join(', ')),
            _buildInfoRow('Conversation ID', message.conversationId),
            _buildInfoRow('User ID', message.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerButton() {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        final message = state.message;
        final isCurrentMessage = audioState is AudioPlayerReady &&
            audioState.messageId == message.id;

        return InkWell(
          onTap: () {
            if (isCurrentMessage) {
              // Audio is loaded for this message, toggle play/pause
              if (audioState.isPlaying) {
                context.read<AudioPlayerBloc>().add(const PauseAudio());
              } else {
                context.read<AudioPlayerBloc>().add(const PlayAudio());
              }
            } else {
              // Load and play this message's audio
              final audioModel = message.playableAudioModel;
              if (audioModel != null) {
                context.read<AudioPlayerBloc>().add(
                      LoadAudio(
                        messageId: message.id,
                        waveformData: audioModel.waveformData,
                      ),
                    );
                // After loading, play the audio
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) {
                    context.read<AudioPlayerBloc>().add(const PlayAudio());
                  }
                });
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrentMessage && audioState.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCurrentMessage && audioState.isPlaying ? 'Pause' : 'Play',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
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
}
