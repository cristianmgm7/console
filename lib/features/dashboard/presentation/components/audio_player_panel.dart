import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/waveform_painter.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/base_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Side panel for audio playback with focus/compact modes
class AudioPlayerPanel extends StatefulWidget {
  const AudioPlayerPanel({super.key});

  @override
  State<AudioPlayerPanel> createState() => _AudioPlayerPanelState();
}

class _AudioPlayerPanelState extends State<AudioPlayerPanel> {
  bool _isFocused = true; // Start in focused mode when opened

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        if (state is! AudioPlayerReady && state is! AudioPlayerLoading) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            if (!_isFocused) {
              setState(() => _isFocused = true);
            }
          },
          child: BasePanel(
            width: 400,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isFocused ? 340 : 80,
              child: _isFocused ? _buildFocusedMode(state) : _buildCompactMode(state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusedMode(AudioPlayerState state) {
    if (state is AudioPlayerLoading) {
      return const Center(child: AppProgressIndicator());
    }

    if (state is! AudioPlayerReady) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Header
        AppContainer(
          padding: const EdgeInsets.all(16),
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(AppIcons.play, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Now Playing',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              AppIconButton(
                icon: AppIcons.minimize,
                onPressed: () => setState(() => _isFocused = false),
                tooltip: 'Minimize',
                size: AppIconButtonSize.small,
              ),
              const SizedBox(width: 4),
              AppIconButton(
                icon: AppIcons.close,
                onPressed: () {
                  context.read<AudioPlayerBloc>().add(const StopAudio());
                },
                tooltip: 'Stop',
                size: AppIconButtonSize.small,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPlayerControls(state),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMode(AudioPlayerState state) {
    if (state is! AudioPlayerReady) {
      return const SizedBox.shrink();
    }

    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: const Border(
        bottom: BorderSide(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Play/Pause button
          AppIconButton(
            icon: state.isPlaying ? AppIcons.pause : AppIcons.play,
            onPressed: () {
              if (state.isPlaying) {
                context.read<AudioPlayerBloc>().add(const PauseAudio());
              } else {
                context.read<AudioPlayerBloc>().add(const PlayAudio());
              }
            },
            size: AppIconButtonSize.medium,
            foregroundColor: AppColors.primary,
          ),

          const SizedBox(width: 12),

          // Progress info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Message ${state.messageId.substring(0, 8)}...',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.positionFormatted,
                      style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Stop button
          AppIconButton(
            icon: AppIcons.stop,
            onPressed: () {
              context.read<AudioPlayerBloc>().add(const StopAudio());
            },
            size: AppIconButtonSize.small,
            foregroundColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(AudioPlayerReady state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform visualization
        GestureDetector(
          onTapDown: (details) => _handleWaveformTap(details, state),
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
              foregroundColor: AppColors.primary,
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
          ],
        ),
      ],
    );
  }

  void _handleWaveformTap(TapDownDetails details, AudioPlayerReady state) {
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
          child: Text('0.5x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 0.75,
          child: Text('0.75x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 1.0,
          child: Text('1.0x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 1.25,
          child: Text('1.25x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 1.5,
          child: Text('1.5x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 1.75,
          child: Text('1.75x', style: AppTextStyle.bodyMedium),
        ),
        PopupMenuItem(
          value: 2.0,
          child: Text('2.0x', style: AppTextStyle.bodyMedium),
        ),
      ],
    );
  }
}
