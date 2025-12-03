import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/waveform_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modal bottom sheet for audio playback controls
class AudioPlayerSheet extends StatelessWidget {
  const AudioPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          return switch (state) {
            AudioPlayerInitial() => const _EmptyState(),
            AudioPlayerLoading() => const _LoadingState(),
            AudioPlayerReady() => _PlayerControls(state: state),
            AudioPlayerError() => _ErrorState(message: state.message),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'No audio loaded',
          style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: AppProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.error, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.state});

  final AudioPlayerReady state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform visualization
        GestureDetector(
          onTapDown: (details) => _handleWaveformTap(context, details),
          child: SizedBox(
            height: 80,
            child: AppContainer(
              backgroundColor: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: WaveformPainter(
                  waveformData: state.waveformData,
                  progress: state.progress,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Time indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              state.positionFormatted,
              style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              state.durationFormatted,
              style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Seek slider
        Slider(
          value: state.position.inMilliseconds.toDouble(),
          max: state.duration.inMilliseconds.toDouble(),
          onChanged: (value) {
            context.read<AudioPlayerBloc>().add(
              SeekAudio(Duration(milliseconds: value.toInt())),
            );
          },
        ),

        const SizedBox(height: 16),

        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed control
            _SpeedButton(currentSpeed: state.speed),

            const SizedBox(width: 32),

            // Skip backward 10s
            AppIconButton(
              icon: AppIcons.rewind10,
              onPressed: () {
                final newPosition = state.position - const Duration(seconds: 10);
                context.read<AudioPlayerBloc>().add(
                  SeekAudio(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  ),
                );
              },
              size: AppIconButtonSize.large,
            ),

            const SizedBox(width: 16),

            // Play/Pause
            AppIconButton(
              icon: state.isPlaying ? AppIcons.pause : AppIcons.play,
              onPressed: () {
                if (state.isPlaying) {
                  context.read<AudioPlayerBloc>().add(const PauseAudio());
                } else {
                  context.read<AudioPlayerBloc>().add(const PlayAudio());
                }
              },
              size: AppIconButtonSize.large,
            ),

            const SizedBox(width: 16),

            // Skip forward 10s
            AppIconButton(
              icon: AppIcons.forward10,
              onPressed: () {
                final newPosition = state.position + const Duration(seconds: 10);
                context.read<AudioPlayerBloc>().add(
                  SeekAudio(
                    newPosition > state.duration ? state.duration : newPosition,
                  ),
                );
              },
              size: AppIconButtonSize.large,
            ),

            const SizedBox(width: 32),

            // Stop
            AppIconButton(
              icon: AppIcons.stop,
              onPressed: () {
                context.read<AudioPlayerBloc>().add(const StopAudio());
                Navigator.pop(context);
              },
              size: AppIconButtonSize.large,
            ),
          ],
        ),
      ],
    );
  }

  void _handleWaveformTap(BuildContext context, TapDownDetails details) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final localPosition = details.localPosition;
    final percentage = localPosition.dx / renderObject.size.width;
    final seekPosition = Duration(
      milliseconds: (state.duration.inMilliseconds * percentage).toInt(),
    );

    context.read<AudioPlayerBloc>().add(SeekAudio(seekPosition));
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.currentSpeed});

  final double currentSpeed;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: currentSpeed,
      icon: Text(
        '${currentSpeed}x',
        style: AppTextStyle.titleMedium.copyWith(
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
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 0.75,
          child: Text(
            '0.75x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            '1.0x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1.25,
          child: Text(
            '1.25x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1.5,
          child: Text(
            '1.5x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 1.75,
          child: Text(
            '1.75x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Text(
            '2.0x',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
