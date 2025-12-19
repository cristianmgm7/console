import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Component for displaying audio duration and playback controls
class AudioControls extends StatelessWidget {
  const AudioControls({
    required this.message,
    this.isOwner = false,
    super.key,
  });

  final MessageUiModel message;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        final isCurrentMessage = audioState is AudioPlayerReady && audioState.messageId == message.id;
        final isLoadingForThisMessage = audioState is AudioPlayerLoading && message.hasPlayableAudio;

        return Row(
          children: [
            // Play button or loading indicator
            if (message.hasPlayableAudio) ...[
              if (isLoadingForThisMessage) ...[
                _buildLoadingIndicator(),
              ] else ...[
                _buildAudioPlayerButton(),
              ],
            ],
            const SizedBox(width: 12),
            Text(
              _getDurationText(audioState, isCurrentMessage),
              style: AppTextStyle.bodySmall.copyWith(
                color: isOwner ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioPlayerButton() {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        final isCurrentMessage = audioState is AudioPlayerReady && audioState.messageId == message.id;
        final isPlaying = isCurrentMessage && audioState.isPlaying;

        return IconButton(
          onPressed: () => _handleAudioButtonPressed(context, isPlaying, isCurrentMessage),
          icon: Icon(
            isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: isOwner ? AppColors.onPrimary : AppColors.primary,
            size: 30,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(6),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          isOwner ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
    );
  }

  String _getDurationText(AudioPlayerState audioState, bool isCurrentMessage) {
    if (isCurrentMessage && audioState is AudioPlayerReady) {
      // Show current position / total duration
      return '${audioState.positionFormatted} / ${audioState.durationFormatted}';
    } else {
      // Show total duration only
      return DateTimeFormatters.formatDuration(message.audioModels.first.duration);
    }
  }

  void _handleAudioButtonPressed(BuildContext context, bool isPlaying, bool isCurrentMessage) {
    final bloc = context.read<AudioPlayerBloc>();
    if (isPlaying) {
      bloc.add(const PauseAudio());
    } else if (isCurrentMessage) {
      bloc.add(const PlayAudio());
    } else {
      final audioModel = message.playableAudioModel;
      if (audioModel != null) {
        bloc.add(LoadAudio(
          messageId: message.id,
          audioModel: audioModel,
        ));
        bloc.add(const PlayAudio());
      }
    }
  }
}
