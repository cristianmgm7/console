import 'dart:async';

import 'package:carbon_voice_console/features/audio_player/domain/usecases/get_audio_presigned_url_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/domain/services/audio_player_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton()
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  AudioPlayerBloc(
    this._playerService,
    this._logger,
    this._getAudioPreSignedUrlUsecase,
  ) : super(const AudioPlayerInitial()) {
    on<LoadAudio>(_onLoadAudio);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SeekAudio>(_onSeekAudio);
    on<SetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<PlayerStateUpdated>(_onPlayerStateUpdated);

    // Subscribe to service state streams
    _subscribeToServiceStreams();
  }

  final AudioPlayerService _playerService;
  final GetAudioPreSignedUrlUsecase _getAudioPreSignedUrlUsecase;

  final Logger _logger;

  // Current state tracking
  String? _currentMessageId;
  String? _currentAudioUrl;
  List<double> _currentWaveformData = [];
  double _currentSpeed = 1;

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<void>? _completionSubscription;

  void _subscribeToServiceStreams() {
    // Combine stream updates into single event
    _durationSubscription = _playerService.durationStream.listen((_) {
      _emitPlayerStateUpdate();
    });

    _positionSubscription = _playerService.positionStream.listen((_) {
      _emitPlayerStateUpdate();
    });

    _isPlayingSubscription = _playerService.isPlayingStream.listen((_) {
      _emitPlayerStateUpdate();
    });

    // Listen for playback completion
    _completionSubscription = _playerService.playbackCompleteStream.listen((_) {
      _logger.d('Playback completed, resetting to initial state');
      add(const StopAudio());
    });
  }

  void _emitPlayerStateUpdate() {
    if (_currentMessageId != null && _playerService.duration != null) {
      add(
        PlayerStateUpdated(
          duration: _playerService.duration!,
          position: _playerService.position,
          isPlaying: _playerService.isPlaying,
        ),
      );
    }
  }

  Future<void> _onLoadAudio(
    LoadAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      _logger.d('Loading audio for message: ${event.messageId}');
      emit(const AudioPlayerLoading());

      // Stop current playback if different message
      if (_currentMessageId != null && _currentMessageId != event.messageId) {
        await _playerService.stop();
      }

      _currentMessageId = event.messageId;
      _currentWaveformData = event.waveformData;

      // Fetch pre-signed URL using use case
      _logger.d('Fetching pre-signed URL for message ${event.messageId}');

      final result = await _getAudioPreSignedUrlUsecase(event.messageId);

      final audioUrl = result.fold(
        onSuccess: (url) => url,
        onFailure: (failure) {
          final errorMessage = failure.failureOrNull?.details ?? 'Failed to fetch audio URL';
          _logger.e('Failed to get pre-signed URL: $errorMessage');
          emit(AudioPlayerError(errorMessage));
          return null;
        },
      );

      if (audioUrl == null) {
        // Error already emitted in fold
        return;
      }

      _currentAudioUrl = audioUrl;

      // Pre-signed URLs don't need auth headers
      _logger.d('Using pre-signed URL, no auth headers required');

      // Load audio with empty headers (pre-signed URL has auth in the URL itself)
      await _playerService.loadAudio(audioUrl, {});

      // Emit ready state
      emit(
        AudioPlayerReady(
          messageId: _currentMessageId!,
          audioUrl: _currentAudioUrl!,
          duration: _playerService.duration ?? Duration.zero,
          position: _playerService.position,
          isPlaying: _playerService.isPlaying,
          speed: _currentSpeed,
          waveformData: _currentWaveformData,
        ),
      );
    } on Exception catch (e) {
      _logger.e('Failed to load audio', error: e);
      emit(AudioPlayerError('Failed to load audio: $e'));
    }
  }

  Future<void> _onPlayAudio(
    PlayAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    try {
      _logger.d('Playing audio');
      await _playerService.play();
    } on Exception catch (e) {
      _logger.e('Failed to play audio', error: e);
      emit(AudioPlayerError('Failed to play audio: $e'));
    }
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    try {
      _logger.d('Pausing audio');
      await _playerService.pause();
    } on Exception catch (e) {
      _logger.e('Failed to pause audio', error: e);
      emit(AudioPlayerError('Failed to pause audio: $e'));
    }
  }

  Future<void> _onStopAudio(
    StopAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      _logger.d('Stopping audio');
      await _playerService.stop();
      _currentMessageId = null;
      _currentAudioUrl = null;
      _currentWaveformData = [];
      emit(const AudioPlayerInitial());
    } on Exception catch (e) {
      _logger.e('Failed to stop audio', error: e);
      emit(AudioPlayerError('Failed to stop audio: $e'));
    }
  }

  Future<void> _onSeekAudio(
    SeekAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    try {
      _logger.d('Seeking to: ${event.position.inSeconds}s');
      await _playerService.seek(event.position);
    } on Exception catch (e) {
      _logger.e('Failed to seek', error: e);
      emit(AudioPlayerError('Failed to seek: $e'));
    }
  }

  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeed event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    try {
      if (event.speed <= 0 || event.speed > 3.0) {
        emit(const AudioPlayerError('Speed must be between 0 and 3.0'));
        return;
      }

      _logger.d('Setting speed to: ${event.speed}x');
      await _playerService.setSpeed(event.speed);
      _currentSpeed = event.speed;

      // Update state with new speed
      final currentState = state as AudioPlayerReady;
      emit(currentState.copyWith(speed: event.speed));
    } on Exception catch (e) {
      _logger.e('Failed to set speed', error: e);
      emit(AudioPlayerError('Failed to set speed: $e'));
    }
  }

  void _onPlayerStateUpdated(
    PlayerStateUpdated event,
    Emitter<AudioPlayerState> emit,
  ) {
    final currentState = state;
    if (currentState is AudioPlayerReady) {
      emit(
        currentState.copyWith(
          duration: event.duration,
          position: event.position,
          isPlaying: event.isPlaying,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _durationSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _isPlayingSubscription?.cancel();
    await _completionSubscription?.cancel();
    return super.close();
  }
}
