import 'dart:async';

import 'package:carbon_voice_console/features/audio_player/services/audio_player_service.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AudioPlayerService)
class AudioPlayerServiceImpl implements AudioPlayerService {
  AudioPlayerServiceImpl(this._logger) {
    _player = AudioPlayer();
    _initializeStreamSubscriptions();
  }

  final Logger _logger;
  late final AudioPlayer _player;

  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // State stream controllers
  final _durationController = StreamController<Duration>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _isLoadingController = StreamController<bool>.broadcast();

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  void _initializeStreamSubscriptions() {
    // Duration changes
    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null) {
        _durationController.add(duration);
      }
    });

    // Position changes
    _positionSubscription = _player.positionStream.listen(_positionController.add);

    // Player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isPlayingController.add(state.playing);
      _isLoadingController.add(state.processingState == ProcessingState.loading);
    });
  }

  @override
  Future<void> loadAudio(String url, Map<String, String> headers) async {
    try {
      _logger.i('Loading audio from: $url');
      _logger.d('Headers: ${headers.keys.toList()}');

      final audioSource = AudioSource.uri(
        Uri.parse(url),
        headers: headers,
      );

      await _player.setAudioSource(audioSource);

      _logger.i('Audio loaded successfully, duration: ${_player.duration}');
    } catch (e, stackTrace) {
      _logger.e('Failed to load audio', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
      _logger.d('Playback started');
    } catch (e, stackTrace) {
      _logger.e('Failed to start playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      _logger.d('Playback paused');
    } catch (e, stackTrace) {
      _logger.e('Failed to pause playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      _logger.d('Playback stopped');
    } catch (e, stackTrace) {
      _logger.e('Failed to stop playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _logger.d('Seeked to position: ${position.inSeconds}s');
    } catch (e, stackTrace) {
      _logger.e('Failed to seek', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      _logger.d('Speed set to: ${speed}x');
    } catch (e, stackTrace) {
      _logger.e('Failed to set speed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Duration? get duration => _player.duration;

  @override
  Duration get position => _player.position;

  @override
  bool get isPlaying => _player.playing;

  @override
  double get speed => _player.speed;

  @override
  Future<void> dispose() async {
    await _durationSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _durationController.close();
    await _positionController.close();
    await _isPlayingController.close();
    await _isLoadingController.close();
    await _player.dispose();
    _logger.d('AudioPlayerService disposed');
  }
}
