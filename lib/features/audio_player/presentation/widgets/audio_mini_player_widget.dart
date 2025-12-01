import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Compact mini player widget that appears in content stack during audio playback
class AudioMiniPlayerWidget extends StatelessWidget {
  const AudioMiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        return switch (state) {
          AudioPlayerReady() => _MiniPlayerContent(state: state),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  const _MiniPlayerContent({required this.state});

  final AudioPlayerReady state;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
      child: Row(
        children: [
          // Play/Pause Button
          _buildPlayPauseButton(context),

          const SizedBox(width: 12),

          // Progress and Time
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 4,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: state.position.inMilliseconds.toDouble().clamp(
                          0,
                          state.duration.inMilliseconds.toDouble(),
                        ),
                    max: state.duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      context.read<AudioPlayerBloc>().add(
                            SeekAudio(Duration(milliseconds: value.toInt())),
                          );
                    },
                  ),
                ),

                // Time Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.positionFormatted,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        state.durationFormatted,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Speed Control
          _SpeedButton(currentSpeed: state.speed),

          const SizedBox(width: 8),

          // Dismiss Button
          AppIconButton(
            icon: AppIcons.close,
            tooltip: 'Stop and close player',
            onPressed: () {
              context.read<AudioPlayerBloc>().add(const StopAudio());
            },
            size: AppIconButtonSize.small,
            foregroundColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(BuildContext context) {
    return InkWell(
      onTap: () {
        if (state.isPlaying) {
          context.read<AudioPlayerBloc>().add(const PauseAudio());
        } else {
          context.read<AudioPlayerBloc>().add(const PlayAudio());
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.currentSpeed});

  final double currentSpeed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: Text(
        '${currentSpeed}x',
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onSelected: (speed) {
        context.read<AudioPlayerBloc>().add(SetPlaybackSpeed(speed));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0.5,
          child: Text(
            '0.5x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 0.75,
          child: Text(
            '0.75x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            '1.0x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1.25,
          child: Text(
            '1.25x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1.5,
          child: Text(
            '1.5x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Text(
            '2.0x',
            style: AppTextStyle.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
