import 'package:equatable/equatable.dart';

sealed class AudioPlayerState extends Equatable {
  const AudioPlayerState();

  @override
  List<Object?> get props => [];
}

/// No audio loaded
class AudioPlayerInitial extends AudioPlayerState {
  const AudioPlayerInitial();
}

/// Loading audio source
class AudioPlayerLoading extends AudioPlayerState {
  const AudioPlayerLoading();
}

/// Audio ready and playing/paused
class AudioPlayerReady extends AudioPlayerState {
  const AudioPlayerReady({
    required this.messageId,
    required this.audioUrl,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.speed,
    required this.waveformData,
  });

  final String messageId;
  final String audioUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final double speed;
  final List<double> waveformData;

  /// Progress percentage (0.0 to 1.0)
  double get progress =>
      duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;

  /// Remaining time
  Duration get remaining => duration - position;

  /// Format position as MM:SS
  String get positionFormatted => _formatDuration(position);

  /// Format duration as MM:SS
  String get durationFormatted => _formatDuration(duration);

  /// Format remaining as MM:SS
  String get remainingFormatted => _formatDuration(remaining);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  List<Object?> get props => [
    messageId,
    audioUrl,
    duration,
    position,
    isPlaying,
    speed,
    waveformData,
  ];

  AudioPlayerReady copyWith({
    String? messageId,
    String? audioUrl,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    double? speed,
    List<double>? waveformData,
  }) {
    return AudioPlayerReady(
      messageId: messageId ?? this.messageId,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      speed: speed ?? this.speed,
      waveformData: waveformData ?? this.waveformData,
    );
  }
}

/// Error during playback
class AudioPlayerError extends AudioPlayerState {
  const AudioPlayerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
