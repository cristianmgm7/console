# Audio Player Pre-Signed URL Support Implementation Plan

## Overview

Add support for fetching pre-signed URLs to play audio messages in the audio player. Currently, the audio player receives a regular URL from the UI and attempts to play it with authentication headers. However, audio playback requires pre-signed URLs similar to the download feature.

## Current State Analysis

### What Exists:
- `AudioPlayerBloc` accepts `LoadAudio` event with `messageId`, `audioUrl`, and `waveformData` ([audio_player_bloc.dart:18](lib/features/audio_player/presentation/bloc/audio_player_bloc.dart#L18), [audio_player_event.dart:11-24](lib/features/audio_player/presentation/bloc/audio_player_event.dart#L11-L24))
- `MessageRepository.getMessage()` supports `includePreSignedUrls` parameter ([message_repository.dart:17](lib/features/messages/domain/repositories/message_repository.dart#L17))
- `AudioModel` entity has `presignedUrl` and `presignedUrlExpiration` fields ([audio_model.dart:8-9](lib/features/messages/domain/entities/audio_model.dart#L8-L9))
- `DownloadAudioMessagesUsecase` successfully fetches pre-signed URLs for downloads ([download_audio_messages_usecase.dart:50](lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart#L50))
- UI (MessageCard) triggers audio playback by passing regular `audioUrl` from MessageUiModel ([message_card.dart:218-222](lib/features/dashboard/presentation/components/message_card.dart#L218-L222))

### What's Missing:
- No use case to fetch pre-signed URL specifically for audio playback
- AudioPlayerBloc manually adds auth headers instead of using pre-signed URLs ([audio_player_bloc.dart:87-90](lib/features/audio_player/presentation/bloc/audio_player_bloc.dart#L87-L90))
- No proper error handling for messages without audio

## Desired End State

### Success Criteria:

#### Automated Verification:
- [x] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] All Dart analysis passes: `flutter analyze`
- [x] Code formatting is correct: `dart format lib/ --set-exit-if-changed`
- [x] All existing tests continue to pass: `flutter test`

#### Manual Verification:
- [ ] Audio player successfully plays audio using pre-signed URLs
- [ ] Error handling works when message has no audio
- [ ] UI shows appropriate error message when playback fails
- [ ] Audio continues to play without authentication issues
- [ ] Both legacy (with audioUrl) and new (messageId-only) flows work

**Implementation Note**: After completing this plan and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful.

## What We're NOT Doing

- No caching of pre-signed URLs (fetch fresh every time)
- No expiration checking or URL refresh logic
- No changes to the audio player service itself
- No changes to the download feature
- No modifications to MessageRepository interface (already supports what we need)
- No UI changes to MessageCard or MessageUiModel

## Implementation Approach

Create a focused use case that fetches the pre-signed URL for a message's audio, then integrate it into the AudioPlayerBloc to replace the manual authentication approach. Support both legacy flow (with audioUrl) and new flow (messageId only) for backwards compatibility.

---

## Phase 1: Create GetAudioPreSignedUrlUsecase

### Overview
Create a new use case in the audio_player feature that fetches a message and extracts its pre-signed audio URL.

### Changes Required:

#### 1. Create Use Case File
**File**: `lib/features/audio_player/domain/usecases/get_audio_presigned_url_usecase.dart`
**Changes**: Create new file with use case implementation

```dart
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case for fetching pre-signed audio URL for playback
@injectable
class GetAudioPreSignedUrlUsecase {
  const GetAudioPreSignedUrlUsecase(
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final Logger _logger;

  /// Fetches the pre-signed URL for a message's audio
  ///
  /// [messageId] - The ID of the message to fetch audio for
  ///
  /// Returns a Result containing the pre-signed URL string on success,
  /// or a Failure if the message has no audio or the fetch fails
  Future<Result<String>> call(String messageId) async {
    try {
      _logger.d('Fetching pre-signed URL for message: $messageId');

      // Fetch message with pre-signed URLs
      final result = await _messageRepository.getMessage(
        messageId,
        includePreSignedUrls: true,
      );

      return result.fold(
        onSuccess: (message) {
          // Check if message has audio
          if (message.audioModels.isEmpty) {
            _logger.w('Message $messageId has no audio models');
            return failure(
              const UnknownFailure(details: 'Message has no audio'),
            );
          }

          // Get the first audio model (typically MP3)
          final audioModel = message.audioModels.first;

          // Check if pre-signed URL exists
          if (audioModel.presignedUrl == null ||
              audioModel.presignedUrl!.isEmpty) {
            _logger.e('Message $messageId audio has no pre-signed URL');
            return failure(
              const UnknownFailure(
                details: 'Audio pre-signed URL not available',
              ),
            );
          }

          _logger.d('Successfully fetched pre-signed URL for message $messageId');
          return success(audioModel.presignedUrl!);
        },
        onFailure: (failure) {
          _logger.e('Failed to fetch message $messageId: ${failure.failureOrNull}');
          return failure;
        },
      );
    } on Exception catch (e, stack) {
      _logger.e(
        'Unexpected error fetching pre-signed URL for message $messageId',
        error: e,
        stackTrace: stack,
      );
      return failure(
        UnknownFailure(details: 'Failed to fetch pre-signed URL: $e'),
      );
    }
  }
}
```

#### 2. Create domain directory structure
**Command**: Create the necessary directory structure for the use case

```bash
mkdir -p lib/features/audio_player/domain/usecases
```

### Success Criteria:

#### Automated Verification:
- [x] File is created at correct path: `lib/features/audio_player/domain/usecases/get_audio_presigned_url_usecase.dart`
- [x] Code generation runs successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No analysis errors: `flutter analyze`
- [x] Formatting is correct: `dart format lib/features/audio_player/domain/usecases/get_audio_presigned_url_usecase.dart`

#### Manual Verification:
- [ ] Use case is registered in dependency injection (check generated `injection.config.dart`)
- [ ] Code follows clean architecture patterns
- [ ] Logging statements are appropriate

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Integrate Use Case into AudioPlayerBloc

### Overview
Modify the AudioPlayerBloc to use the new use case for fetching pre-signed URLs. Support both legacy flow (with audioUrl provided) and new flow (fetch pre-signed URL using messageId).

### Changes Required:

#### 1. Update AudioPlayerBloc Constructor
**File**: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
**Changes**: Inject the new use case

```dart
@LazySingleton()
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  AudioPlayerBloc(
    this._playerService,
    this._authService,
    this._logger,
    this._getAudioPreSignedUrlUsecase, // Add this
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
  final AuthenticatedHttpService _authService;
  final Logger _logger;
  final GetAudioPreSignedUrlUsecase _getAudioPreSignedUrlUsecase; // Add this
```

#### 2. Add Import Statement
**File**: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
**Changes**: Import the new use case

Add at top of file:
```dart
import 'package:carbon_voice_console/features/audio_player/domain/usecases/get_audio_presigned_url_usecase.dart';
```

#### 3. Update _onLoadAudio Method
**File**: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
**Changes**: Replace the existing `_onLoadAudio` method (lines 69-106) with new implementation

```dart
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

    // Determine which URL to use
    String audioUrl;

    if (event.audioUrl != null && event.audioUrl!.isNotEmpty) {
      // Legacy flow: Use provided URL
      _logger.d('Using provided audio URL (legacy flow)');
      audioUrl = event.audioUrl!;
    } else {
      // New flow: Fetch pre-signed URL using use case
      _logger.d('Fetching pre-signed URL for message ${event.messageId}');

      final result = await _getAudioPreSignedUrlUsecase(event.messageId);

      final fetchedUrl = result.fold(
        onSuccess: (url) => url,
        onFailure: (failure) {
          final errorMessage = failure.failureOrNull?.details ??
                               'Failed to fetch audio URL';
          _logger.e('Failed to get pre-signed URL: $errorMessage');
          emit(AudioPlayerError(errorMessage));
          return null;
        },
      );

      if (fetchedUrl == null) {
        // Error already emitted in fold
        return;
      }

      audioUrl = fetchedUrl;
    }

    _currentAudioUrl = audioUrl;

    // For pre-signed URLs, no auth headers needed
    // For regular URLs, add auth headers (legacy support)
    final Map<String, String> headers;
    if (audioUrl.contains('X-Amz-Algorithm') ||
        audioUrl.contains('Signature')) {
      // Pre-signed URL - no auth headers needed
      _logger.d('Using pre-signed URL, no auth headers required');
      headers = {};
    } else {
      // Regular URL - add auth headers
      _logger.d('Using regular URL, adding auth headers');
      headers = await _authService.getAuthHeaders();
    }

    // Load audio
    await _playerService.loadAudio(audioUrl, headers);

    // Emit ready state
    emit(AudioPlayerReady(
      messageId: _currentMessageId!,
      audioUrl: _currentAudioUrl!,
      duration: _playerService.duration ?? Duration.zero,
      position: _playerService.position,
      isPlaying: _playerService.isPlaying,
      speed: _currentSpeed,
      waveformData: _currentWaveformData,
    ));
  } on Exception catch (e) {
    _logger.e('Failed to load audio', error: e);
    emit(AudioPlayerError('Failed to load audio: $e'));
  }
}
```

#### 4. Update LoadAudio Event (Make audioUrl Optional)
**File**: `lib/features/audio_player/presentation/bloc/audio_player_event.dart`
**Changes**: Make `audioUrl` parameter optional (line 11-24)

```dart
/// Load and prepare audio for playback
class LoadAudio extends AudioPlayerEvent {
  const LoadAudio({
    required this.messageId,
    this.audioUrl, // Remove 'required'
    required this.waveformData,
  });

  final String messageId;
  final String? audioUrl; // Make nullable
  final List<double> waveformData;

  @override
  List<Object?> get props => [messageId, audioUrl, waveformData];
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No analysis errors: `flutter analyze`
- [x] Code formatting is correct: `dart format lib/features/audio_player/`
- [x] Existing audio player tests pass (if any): `flutter test`

#### Manual Verification:
- [ ] Play audio using legacy flow (with audioUrl provided) - should work as before
- [ ] Play audio using new flow (without audioUrl) - should fetch pre-signed URL
- [ ] Error message displays correctly when message has no audio
- [ ] Error message displays correctly when API call fails
- [ ] Audio playback works smoothly with pre-signed URLs
- [ ] No authentication errors during playback

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Update UI to Use New Flow (Optional)

### Overview
Update the MessageCard to use the new messageId-only flow instead of passing audioUrl. This is optional and can be done later, as the backwards compatibility ensures existing code continues to work.

### Changes Required:

#### 1. Simplify _handlePlayAudio Method
**File**: `lib/features/dashboard/presentation/components/message_card.dart`
**Changes**: Update the play audio handler (lines 211-234)

```dart
void _handlePlayAudio(BuildContext context, MessageUiModel message) {
  if (!message.hasPlayableAudio) return;

  // Get the audio player BLoC
  final audioBloc = context.read<AudioPlayerBloc>();

  // Load audio - let the BLoC fetch the pre-signed URL
  audioBloc.add(LoadAudio(
    messageId: message.id,
    // audioUrl: message.audioUrl, // Remove this - let BLoC fetch it
    waveformData: message.playableAudioModel?.waveformData ?? [],
  ));

  // Auto-play after loading
  audioBloc.add(const PlayAudio());

  // Show player modal
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const AudioPlayerSheet(),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [x] No analysis errors: `flutter analyze`
- [x] Code formatting is correct: `dart format lib/features/dashboard/presentation/components/message_card.dart`

#### Manual Verification:
- [ ] Click play button on message card
- [ ] Audio player sheet opens correctly
- [ ] Audio loads and plays successfully
- [ ] Waveform displays correctly
- [ ] Error handling works for messages without audio
- [ ] Loading state displays while fetching pre-signed URL

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful.

---

## Testing Strategy

### Unit Tests

Create test file: `test/features/audio_player/domain/usecases/get_audio_presigned_url_usecase_test.dart`

**Test Cases:**
- ✅ Returns pre-signed URL when message has audio with pre-signed URL
- ✅ Returns failure when message has no audio models
- ✅ Returns failure when audio model has no pre-signed URL
- ✅ Returns failure when repository call fails
- ✅ Handles exceptions gracefully

**BLoC Tests:**
- ✅ LoadAudio with audioUrl uses provided URL (legacy flow)
- ✅ LoadAudio without audioUrl fetches pre-signed URL (new flow)
- ✅ Emits error when use case fails
- ✅ Uses correct headers for pre-signed vs regular URLs

### Integration Tests

**Manual Testing Steps:**

1. **Test New Flow (No audioUrl provided):**
   - Navigate to dashboard
   - Select a message with audio
   - Click play button
   - Verify: Audio loads and plays successfully
   - Verify: No authentication errors in logs

2. **Test Legacy Flow (With audioUrl):**
   - Ensure backwards compatibility
   - Test any code paths that still pass audioUrl
   - Verify: Audio plays correctly

3. **Test Error Handling:**
   - Try playing a message without audio
   - Verify: Error message displays clearly
   - Verify: App doesn't crash

4. **Test Edge Cases:**
   - Test with expired pre-signed URLs (manually wait if needed)
   - Test with network errors
   - Test rapid play/pause/stop actions
   - Test switching between messages quickly

## Performance Considerations

- **API Calls**: Each playback will make an API call to fetch the message with pre-signed URL. This is acceptable for now as caching is not implemented.
- **Pre-signed URL Expiration**: URLs are fetched fresh each time, so expiration is not a concern during a single playback session.
- **Network Latency**: There will be a slight delay before playback starts while fetching the pre-signed URL. Consider adding loading state indication in UI.

## Migration Notes

- **Backwards Compatibility**: The `LoadAudio` event still accepts optional `audioUrl`, so existing code continues to work.
- **Gradual Migration**: Can migrate UI components one at a time to use messageId-only flow.
- **No Database Changes**: All changes are at the application layer.
- **No Breaking Changes**: Existing functionality remains intact.

## Future Enhancements (Out of Scope)

- Caching pre-signed URLs with expiration tracking
- Automatic URL refresh when expired
- Prefetching pre-signed URLs for visible messages
- Background pre-loading of audio for smoother playback
- Retry logic for failed API calls

## References

- MessageRepository interface: [message_repository.dart](lib/features/messages/domain/repositories/message_repository.dart)
- AudioModel entity: [audio_model.dart](lib/features/messages/domain/entities/audio_model.dart)
- Download use case (similar pattern): [download_audio_messages_usecase.dart](lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart)
- AudioPlayerBloc: [audio_player_bloc.dart](lib/features/audio_player/presentation/bloc/audio_player_bloc.dart)
- MessageCard UI: [message_card.dart](lib/features/dashboard/presentation/components/message_card.dart)
