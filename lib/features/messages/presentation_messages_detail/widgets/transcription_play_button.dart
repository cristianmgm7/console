import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TranscriptionPlayButton extends StatelessWidget {
  const TranscriptionPlayButton({
    required this.messageId,
    required this.audioModel,
    super.key,
  });

  final String messageId;
  final AudioModel audioModel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, audioState) {
        final isCurrentMessage =
            audioState is AudioPlayerReady && audioState.messageId == messageId;

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
              context.read<AudioPlayerBloc>().add(
                LoadAudio(
                  messageId: messageId,
                  audioModel: audioModel,
                ),
              );
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
                  isCurrentMessage && audioState.isPlaying ? Icons.pause : Icons.play_arrow,
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
}
