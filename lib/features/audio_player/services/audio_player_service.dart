import 'dart:async';

/// Abstract service for audio playback operations
abstract class AudioPlayerService {
  /// Load audio from URL with authentication headers
  Future<void> loadAudio(String url, Map<String, String> headers);

  /// Start or resume playback
  Future<void> play();

  /// Pause playback
  Future<void> pause();

  /// Stop playback
  Future<void> stop();

  /// Seek to position
  Future<void> seek(Duration position);

  /// Set playback speed
  Future<void> setSpeed(double speed);

  /// Get current duration
  Duration? get duration;

  /// Get current position
  Duration get position;

  /// Get playing state
  bool get isPlaying;

  /// Get current speed
  double get speed;

  /// Stream of duration changes
  Stream<Duration> get durationStream;

  /// Stream of position changes
  Stream<Duration> get positionStream;

  /// Stream of playing state changes
  Stream<bool> get isPlayingStream;

  /// Stream of loading state changes
  Stream<bool> get isLoadingStream;

  /// Dispose resources
  Future<void> dispose();
}
