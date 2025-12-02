import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_icon_button.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A reusable play/pause button for message audio playback
class MessagePlayButton extends StatelessWidget {
  const MessagePlayButton({
    required this.message,
    required this.audioState,
    super.key,
  });

  final MessageUiModel message;
  final AudioPlayerState audioState;

  @override
  Widget build(BuildContext context) {
    if (audioState is AudioPlayerReady) {
      final audioPlayerReady = audioState as AudioPlayerReady;
      final isCurrentMessage = audioPlayerReady.messageId == message.id;
      final isPlaying = isCurrentMessage && audioPlayerReady.isPlaying;

      return AppIconButton(
        icon: isPlaying ? AppIcons.pause : AppIcons.play,
        tooltip: isPlaying ? 'Pause audio' : 'Play audio',
        onPressed: () => _handleAudioAction(context),
        foregroundColor: isCurrentMessage ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
        size: AppIconButtonSize.small,
      );
    } else {
      return AppIconButton(
        icon: AppIcons.play,
        tooltip: 'Play audio',
        onPressed: () => _handleAudioAction(context),
        foregroundColor: AppColors.primary.withValues(alpha: 0.7),
        size: AppIconButtonSize.small,
      );
    }
  }

  Future<void> _handleAudioAction(BuildContext context) async {
    final audioBloc = context.read<AudioPlayerBloc>();

    if (audioState is AudioPlayerReady) {
      final audioPlayerReady = audioState as AudioPlayerReady;
      if (audioPlayerReady.messageId == message.id) {
        // Toggle play/pause for current message
        if (audioPlayerReady.isPlaying) {
          audioBloc.add(const PauseAudio());
        } else {
          audioBloc.add(const PlayAudio());
        }
        return;
      }
    }

    // Load and play new message
    await _handlePlayAudio(context);
  }

  Future<void> _handlePlayAudio(BuildContext context) async {
    if (!message.hasPlayableAudio || message.audioUrl == null) return;

    // Get the audio player BLoC
    final audioBloc = context.read<AudioPlayerBloc>();

    // Load audio - let the BLoC fetch the pre-signed URL
    audioBloc.add(
      LoadAudio(
        messageId: message.id,
        waveformData: message.playableAudioModel?.waveformData ?? [],
      ),
    );

    // Auto-play after loading (no modal shown)
    audioBloc.add(const PlayAudio());
  }
}
