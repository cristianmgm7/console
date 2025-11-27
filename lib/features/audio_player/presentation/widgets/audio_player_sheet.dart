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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    return const SizedBox(
      height: 200,
      child: Center(
        child: Text('No audio loaded'),
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
        child: CircularProgressIndicator(),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
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
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: WaveformPainter(
                waveformData: state.waveformData,
                progress: state.progress,
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Colors.grey.shade400,
              ),
              size: Size.infinite,
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
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              state.durationFormatted,
              style: Theme.of(context).textTheme.bodySmall,
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
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: 32,
              onPressed: () {
                final newPosition = state.position - const Duration(seconds: 10);
                context.read<AudioPlayerBloc>().add(
                      SeekAudio(
                        newPosition < Duration.zero ? Duration.zero : newPosition,
                      ),
                    );
              },
            ),

            const SizedBox(width: 16),

            // Play/Pause
            IconButton(
              icon: Icon(
                state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              ),
              iconSize: 64,
              onPressed: () {
                if (state.isPlaying) {
                  context.read<AudioPlayerBloc>().add(const PauseAudio());
                } else {
                  context.read<AudioPlayerBloc>().add(const PlayAudio());
                }
              },
            ),

            const SizedBox(width: 16),

            // Skip forward 10s
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: 32,
              onPressed: () {
                final newPosition = state.position + const Duration(seconds: 10);
                context.read<AudioPlayerBloc>().add(
                      SeekAudio(
                        newPosition > state.duration ? state.duration : newPosition,
                      ),
                    );
              },
            ),

            const SizedBox(width: 32),

            // Stop
            IconButton(
              icon: const Icon(Icons.stop),
              iconSize: 32,
              onPressed: () {
                context.read<AudioPlayerBloc>().add(const StopAudio());
                Navigator.pop(context);
              },
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onSelected: (speed) {
        context.read<AudioPlayerBloc>().add(SetPlaybackSpeed(speed));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 1.75, child: Text('1.75x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
    );
  }
}
