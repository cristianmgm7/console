# Mini Audio Player UX Improvement Implementation Plan

## Overview

Transform the current blocking modal bottom sheet audio player into a persistent Spotify-like mini player that appears in the content area, allowing users to continue navigating and using the app while audio plays. This improves the user experience by removing workflow interruptions while maintaining full playback control.

## Current State Analysis

### Existing Infrastructure
- **AudioPlayerBloc**: App-level BLoC with complete playback state management
- **AudioPlayerSheet**: Modal bottom sheet that blocks entire UI workflow
- **MiniAudioPlayer**: Standalone component (not BLoC-integrated) with basic playback controls
- **Content Stacks**: Both dashboard and voice memos use Stack pattern with action panels

### Key Findings
- AudioPlayerBloc is provided at app level, ensuring playback persistence across navigation
- Dashboard and voice memos both use `Stack` with `Positioned` action panels at bottom
- Current flow: Play button → Show modal bottom sheet → Blocks all interaction
- MiniAudioPlayer exists but lacks BLoC integration and advanced features

### What We're NOT Doing
- Changing the underlying audio playback architecture
- Modifying the AudioPlayerBloc or service layer
- Altering the action panel functionality or positioning

## Desired End State

A seamless audio experience where:
1. Users click play on any message/voice memo
2. A compact mini player appears in the content area (not blocking navigation)
3. Users can continue browsing, selecting items, and using other features
4. Mini player shows playback progress, controls, and can be manually dismissed
5. Playback automatically stops when switching to different audio content
6. Mini player auto-dismisses when playback completes

### Key User Flows
1. **Play Audio**: Click play → Mini player appears in content stack → Audio starts
2. **Navigate While Playing**: Browse other content → Mini player remains visible → Continue playback
3. **Manual Dismiss**: Click X button → Mini player disappears → Playback continues in background
4. **Auto Dismiss**: Playback completes → Mini player disappears automatically
5. **Switch Audio**: Play different audio → Previous mini player disappears → New mini player appears

## Implementation Approach

Create a BLoC-integrated mini player that replaces the modal bottom sheet, appearing in the existing content stack pattern used by action panels.

## Phase 1: Create BLoC-Integrated Mini Player Widget

### Overview
Build a new `AudioMiniPlayerWidget` that integrates with `AudioPlayerBloc` and provides the same functionality as the current bottom sheet but in a compact, non-blocking format.

### Changes Required:

#### 1. Create New Mini Player Widget
**File**: `lib/features/audio_player/presentation/widgets/audio_mini_player_widget.dart`
**Changes**: New file implementing a compact audio player widget

```dart
class AudioMiniPlayerWidget extends StatelessWidget {
  const AudioMiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        return switch (state) {
          AudioPlayerReady() => _MiniPlayerContent(state: state),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  // Implementation with play/pause, progress bar, speed control, dismiss button
}
```

### Success Criteria:

#### Automated Verification:
- [x] Widget compiles without errors: `flutter build`
- [ ] Unit tests pass for new widget: `flutter test`
- [x] BLoC integration works: Audio state changes update widget
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [ ] Widget appears when AudioPlayerReady state is active
- [ ] Play/pause controls work correctly
- [ ] Progress bar shows current position and allows seeking
- [ ] Speed control changes playback speed
- [ ] Dismiss button removes widget and stops playback

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the mini player widget works correctly before proceeding to integration.

---

## Phase 2: Integrate Mini Player in Dashboard

### Overview
Replace the modal bottom sheet in the dashboard with the new mini player widget in the content stack.

### Changes Required:

#### 1. Update Dashboard Content Stack
**File**: `lib/features/dashboard/presentation/components/content_dashboard.dart`
**Changes**: Replace bottom sheet modal with mini player in stack

```dart
@override
Widget build(BuildContext context) {
  return AppContainer(
    backgroundColor: AppColors.surface,
    child: Stack(
      children: [
        // Main content (unchanged)
        BlocBuilder<MessageBloc, MessageState>(
          builder: (context, messageState) {
            return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                return _buildContent(context, messageState, audioState);
              },
            );
          },
        ),

        // Action panel - only show when messages are selected
        if (selectedMessages.isNotEmpty && onDownloadAudio != null)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(child: MessagesActionPanel(...)),
          ),

        // NEW: Mini player - show when audio is ready
        Positioned(
          bottom: selectedMessages.isNotEmpty ? 100 : 24, // Above action panel if present
          left: 24,
          right: 24,
          child: const AudioMiniPlayerWidget(),
        ),
      ],
    ),
  );
}
```

#### 2. Remove Bottom Sheet Logic
**File**: `lib/features/dashboard/presentation/components/content_dashboard.dart`
**Changes**: Remove `showModalBottomSheet` call from `_handlePlayAudio`

```dart
Future<void> _handlePlayAudio(BuildContext context, MessageUiModel message) async {
  if (!message.hasPlayableAudio || message.audioUrl == null) return;

  // Get the audio player BLoC
  final audioBloc = context.read<AudioPlayerBloc>();

  // Load audio - let the BLoC fetch the pre-signed URL
  audioBloc.add(
    LoadAudio(
      messageId: message.id,
      waveformData: message.playableAudioModel?.waveformData ?? [],
    ),
  );

  // Auto-play after loading (no modal shown)
  audioBloc.add(const PlayAudio());
}
```

### Success Criteria:

#### Automated Verification:
- [x] Dashboard compiles without errors: `flutter build`
- [x] No references to AudioPlayerSheet in dashboard: `grep -r AudioPlayerSheet lib/features/dashboard/`
- [ ] Unit tests pass: `flutter test`

#### Manual Verification:
- [ ] Clicking play on message shows mini player instead of bottom sheet
- [ ] Mini player appears above action panel when messages selected
- [ ] Audio plays immediately without blocking UI
- [ ] Can navigate dashboard while audio plays
- [ ] Mini player controls work correctly

---

## Phase 3: Integrate Mini Player in Voice Memos

### Overview
Apply the same integration pattern to voice memos screen.

### Changes Required:

#### 1. Update Voice Memos Content Stack
**File**: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
**Changes**: Add mini player to stack, similar to dashboard

```dart
@override
Widget build(BuildContext context) {
  return AppContainer(
    backgroundColor: AppColors.surface,
    child: BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, downloadState) { ... },
      builder: (context, downloadState) {
        return Stack(
          children: [
            BlocBuilder<VoiceMemoBloc, VoiceMemoState>(
              builder: _buildContent,
            ),

            // Floating Action Panel
            if (_selectedVoiceMemos.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(child: MessagesActionPanel(...)),
              ),

            // NEW: Mini player - show when audio is ready
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, audioState) {
                final bottomOffset = _selectedVoiceMemos.isNotEmpty ? 100 : 24;
                return Positioned(
                  bottom: bottomOffset,
                  left: 24,
                  right: 24,
                  child: const AudioMiniPlayerWidget(),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
```

#### 2. Implement Voice Memo Playback
**File**: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
**Changes**: Add playback logic to voice memo play button

```dart
// In the table row for voice memos
if (voiceMemo.hasPlayableAudio)
  AppIconButton(
    icon: AppIcons.play,
    tooltip: 'Play audio',
    onPressed: () {
      // TODO: Implement audio playback for voice memos
      final audioBloc = context.read<AudioPlayerBloc>();
      // Load voice memo audio (similar to message logic)
      audioBloc.add(LoadAudio(
        messageId: voiceMemo.id, // Assuming voice memos have compatible ID
        waveformData: voiceMemo.waveformData ?? [],
      ));
      audioBloc.add(const PlayAudio());
    },
    size: AppIconButtonSize.small,
  )
```

### Success Criteria:

#### Automated Verification:
- [x] Voice memos screen compiles: `flutter build`
- [ ] No breaking changes to existing functionality: `flutter test`

#### Manual Verification:
- [ ] Voice memo play buttons trigger mini player
- [ ] Mini player appears correctly in voice memos stack
- [ ] Position adjusts based on action panel visibility
- [ ] Audio playback works for voice memos

---

## Phase 4: Add Auto-Dismissal Logic

### Overview
Implement automatic dismissal of the mini player when playback completes, and ensure proper cleanup.

### Changes Required:

#### 1. Update AudioPlayerBloc for Completion Handling
**File**: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
**Changes**: Add completion detection and auto-dismissal

```dart
// In _subscribeToServiceStreams method
void _subscribeToServiceStreams() {
  // Existing subscriptions...
  
  // NEW: Listen for playback completion
  _playerService.playbackCompleteStream.listen((_) {
    _logger.d('Playback completed, resetting to initial state');
    add(const StopAudio()); // This will emit AudioPlayerInitial
  });
}
```

#### 2. Ensure Mini Player Shows Only When Active
**File**: `lib/features/audio_player/presentation/widgets/audio_mini_player_widget.dart`
**Changes**: Only show when AudioPlayerReady state

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
    builder: (context, state) {
      return switch (state) {
        AudioPlayerReady() => _MiniPlayerContent(state: state),
        _ => const SizedBox.shrink(), // Hide when not ready
      };
    },
  );
}
```

### Success Criteria:

#### Automated Verification:
- [x] Completion stream integration works: Unit tests pass
- [ ] State transitions work correctly: `flutter test`

#### Manual Verification:
- [ ] Mini player disappears when playback completes
- [ ] No memory leaks or hanging subscriptions
- [ ] Manual dismiss button works correctly

---

## Testing Strategy

### Unit Tests:
- Test mini player widget renders correctly for each state
- Test BLoC integration and state updates
- Test completion detection and auto-dismissal
- Test position adjustments with action panels

### Integration Tests:
- Test dashboard integration: Play message → Mini player appears → Navigate → Still playing
- Test voice memos integration: Same flow as dashboard
- Test action panel interaction: Select items → Mini player repositions correctly

### Manual Testing Steps:
1. [ ] Play audio from dashboard message → Mini player appears, audio starts
2. [ ] Navigate between dashboard sections while playing → Mini player persists
3. [ ] Select messages while playing → Mini player moves above action panel
4. [ ] Click dismiss button → Mini player disappears, playback stops
5. [ ] Let playback complete → Mini player auto-dismisses
6. [ ] Play voice memo → Mini player appears in voice memos screen
7. [ ] Switch between dashboard and voice memos while playing → Playback continues
8. [ ] Test on different screen sizes → Mini player positioning works

## Performance Considerations

- Mini player only renders when AudioPlayerBloc is in Ready state
- BLoC subscriptions are properly managed and cancelled
- No additional rebuilds triggered by audio position updates (use streams efficiently)
- Memory cleanup when mini player is dismissed

## Migration Notes

- Existing audio URLs and authentication flow remain unchanged
- No database changes required
- Backward compatibility maintained for any existing bottom sheet usage
- Gradual rollout: Can keep bottom sheet as fallback during transition

## References

- Current AudioPlayerSheet implementation: `lib/features/audio_player/presentation/widgets/audio_player_sheet.dart`
- Dashboard content structure: `lib/features/dashboard/presentation/components/content_dashboard.dart`
- Voice memos structure: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
- AudioPlayerBloc: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
