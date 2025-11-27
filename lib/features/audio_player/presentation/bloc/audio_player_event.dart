import 'package:equatable/equatable.dart';

sealed class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Load and prepare audio for playback
class LoadAudio extends AudioPlayerEvent {
  const LoadAudio({
    required this.messageId,
    required this.audioUrl,
    required this.waveformData,
  });

  final String messageId;
  final String audioUrl;
  final List<double> waveformData;

  @override
  List<Object?> get props => [messageId, audioUrl, waveformData];
}

/// Start or resume playback
class PlayAudio extends AudioPlayerEvent {
  const PlayAudio();
}

/// Pause playback
class PauseAudio extends AudioPlayerEvent {
  const PauseAudio();
}

/// Stop playback and clear state
class StopAudio extends AudioPlayerEvent {
  const StopAudio();
}

/// Seek to specific position
class SeekAudio extends AudioPlayerEvent {
  const SeekAudio(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

/// Set playback speed
class SetPlaybackSpeed extends AudioPlayerEvent {
  const SetPlaybackSpeed(this.speed);

  final double speed;

  @override
  List<Object?> get props => [speed];
}

/// Internal event for player state updates from service streams
class PlayerStateUpdated extends AudioPlayerEvent {
  const PlayerStateUpdated({
    required this.duration,
    required this.position,
    required this.isPlaying,
  });

  final Duration duration;
  final Duration position;
  final bool isPlaying;

  @override
  List<Object?> get props => [duration, position, isPlaying];
}
