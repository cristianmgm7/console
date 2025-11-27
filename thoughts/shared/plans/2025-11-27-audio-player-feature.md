# Audio Player Feature Implementation Plan

## Overview

Implement a complete audio playback system for message MP3 files using Flutter's `just_audio` package. The feature will enable users to stream and play authenticated audio content directly from message URLs with a persistent modal bottom sheet player interface.

## Current State Analysis

### Existing Infrastructure
- **Message Entity** ([message.dart:1](lib/features/messages/domain/entities/message.dart#L1)): Contains `audioModels` list with audio metadata
- **AudioModel Entity** ([audio_model.dart:1](lib/features/messages/domain/entities/audio_model.dart#L1)): Has `url`, `duration`, `waveformData`, `format`, `isOriginal`
- **MessageUiModel** ([message_ui_model.dart:56](lib/features/messages/presentation/models/message_ui_model.dart#L56)): Has computed `audioUrl` property
- **Authenticated HTTP Service** ([download_http_service.dart:16](lib/features/message_download/data/datasources/download_http_service.dart#L16)): Already handles OAuth-authenticated requests
- **Architecture Pattern**: Clean architecture with domain/data/presentation layers, BLoC state management, injectable DI

### Key Discoveries
- Audio URLs require OAuth authentication headers
- Messages already contain complete audio metadata including waveform data
- Existing download feature demonstrates authenticated file access pattern
- Dashboard uses MessageCard widgets that can trigger playback
- BLoC pattern used consistently: sealed events/states with Equatable, Result type for error handling

### Dependencies Available
- `flutter_bloc: ^8.1.6` - State management
- `equatable: ^2.0.7` - Value equality
- `injectable: ^2.5.0` / `get_it: ^8.0.2` - Dependency injection
- `logger: ^2.6.2` - Logging
- `dio: ^5.7.0` - HTTP client (used by AuthenticatedHttpService)

## Desired End State

A fully functional audio player system where:

1. Users can click a play button on any MessageCard to start audio playback
2. A persistent modal bottom sheet appears showing player controls
3. Audio streams directly from authenticated URLs without pre-downloading
4. Users can control playback with play/pause, seek, speed adjustment
5. Waveform visualization displays using existing message waveformData
6. Player state persists across the modal (closing/reopening shows current state)
7. Only one audio file plays at a time (starting new audio stops current)

### Verification
- Clicking play on a message opens the player modal and begins playback
- Player controls (play/pause, seek, speed) work correctly
- Waveform renders and highlights current position
- Authenticated audio streams successfully
- Player state remains consistent when modal is closed/reopened
- Stopping one message and playing another works seamlessly

## What We're NOT Doing

- **Background playback**: Audio stops when app is backgrounded
- **Playlist/queue system**: No auto-advance to next message
- **Download for offline**: Streaming only, no local caching
- **Volume control**: Use system volume
- **Audio effects**: No equalizer or audio processing
- **Notifications**: No system media notifications
- **Picture-in-Picture**: No PiP mode
- **Playback history**: No tracking of listened messages
- **Resume on app restart**: Player state doesn't persist between app sessions

## Implementation Approach

### Architecture Strategy
Create a new `audio_player` feature following clean architecture:
- **Domain**: Player entities, repository interface, use cases for play/pause/seek
- **Data**: just_audio implementation with authenticated audio source
- **Presentation**: BLoC for state management, modal player widget

### Authentication Strategy
Use `AudioSource.uri` with headers parameter to pass OAuth token. The just_audio package supports this natively via its localhost proxy server.

### State Management Strategy
- Global singleton `AudioPlayerBloc` managed via GetIt (LazySingleton)
- Player state persists across modal open/close
- Events dispatched from MessageCard and player controls
- States track current message, playback position, duration, playing status, speed

### Technical Approach
1. Add `just_audio` dependency
2. Create authenticated audio source wrapper using existing AuthenticatedHttpService
3. Build domain layer with player entities and use cases
4. Implement data layer with just_audio player service
5. Create BLoC with events/states for all player operations
6. Build modal player UI with waveform visualization
7. Integrate play button into MessageCard

---

## Phase 1: Dependencies and Domain Layer

### Overview
Set up project dependencies and create the domain layer with entities, repository interface, and core business logic.

### Changes Required

#### 1. Add Dependencies
**File**: `pubspec.yaml`

Add just_audio package:
```yaml
dependencies:
  # ... existing dependencies

  # Audio Playback
  just_audio: ^0.9.40
```

**Verification Commands**:
- Run: `flutter pub get`
- Verify package resolves without conflicts

#### 2. Domain Entities

**File**: `lib/features/audio_player/domain/entities/player_state.dart`

Create player state entity:
```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing audio player state
class PlayerState extends Equatable {
  const PlayerState({
    required this.messageId,
    required this.audioUrl,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.isPaused,
    required this.isLoading,
    required this.speed,
    required this.waveformData,
  });

  final String messageId;
  final String audioUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isPaused;
  final bool isLoading;
  final double speed; // 1.0, 1.5, 2.0, etc.
  final List<double> waveformData;

  /// Progress percentage (0.0 to 1.0)
  double get progress => duration.inMilliseconds > 0
      ? position.inMilliseconds / duration.inMilliseconds
      : 0.0;

  /// Remaining time
  Duration get remaining => duration - position;

  @override
  List<Object?> get props => [
        messageId,
        audioUrl,
        duration,
        position,
        isPlaying,
        isPaused,
        isLoading,
        speed,
        waveformData,
      ];
}
```

**File**: `lib/features/audio_player/domain/entities/playback_error.dart`

Create error entity:
```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing playback errors
class PlaybackError extends Equatable {
  const PlaybackError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final String? details;

  @override
  List<Object?> get props => [code, message, details];
}
```

#### 3. Domain Repository Interface

**File**: `lib/features/audio_player/domain/repositories/audio_player_repository.dart`

Define repository contract:
```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/entities/player_state.dart';

/// Repository interface for audio player operations
abstract class AudioPlayerRepository {
  /// Initialize and load audio source
  /// Returns initial player state or error
  Future<Result<PlayerState>> loadAudio({
    required String messageId,
    required String audioUrl,
    required List<double> waveformData,
    required Map<String, String> headers,
  });

  /// Start or resume playback
  Future<Result<void>> play();

  /// Pause playback
  Future<Result<void>> pause();

  /// Stop playback and release resources
  Future<Result<void>> stop();

  /// Seek to specific position
  Future<Result<void>> seek(Duration position);

  /// Set playback speed
  Future<Result<void>> setSpeed(double speed);

  /// Get current player state
  Future<Result<PlayerState>> getPlayerState();

  /// Stream of player state changes
  Stream<PlayerState> get playerStateStream;

  /// Dispose player resources
  Future<void> dispose();
}
```

#### 4. Domain Use Cases

**File**: `lib/features/audio_player/domain/usecases/load_audio_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/entities/player_state.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class LoadAudioUsecase {
  const LoadAudioUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<PlayerState>> call({
    required String messageId,
    required String audioUrl,
    required List<double> waveformData,
    required Map<String, String> authHeaders,
  }) async {
    _logger.d('Loading audio for message: $messageId');

    if (audioUrl.isEmpty) {
      _logger.w('Cannot load audio: URL is empty');
      return failure(const AppFailure(
        code: 'INVALID_URL',
        details: 'Audio URL is empty',
      ));
    }

    final result = await _repository.loadAudio(
      messageId: messageId,
      audioUrl: audioUrl,
      waveformData: waveformData,
      headers: authHeaders,
    );

    result.fold(
      onSuccess: (state) => _logger.i('Audio loaded successfully: $messageId'),
      onFailure: (failure) => _logger.e('Failed to load audio: ${failure.failure.details}'),
    );

    return result;
  }
}
```

**File**: `lib/features/audio_player/domain/usecases/play_audio_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PlayAudioUsecase {
  const PlayAudioUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<void>> call() async {
    _logger.d('Starting audio playback');
    return await _repository.play();
  }
}
```

**File**: `lib/features/audio_player/domain/usecases/pause_audio_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PauseAudioUsecase {
  const PauseAudioUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<void>> call() async {
    _logger.d('Pausing audio playback');
    return await _repository.pause();
  }
}
```

**File**: `lib/features/audio_player/domain/usecases/seek_audio_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class SeekAudioUsecase {
  const SeekAudioUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<void>> call(Duration position) async {
    _logger.d('Seeking to position: ${position.inSeconds}s');
    return await _repository.seek(position);
  }
}
```

**File**: `lib/features/audio_player/domain/usecases/set_speed_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class SetSpeedUsecase {
  const SetSpeedUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<void>> call(double speed) async {
    _logger.d('Setting playback speed to ${speed}x');

    if (speed <= 0 || speed > 3.0) {
      _logger.w('Invalid speed value: $speed');
      return failure(const AppFailure(
        code: 'INVALID_SPEED',
        details: 'Speed must be between 0 and 3.0',
      ));
    }

    return await _repository.setSpeed(speed);
  }
}
```

**File**: `lib/features/audio_player/domain/usecases/stop_audio_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class StopAudioUsecase {
  const StopAudioUsecase(this._repository, this._logger);

  final AudioPlayerRepository _repository;
  final Logger _logger;

  Future<Result<void>> call() async {
    _logger.d('Stopping audio playback');
    return await _repository.stop();
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Dependencies install successfully: `flutter pub get`
- [ ] No compilation errors: `flutter analyze`
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] All files created in correct directory structure

#### Manual Verification:
- [ ] Domain entities have proper Equatable implementation
- [ ] Repository interface defines all needed operations
- [ ] Use cases follow existing patterns from message_download feature
- [ ] All imports reference correct paths
- [ ] Logger integration matches existing patterns

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Data Layer - Audio Player Service

### Overview
Implement the data layer with just_audio integration, authenticated audio source, and repository implementation.

### Changes Required

#### 1. Authenticated Audio Source

**File**: `lib/features/audio_player/data/datasources/authenticated_audio_source.dart`

Create custom audio source that wraps AudioSource.uri with auth headers:
```dart
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

/// Wrapper for creating authenticated audio sources
class AuthenticatedAudioSource {
  const AuthenticatedAudioSource(this._logger);

  final Logger _logger;

  /// Creates an audio source with authentication headers
  AudioSource createSource(String url, Map<String, String> headers) {
    _logger.d('Creating authenticated audio source for URL: $url');
    _logger.d('Headers: ${headers.keys.toList()}');

    return AudioSource.uri(
      Uri.parse(url),
      headers: headers,
    );
  }
}
```

#### 2. Audio Player Service

**File**: `lib/features/audio_player/data/datasources/audio_player_service.dart`

Create service that wraps just_audio player:
```dart
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:carbon_voice_console/features/audio_player/data/datasources/authenticated_audio_source.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for managing audio playback using just_audio
@LazySingleton()
class AudioPlayerService {
  AudioPlayerService(this._audioSourceFactory, this._logger) {
    _player = AudioPlayer();
    _initializeStreamSubscriptions();
  }

  final AuthenticatedAudioSource _audioSourceFactory;
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

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  void _initializeStreamSubscriptions() {
    // Duration changes
    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null) {
        _durationController.add(duration);
      }
    });

    // Position changes
    _positionSubscription = _player.positionStream.listen((position) {
      _positionController.add(position);
    });

    // Player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _isPlayingController.add(state.playing);
      _isLoadingController.add(state.processingState == ProcessingState.loading);
    });
  }

  /// Load audio from URL with authentication headers
  Future<void> loadAudio(String url, Map<String, String> headers) async {
    try {
      _logger.i('Loading audio from: $url');

      final audioSource = _audioSourceFactory.createSource(url, headers);

      await _player.setAudioSource(audioSource);

      _logger.i('Audio loaded successfully, duration: ${_player.duration}');
    } catch (e, stackTrace) {
      _logger.e('Failed to load audio', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start or resume playback
  Future<void> play() async {
    try {
      await _player.play();
      _logger.d('Playback started');
    } catch (e, stackTrace) {
      _logger.e('Failed to start playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _logger.d('Playback paused');
    } catch (e, stackTrace) {
      _logger.e('Failed to pause playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _logger.d('Playback stopped');
    } catch (e, stackTrace) {
      _logger.e('Failed to stop playback', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _logger.d('Seeked to position: ${position.inSeconds}s');
    } catch (e, stackTrace) {
      _logger.e('Failed to seek', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      _logger.d('Speed set to: ${speed}x');
    } catch (e, stackTrace) {
      _logger.e('Failed to set speed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get current duration
  Duration? get duration => _player.duration;

  /// Get current position
  Duration get position => _player.position;

  /// Get playing state
  bool get isPlaying => _player.playing;

  /// Get current speed
  double get speed => _player.speed;

  /// Dispose resources
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
```

#### 3. Repository Implementation

**File**: `lib/features/audio_player/data/repositories/audio_player_repository_impl.dart`

```dart
import 'dart:async';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/audio_player/data/datasources/audio_player_service.dart';
import 'package:carbon_voice_console/features/audio_player/domain/entities/player_state.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AudioPlayerRepository)
class AudioPlayerRepositoryImpl implements AudioPlayerRepository {
  AudioPlayerRepositoryImpl(this._playerService, this._logger);

  final AudioPlayerService _playerService;
  final Logger _logger;

  // Current state tracking
  String? _currentMessageId;
  String? _currentAudioUrl;
  List<double> _currentWaveformData = [];
  double _currentSpeed = 1.0;

  // State stream controller
  final _stateController = StreamController<PlayerState>.broadcast();

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  Future<Result<PlayerState>> loadAudio({
    required String messageId,
    required String audioUrl,
    required List<double> waveformData,
    required Map<String, String> headers,
  }) async {
    try {
      _logger.i('Loading audio for message: $messageId');

      // Stop current playback if different message
      if (_currentMessageId != null && _currentMessageId != messageId) {
        await _playerService.stop();
      }

      _currentMessageId = messageId;
      _currentAudioUrl = audioUrl;
      _currentWaveformData = waveformData;

      await _playerService.loadAudio(audioUrl, headers);

      final state = _createCurrentState();
      _stateController.add(state);

      return success(state);
    } on Exception catch (e) {
      _logger.e('Failed to load audio', error: e);
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> play() async {
    try {
      await _playerService.play();
      _emitCurrentState();
      return success(null);
    } on Exception catch (e) {
      _logger.e('Failed to play audio', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> pause() async {
    try {
      await _playerService.pause();
      _emitCurrentState();
      return success(null);
    } on Exception catch (e) {
      _logger.e('Failed to pause audio', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _playerService.stop();
      _currentMessageId = null;
      _currentAudioUrl = null;
      _currentWaveformData = [];
      _emitCurrentState();
      return success(null);
    } on Exception catch (e) {
      _logger.e('Failed to stop audio', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> seek(Duration position) async {
    try {
      await _playerService.seek(position);
      _emitCurrentState();
      return success(null);
    } on Exception catch (e) {
      _logger.e('Failed to seek', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> setSpeed(double speed) async {
    try {
      await _playerService.setSpeed(speed);
      _currentSpeed = speed;
      _emitCurrentState();
      return success(null);
    } on Exception catch (e) {
      _logger.e('Failed to set speed', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<PlayerState>> getPlayerState() async {
    return success(_createCurrentState());
  }

  PlayerState _createCurrentState() {
    return PlayerState(
      messageId: _currentMessageId ?? '',
      audioUrl: _currentAudioUrl ?? '',
      duration: _playerService.duration ?? Duration.zero,
      position: _playerService.position,
      isPlaying: _playerService.isPlaying,
      isPaused: !_playerService.isPlaying && _currentMessageId != null,
      isLoading: false,
      speed: _currentSpeed,
      waveformData: _currentWaveformData,
    );
  }

  void _emitCurrentState() {
    _stateController.add(_createCurrentState());
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _playerService.dispose();
  }
}
```

#### 4. Register AuthenticatedAudioSource

**File**: `lib/features/audio_player/data/datasources/authenticated_audio_source.dart`

Update to add injectable annotation:
```dart
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

@injectable
class AuthenticatedAudioSource {
  const AuthenticatedAudioSource(this._logger);

  final Logger _logger;

  AudioSource createSource(String url, Map<String, String> headers) {
    _logger.d('Creating authenticated audio source for URL: $url');
    _logger.d('Headers: ${headers.keys.toList()}');

    return AudioSource.uri(
      Uri.parse(url),
      headers: headers,
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] No compilation errors: `flutter analyze`
- [ ] Type checking passes: `flutter analyze --no-fatal-infos`

#### Manual Verification:
- [ ] AudioPlayerService initializes just_audio player correctly
- [ ] Authenticated headers are passed to AudioSource.uri
- [ ] Repository implements all interface methods
- [ ] Stream subscriptions are properly managed
- [ ] Error handling follows existing patterns
- [ ] Dependency injection annotations are correct

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: Presentation Layer - BLoC

### Overview
Create BLoC components for audio player state management with events and states following existing patterns.

### Changes Required

#### 1. Events

**File**: `lib/features/audio_player/presentation/bloc/audio_player_event.dart`

```dart
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

/// Internal event for player state updates from repository stream
class PlayerStateUpdated extends AudioPlayerEvent {
  const PlayerStateUpdated(this.state);

  final dynamic state; // PlayerState from domain

  @override
  List<Object?> get props => [state];
}
```

#### 2. States

**File**: `lib/features/audio_player/presentation/bloc/audio_player_state.dart`

```dart
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
  double get progress => duration.inMilliseconds > 0
      ? position.inMilliseconds / duration.inMilliseconds
      : 0.0;

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
```

#### 3. BLoC

**File**: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`

```dart
import 'dart:async';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/load_audio_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/pause_audio_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/play_audio_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/seek_audio_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/set_speed_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/usecases/stop_audio_usecase.dart';
import 'package:carbon_voice_console/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton()
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  AudioPlayerBloc(
    this._loadAudioUsecase,
    this._playAudioUsecase,
    this._pauseAudioUsecase,
    this._stopAudioUsecase,
    this._seekAudioUsecase,
    this._setSpeedUsecase,
    this._repository,
    this._authService,
    this._logger,
  ) : super(const AudioPlayerInitial()) {
    on<LoadAudio>(_onLoadAudio);
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SeekAudio>(_onSeekAudio);
    on<SetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<PlayerStateUpdated>(_onPlayerStateUpdated);

    // Subscribe to repository state stream
    _stateSubscription = _repository.playerStateStream.listen((playerState) {
      add(PlayerStateUpdated(playerState));
    });
  }

  final LoadAudioUsecase _loadAudioUsecase;
  final PlayAudioUsecase _playAudioUsecase;
  final PauseAudioUsecase _pauseAudioUsecase;
  final StopAudioUsecase _stopAudioUsecase;
  final SeekAudioUsecase _seekAudioUsecase;
  final SetSpeedUsecase _setSpeedUsecase;
  final AudioPlayerRepository _repository;
  final AuthenticatedHttpService _authService;
  final Logger _logger;

  StreamSubscription? _stateSubscription;

  Future<void> _onLoadAudio(
    LoadAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    _logger.d('Loading audio for message: ${event.messageId}');
    emit(const AudioPlayerLoading());

    // Get auth headers from authenticated service
    final authHeaders = await _authService.getAuthHeaders();

    final result = await _loadAudioUsecase(
      messageId: event.messageId,
      audioUrl: event.audioUrl,
      waveformData: event.waveformData,
      authHeaders: authHeaders,
    );

    result.fold(
      onSuccess: (playerState) {
        emit(AudioPlayerReady(
          messageId: playerState.messageId,
          audioUrl: playerState.audioUrl,
          duration: playerState.duration,
          position: playerState.position,
          isPlaying: playerState.isPlaying,
          speed: playerState.speed,
          waveformData: playerState.waveformData,
        ));
      },
      onFailure: (failure) {
        emit(AudioPlayerError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onPlayAudio(
    PlayAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    _logger.d('Playing audio');
    final result = await _playAudioUsecase();

    if (result.isFailure) {
      emit(AudioPlayerError(FailureMapper.mapToMessage(result.failureOrNull!.failure)));
    }
  }

  Future<void> _onPauseAudio(
    PauseAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    _logger.d('Pausing audio');
    final result = await _pauseAudioUsecase();

    if (result.isFailure) {
      emit(AudioPlayerError(FailureMapper.mapToMessage(result.failureOrNull!.failure)));
    }
  }

  Future<void> _onStopAudio(
    StopAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    _logger.d('Stopping audio');
    final result = await _stopAudioUsecase();

    result.fold(
      onSuccess: (_) => emit(const AudioPlayerInitial()),
      onFailure: (failure) {
        emit(AudioPlayerError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onSeekAudio(
    SeekAudio event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    _logger.d('Seeking to: ${event.position.inSeconds}s');
    final result = await _seekAudioUsecase(event.position);

    if (result.isFailure) {
      emit(AudioPlayerError(FailureMapper.mapToMessage(result.failureOrNull!.failure)));
    }
  }

  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeed event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (state is! AudioPlayerReady) return;

    _logger.d('Setting speed to: ${event.speed}x');
    final result = await _setSpeedUsecase(event.speed);

    if (result.isFailure) {
      emit(AudioPlayerError(FailureMapper.mapToMessage(result.failureOrNull!.failure)));
    }
  }

  void _onPlayerStateUpdated(
    PlayerStateUpdated event,
    Emitter<AudioPlayerState> emit,
  ) {
    final currentState = state;
    if (currentState is AudioPlayerReady) {
      final playerState = event.state;
      emit(currentState.copyWith(
        duration: playerState.duration,
        position: playerState.position,
        isPlaying: playerState.isPlaying,
        speed: playerState.speed,
      ));
    }
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    return super.close();
  }
}
```

#### 4. Add Method to AuthenticatedHttpService

**File**: `lib/core/network/authenticated_http_service.dart`

Add method to get auth headers (if not already present):
```dart
/// Get current authentication headers for external use
Future<Map<String, String>> getAuthHeaders() async {
  final token = await _tokenRefresherService.getValidAccessToken();

  if (token == null) {
    throw Exception('No valid access token available');
  }

  return {
    'Authorization': 'Bearer $token',
  };
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] No compilation errors: `flutter analyze`
- [ ] BLoC follows existing patterns from other features

#### Manual Verification:
- [ ] Events are properly sealed with Equatable
- [ ] States include all necessary player information
- [ ] BLoC is registered as LazySingleton
- [ ] Stream subscription is properly managed in close()
- [ ] Error handling uses FailureMapper consistently
- [ ] Auth headers are obtained from AuthenticatedHttpService

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: UI - Player Modal Widget

### Overview
Create the persistent modal bottom sheet player UI with controls and waveform visualization.

### Changes Required

#### 1. Waveform Painter

**File**: `lib/features/audio_player/presentation/widgets/waveform_painter.dart`

```dart
import 'package:flutter/material.dart';

/// Custom painter for audio waveform visualization
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> waveformData;
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final barWidth = size.width / waveformData.length;
    final barGap = barWidth * 0.2;
    final actualBarWidth = barWidth - barGap;
    final midHeight = size.height / 2;

    for (var i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final normalizedValue = waveformData[i].clamp(0.0, 1.0);
      final barHeight = normalizedValue * size.height;

      final isActive = (i / waveformData.length) <= progress;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          midHeight - (barHeight / 2),
          actualBarWidth,
          barHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveformData != waveformData;
  }
}
```

#### 2. Audio Player Modal

**File**: `lib/features/audio_player/presentation/widgets/audio_player_sheet.dart`

```dart
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
          min: 0,
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
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final percentage = localPosition.dx / renderBox.size.width;
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
```

### Success Criteria

#### Automated Verification:
- [ ] No compilation errors: `flutter analyze`
- [ ] UI builds without errors: `flutter build web`

#### Manual Verification:
- [ ] Waveform renders correctly with sample data
- [ ] Player controls are properly laid out
- [ ] Speed selector shows all speed options
- [ ] Slider responds to drag gestures
- [ ] Time indicators display correctly formatted
- [ ] Play/pause button toggles icon appropriately
- [ ] Modal has proper styling and spacing

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Integration - Connect UI to Messages

### Overview
Integrate the audio player with existing message UI by adding play buttons to MessageCard and managing the player modal.

### Changes Required

#### 1. Update MessageCard with Play Button

**File**: `lib/features/dashboard/presentation/components/message_card.dart`

Add play button to message card. Look for the existing structure and add an audio play button:

```dart
// Add this import at the top
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_player_sheet.dart';

// In the MessageCard widget, add a play button for messages with audio
// This would typically go in the row/column with other message actions
IconButton(
  icon: const Icon(Icons.play_circle_outline),
  tooltip: 'Play audio',
  onPressed: message.audioUrl != null && message.audioUrl!.isNotEmpty
      ? () => _handlePlayAudio(context, message)
      : null,
)

// Add this helper method to MessageCard class
void _handlePlayAudio(BuildContext context, MessageUiModel message) {
  if (message.audioUrl == null || message.audioUrl!.isEmpty) return;

  // Get the audio player BLoC
  final audioBloc = context.read<AudioPlayerBloc>();

  // Load audio
  audioBloc.add(LoadAudio(
    messageId: message.id,
    audioUrl: message.audioUrl!,
    waveformData: message.audioModels.isNotEmpty
        ? message.audioModels.first.waveformData
        : [],
  ));

  // Auto-play after loading
  audioBloc.add(const PlayAudio());

  // Show player modal
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (sheetContext) => const AudioPlayerSheet(),
  );
}
```

#### 2. Register AudioPlayerBloc in Provider

**File**: `lib/core/providers/bloc_providers.dart`

Add AudioPlayerBloc to the MultiBlocProvider:

```dart
// Add import
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';

// In the providers list
BlocProvider<AudioPlayerBloc>(
  create: (_) => getIt<AudioPlayerBloc>(),
),
```

#### 3. Update MessageUiModel (if needed)

**File**: `lib/features/messages/presentation/models/message_ui_model.dart`

Ensure audioModels are accessible in MessageUiModel. If not already present, add:

```dart
// Verify this property exists and is accessible
final List<AudioModel> audioModels;
```

**File**: `lib/features/messages/presentation/mappers/message_ui_mapper.dart`

Ensure the mapper includes audioModels:

```dart
// In the toUiModel() extension method, verify audioModels are mapped
audioModels: audioModels,
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] No compilation errors: `flutter analyze`
- [ ] Build succeeds: `flutter build web`

#### Manual Verification:
- [ ] Play button appears on message cards with audio
- [ ] Play button is disabled for messages without audio
- [ ] Clicking play button loads and plays audio
- [ ] Player modal opens automatically when playing
- [ ] Player modal can be closed and reopened
- [ ] Player state persists when modal is closed/reopened
- [ ] Starting playback on a different message stops current playback

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Platform Configuration and Testing

### Overview
Configure platform-specific settings for just_audio and perform comprehensive testing.

### Changes Required

#### 1. Android Configuration

**File**: `android/app/src/main/AndroidManifest.xml`

Add cleartext traffic permission for just_audio's localhost proxy:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
    ...
</application>
```

#### 2. iOS Configuration (if applicable)

**File**: `ios/Runner/Info.plist`

Add background audio modes if needed (though we're not implementing background playback in MVP):

```xml
<!-- Only if background playback is added in future -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

#### 3. Web Configuration

Verify CORS settings on audio server if needed. just_audio on web has limitations with custom headers, but should work with cookie-based auth.

#### 4. Integration Test

**File**: `test/features/audio_player/audio_player_integration_test.dart`

Create basic integration test:

```dart
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Basic test to verify BLoC structure
void main() {
  group('AudioPlayerBloc', () {
    test('initial state is AudioPlayerInitial', () {
      // This test verifies the BLoC can be instantiated
      // Full implementation requires mock setup
    });

    test('LoadAudio event transitions to AudioPlayerLoading then AudioPlayerReady', () async {
      // This test verifies the load flow
      // Full implementation requires mock setup
    });
  });
}
```

### Success Criteria

#### Automated Verification:
- [ ] Android build succeeds: `flutter build apk`
- [ ] Web build succeeds: `flutter build web`
- [ ] Tests run: `flutter test`
- [ ] No analyzer warnings: `flutter analyze`

#### Manual Verification:
- [ ] **Load Audio**: Select a message with audio and click play
  - [ ] Player modal opens
  - [ ] Audio loads (shows loading state briefly)
  - [ ] Playback starts automatically
  - [ ] Waveform renders correctly
  - [ ] Duration displays correctly

- [ ] **Play/Pause Controls**:
  - [ ] Pause button stops playback
  - [ ] Play button resumes playback
  - [ ] Icon toggles between play and pause

- [ ] **Seek Controls**:
  - [ ] Dragging slider seeks to correct position
  - [ ] Clicking waveform seeks to that position
  - [ ] Skip +10s button advances correctly
  - [ ] Skip -10s button rewinds correctly
  - [ ] Position indicator updates in real-time

- [ ] **Speed Control**:
  - [ ] Speed menu shows all options (0.5x to 2.0x)
  - [ ] Selecting speed changes playback rate
  - [ ] Current speed displays correctly

- [ ] **State Persistence**:
  - [ ] Close player modal during playback
  - [ ] Reopen modal (audio still playing)
  - [ ] Position continues from where it was
  - [ ] Controls still work

- [ ] **Multi-Message Playback**:
  - [ ] Start playing message A
  - [ ] Click play on message B
  - [ ] Message A stops, B starts playing
  - [ ] Only one audio plays at a time

- [ ] **Error Handling**:
  - [ ] Try playing message with invalid/missing audio URL
  - [ ] Error state displays with clear message
  - [ ] App doesn't crash

- [ ] **Authentication**:
  - [ ] Audio loads with authentication (check network logs)
  - [ ] Authorization header is present in requests
  - [ ] Playback works for protected audio URLs

- [ ] **Performance**:
  - [ ] Audio streams smoothly without buffering issues
  - [ ] UI remains responsive during playback
  - [ ] Waveform updates don't cause lag

**Implementation Note**: This is the final phase. After all verification passes, the audio player feature is complete and ready for use.

---

## Testing Strategy

### Unit Tests
- **Domain Layer**:
  - PlayerState entity computed properties (progress, remaining)
  - Use case input validation (speed limits, empty URLs)

- **Data Layer**:
  - Repository state transformations
  - Error handling in service methods

- **Presentation Layer**:
  - BLoC event handlers
  - State transitions
  - Error state mapping

### Integration Tests
- Load audio flow: Event → UseCase → Repository → Service
- Playback controls: Play, pause, seek, speed
- State stream updates
- Error propagation

### Manual Testing Steps
1. **Basic Playback**:
   - Click play on message
   - Verify audio plays
   - Verify waveform animates
   - Verify time updates

2. **Seek Testing**:
   - Drag slider to middle
   - Tap waveform at 25% mark
   - Use skip buttons
   - Verify position changes correctly

3. **Speed Testing**:
   - Change to 1.5x speed
   - Verify audio plays faster
   - Change to 0.5x speed
   - Verify audio plays slower

4. **Multi-Message Testing**:
   - Play message 1
   - Play message 2 while 1 is playing
   - Verify only message 2 plays

5. **Error Testing**:
   - Try message with no audio URL
   - Try invalid URL
   - Verify error states display

6. **State Persistence**:
   - Play audio
   - Close modal
   - Reopen modal
   - Verify playback continues

## Performance Considerations

### Streaming Optimization
- just_audio handles buffering automatically
- AudioSource.uri with headers streams efficiently
- No pre-downloading reduces storage usage

### Waveform Rendering
- Waveform data already provided by API
- CustomPainter repaints only on progress change
- Lightweight rendering with shouldRepaint optimization

### Memory Management
- Single AudioPlayer instance (LazySingleton)
- Proper stream subscription cleanup
- Dispose called on BLoC close

### Network Efficiency
- Authenticated headers prevent re-authentication
- Streaming starts playback before full download
- just_audio's localhost proxy handles caching

## Migration Notes

Not applicable - this is a new feature with no existing data or state to migrate.

## References

### Documentation
- just_audio package: https://pub.dev/packages/just_audio
- just_audio GitHub: https://github.com/ryanheise/just_audio
- Flutter BLoC: https://bloclibrary.dev/

### Codebase Patterns
- Message Download Feature: `lib/features/message_download/`
- BLoC Pattern Example: `lib/features/message_download/presentation/bloc/download_bloc.dart`
- Repository Pattern: `lib/features/message_download/data/repositories/download_repository_impl.dart`
- Use Case Pattern: `lib/features/message_download/domain/usecases/download_messages_usecase.dart`

### Related Issues
- Adding Headers to setUrl: https://github.com/ryanheise/just_audio/issues/99
- Authenticated Audio Sources: https://stackoverflow.com/questions/64214710/how-to-fetch-audio-from-my-api-with-protected-urls-using-just-audio-flutter

### API Documentation
- AudioModel entity: `lib/features/messages/domain/entities/audio_model.dart`
- MessageUiModel: `lib/features/messages/presentation/models/message_ui_model.dart`
- AuthenticatedHttpService: `lib/core/network/authenticated_http_service.dart`
