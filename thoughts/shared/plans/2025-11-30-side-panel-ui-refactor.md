# Side Panel UI Refactor - Replace Bottom Sheets with Dashboard Panels

## Overview

Replace modal bottom sheets for downloads and audio playback with persistent side panels in the dashboard. This provides a non-blocking, Gmail-style UX where multiple operations (downloads, audio playback, message details) can be visible simultaneously in a layered panel system on the right side of the dashboard.

## Current State Analysis

### Existing Bottom Sheet Implementations:
1. **DownloadProgressSheet** ([download_progress_sheet.dart:12](lib/features/message_download/presentation/widgets/download_progress_sheet.dart#L12))
   - Modal bottom sheet that blocks UI interaction
   - Shows download progress, counts, and cancel button
   - Auto-dismisses on completion/cancellation

2. **AudioPlayerSheet** ([audio_player_sheet.dart:13](lib/features/audio_player/presentation/widgets/audio_player_sheet.dart#L13))
   - Modal bottom sheet for audio controls
   - Includes waveform visualization, playback controls, speed adjustment
   - Dismisses when stopped

### Existing Panel Pattern:
- **MessageDetailPanel** ([message_detail_panel.dart:11](lib/features/messages/presentation/components/message_detail_panel.dart#L11))
  - Fixed 400px width
  - Shows on right side of dashboard
  - Uses AppContainer with left border styling
  - Managed via Stack in DashboardScreen

### Current Trigger Points:
- **Downloads**: [dashboard_screen.dart:198-207](lib/features/dashboard/presentation/dashboard_screen.dart#L198-L207) (audio), [dashboard_screen.dart:231-240](lib/features/dashboard/presentation/dashboard_screen.dart#L231-L240) (transcripts)
- **Audio Playback**: [content_dashboard.dart:52-75](lib/features/dashboard/presentation/components/content_dashboard.dart#L52-L75), [message_card.dart:210-233](lib/features/dashboard/presentation/components/message_card.dart#L210-L233)

## Desired End State

A layered panel system on the right side of the dashboard with:

1. **Download Panel** (Right-most position)
   - Circular progress indicators with percentage (like file transfers)
   - Supports multiple simultaneous downloads
   - Auto-dismisses after 3-5 seconds on completion
   - Can be manually dismissed
   - Animated slide-in/out

2. **Audio Player Panel** (Center-right position)
   - Full controls when focused
   - Compact "now playing" bar when not focused
   - Positioned slightly lower than message detail to avoid overlap
   - Persists when navigating between messages
   - Closes when new audio is played (only one audio at a time)
   - Animated transitions between focused/compact states

3. **Message Detail Panel** (Existing, center-right)
   - Remains as-is
   - Works alongside new panels

### Panel Layout (when all 3 are open):
```
Dashboard Content (Left)    |  Message Detail (Center-Right)  |  Download (Right-most)
                            |                                  |
                            |  Audio Player (Below detail,     |
                            |  center-right, compact mode)      |
```

### Success Criteria:

#### Automated Verification:
- [ ] All existing tests pass: `flutter test`
- [ ] No linting errors: `flutter analyze`
- [ ] Code generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] App builds successfully: `flutter build web`
- [ ] Hot reload works without errors: `flutter run -d chrome`

#### Manual Verification:
- [ ] Download panel appears on right side when download starts
- [ ] Multiple downloads show separate circular progress indicators
- [ ] Download panel auto-dismisses 3-5 seconds after completion
- [ ] Audio player appears in compact mode when playing
- [ ] Audio player expands to full controls when clicked
- [ ] Audio player collapses to compact mode when focus is lost
- [ ] Only one audio plays at a time (new audio stops previous)
- [ ] Audio player persists when navigating to different messages
- [ ] All three panels can be visible simultaneously
- [ ] Panels have smooth slide-in/out animations
- [ ] No UI blocking or modal overlays
- [ ] Panels have consistent styling with MessageDetailPanel

## What We're NOT Doing

- Not implementing queue management for audio playback
- Not adding playlist functionality
- Not implementing download history/archive
- Not changing the message selection/action panel behavior
- Not modifying the existing MessageDetailPanel implementation
- Not implementing panel resizing or drag-to-reposition
- Not adding desktop notifications for completed downloads

## Implementation Approach

Use a centralized panel orchestration system within DashboardScreen that manages multiple side panels via a Stack-based layout. Each panel will be a self-contained widget that responds to BLoC state and can be shown/hidden with animations.

---

## Phase 1: Create Panel Infrastructure

### Overview
Build the foundational panel system that will manage multiple side panels with animations and proper layering.

### Changes Required:

#### 1. Create Panel Orchestration Widget
**File**: `lib/features/dashboard/presentation/components/dashboard_panels.dart`
**Changes**: Create new file

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/download_panel.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/audio_player_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation/components/message_detail_panel.dart';

/// Orchestrates all side panels in the dashboard
class DashboardPanels extends StatelessWidget {
  const DashboardPanels({
    required this.selectedMessageForDetail,
    required this.onCloseDetail,
    super.key,
  });

  final String? selectedMessageForDetail;
  final VoidCallback onCloseDetail;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Download Panel (Right-most)
        BlocBuilder<DownloadBloc, DownloadState>(
          builder: (context, state) {
            final showDownloadPanel = state is DownloadInProgress ||
                                       state is DownloadCompleted ||
                                       state is DownloadCancelled;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              right: showDownloadPanel ? 0 : -350, // Slide from right
              bottom: 0,
              width: 320,
              child: const DownloadPanel(),
            );
          },
        ),

        // Message Detail Panel (Center-right)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          right: selectedMessageForDetail != null ? 320 : -400, // Offset by download panel width
          height: double.infinity,
          width: 400,
          child: selectedMessageForDetail != null
              ? MessageDetailPanel(
                  messageId: selectedMessageForDetail!,
                  onClose: onCloseDetail,
                )
              : const SizedBox.shrink(),
        ),

        // Audio Player Panel (Center-right, below detail)
        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            final showAudioPanel = state is AudioPlayerReady || state is AudioPlayerLoading;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: selectedMessageForDetail != null ? 420 : 80, // Position below detail if present
              right: showAudioPanel ? 320 : -420, // Offset by download panel width
              width: 400,
              child: const AudioPlayerPanel(),
            );
          },
        ),
      ],
    );
  }
}
```

#### 2. Create Base Panel Container Widget
**File**: `lib/features/dashboard/presentation/components/base_panel.dart`
**Changes**: Create new file

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';

/// Base container for all dashboard side panels
class BasePanel extends StatelessWidget {
  const BasePanel({
    required this.child,
    this.width = 320,
    this.showBorder = true,
    super.key,
  });

  final Widget child;
  final double width;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppContainer(
        backgroundColor: AppColors.surface,
        border: showBorder
            ? const Border(
                left: BorderSide(color: AppColors.border),
              )
            : null,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
```

#### 3. Update DashboardScreen to Use Panel Orchestration
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Integrate DashboardPanels into the Stack layout

Replace the current panel logic (lines 308-350) with:

```dart
Widget _buildDashboardWithPanels() {
  return SizedBox.expand(
    child: Column(
      children: [
        // App Bar - full width at top
        DashboardAppBar(
          onRefresh: _onRefresh,
        ),

        // Main content area with panels
        Expanded(
          child: Stack(
            children: [
              // Left side: Message list area (full width)
              BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
                selector: (state) => state is MessageLoaded ? state : null,
                builder: (context, messageState) {
                  return DashboardContent(
                    isAnyBlocLoading: _isAnyBlocLoading,
                    scrollController: _scrollController,
                    selectedMessages: _selectedMessages,
                    onToggleMessageSelection: _toggleMessageSelection,
                    onToggleSelectAll: _toggleSelectAll,
                    selectAll: _selectAll,
                    onViewDetail: _onViewDetail,
                  );
                },
              ),

              // Right side: All panels (orchestrated)
              DashboardPanels(
                selectedMessageForDetail: _selectedMessageForDetail,
                onCloseDetail: _onCloseDetail,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

And update the build method to use the new layout:

```dart
@override
Widget build(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Stack(
      children: [
        _buildDashboardWithPanels(), // Replace both _buildFullDashboard and _buildDashboardWithDetail

        // Floating Action Panel - only show when no detail is selected
        if (_selectedMessages.isNotEmpty && _selectedMessageForDetail == null)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: MessagesActionPanel(
                selectedCount: _selectedMessages.length,
                onDownloadAudio: _handleDownloadAudio,
                onDownloadTranscript: _handleDownloadTranscript,
                onSummarize: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Summarizing ${_selectedMessages.length} messages...'),
                    ),
                  );
                },
                onAIChat: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening AI chat for ${_selectedMessages.length} messages...'),
                    ),
                  );
                },
              ),
            ),
          ),

        // Error listeners
        _buildErrorListeners(),
      ],
    ),
  );
}
```

#### 4. Extract Download Handlers
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Extract download logic into methods (replace showModalBottomSheet calls)

```dart
void _handleDownloadAudio() {
  if (_selectedMessages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No messages selected'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final messagesToDownload = Set<String>.from(_selectedMessages);

  setState(() {
    _selectedMessages.clear();
    _selectAll = false;
  });

  // Trigger download via existing BLoC (no bottom sheet)
  context.read<DownloadBloc>().add(StartDownloadAudio(messagesToDownload));
}

void _handleDownloadTranscript() {
  if (_selectedMessages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No messages selected'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final messagesToDownload = Set<String>.from(_selectedMessages);

  setState(() {
    _selectedMessages.clear();
    _selectAll = false;
  });

  // Trigger download via existing BLoC (no bottom sheet)
  context.read<DownloadBloc>().add(StartDownloadTranscripts(messagesToDownload));
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] No import errors after adding new files
- [x] Build runner succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] App runs without runtime errors: `flutter run -d chrome`

#### Manual Verification:
- [ ] Dashboard loads without errors
- [ ] Panel infrastructure renders (even if empty)
- [ ] No visual regressions in existing dashboard layout
- [ ] Message detail panel still works as before
- [ ] Animations are smooth when panels appear/disappear

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the basic infrastructure works before proceeding to Phase 2.

---

## Phase 2: Implement Download Panel

### Overview
Convert the download bottom sheet into a side panel with circular progress indicators and auto-dismiss functionality.

### Changes Required:

#### 1. Create Download Panel Widget
**File**: `lib/features/dashboard/presentation/components/download_panel.dart`
**Changes**: Create new file

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/base_panel.dart';

/// Side panel showing download progress with circular indicators
class DownloadPanel extends StatefulWidget {
  const DownloadPanel({super.key});

  @override
  State<DownloadPanel> createState() => _DownloadPanelState();
}

class _DownloadPanelState extends State<DownloadPanel> {
  Timer? _autoDismissTimer;

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoDismiss(DownloadState state) {
    // Cancel any existing timer
    _autoDismissTimer?.cancel();

    // Schedule auto-dismiss for completed/cancelled states
    if (state is DownloadCompleted || state is DownloadCancelled) {
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          // Reset BLoC to initial state (hides panel)
          context.read<DownloadBloc>().add(const ResetDownload());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, state) {
        _scheduleAutoDismiss(state);
      },
      builder: (context, state) {
        if (state is DownloadInitial) {
          return const SizedBox.shrink();
        }

        return BasePanel(
          width: 320,
          child: Column(
            children: [
              // Header
              AppContainer(
                padding: const EdgeInsets.all(16),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.download, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Downloads',
                      style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    if (state is DownloadInProgress)
                      AppIconButton(
                        icon: AppIcons.close,
                        onPressed: () {
                          context.read<DownloadBloc>().add(const CancelDownload());
                        },
                        tooltip: 'Cancel',
                        size: AppIconButtonSize.small,
                      )
                    else
                      AppIconButton(
                        icon: AppIcons.close,
                        onPressed: () {
                          _autoDismissTimer?.cancel();
                          context.read<DownloadBloc>().add(const ResetDownload());
                        },
                        tooltip: 'Close',
                        size: AppIconButtonSize.small,
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(DownloadState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: switch (state) {
        DownloadInProgress() => _buildInProgress(state),
        DownloadCompleted() => _buildCompleted(state),
        DownloadCancelled() => _buildCancelled(state),
        DownloadError() => _buildError(state),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildInProgress(DownloadInProgress state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular progress indicator with percentage
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: state.progressPercent / 100,
                strokeWidth: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${state.progressPercent.toStringAsFixed(0)}%',
                  style: AppTextStyle.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${state.current} / ${state.total}',
                  style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Downloading files...',
          style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCompleted(DownloadCompleted state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.checkCircle, color: AppColors.primary, size: 64),
        const SizedBox(height: 16),
        Text(
          'Download Complete',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.successCount} successful',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        if (state.failureCount > 0)
          Text(
            '${state.failureCount} failed',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
          ),
        if (state.skippedCount > 0)
          Text(
            '${state.skippedCount} skipped',
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildCancelled(DownloadCancelled state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.cancel, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          'Download Cancelled',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Completed ${state.completedCount} of ${state.totalCount}',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildError(DownloadError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.error, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          'Error',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          state.message,
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
```

#### 2. Add ResetDownload Event
**File**: `lib/features/message_download/presentation/bloc/download_event.dart`
**Changes**: Add new event for resetting the download state

```dart
/// Reset download state to initial (for hiding panel)
class ResetDownload extends DownloadEvent {
  const ResetDownload();
}
```

#### 3. Handle ResetDownload Event in BLoC
**File**: `lib/features/message_download/presentation/bloc/download_bloc.dart`
**Changes**: Add event handler in constructor

```dart
on<ResetDownload>(_onResetDownload);
```

And add the handler method:

```dart
Future<void> _onResetDownload(
  ResetDownload event,
  Emitter<DownloadState> emit,
) async {
  emit(const DownloadInitial());
}
```

#### 4. Remove Bottom Sheet Imports from DashboardScreen
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Remove unused imports

Remove:
```dart
import 'package:carbon_voice_console/features/message_download/presentation/widgets/download_progress_sheet.dart';
```

Also remove the `unawaited` import and `showModalBottomSheet` calls (already done in Phase 1).

### Success Criteria:

#### Automated Verification:
- [x] All tests pass: `flutter test`
- [x] No linting errors: `flutter analyze`
- [x] App builds successfully: `flutter build web`
- [x] Hot reload works: `flutter run -d chrome`

#### Manual Verification:
- [ ] Download panel appears on the right when download starts
- [ ] Circular progress shows percentage correctly
- [ ] Download counts update in real-time
- [ ] Panel shows completion state with success/failure counts
- [ ] Panel auto-dismisses 4 seconds after completion
- [ ] Cancel button works during download
- [ ] Close button works on completed/error states
- [ ] Panel slides in/out smoothly
- [ ] Multiple downloads can run (though UI shows combined progress)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that downloads work correctly in the panel before proceeding to Phase 3.

---

## Phase 3: Implement Audio Player Panel

### Overview
Convert the audio player bottom sheet into a side panel with focus/compact states and persistence across navigation.

### Changes Required:

#### 1. Create Audio Player Panel Widget
**File**: `lib/features/dashboard/presentation/components/audio_player_panel.dart`
**Changes**: Create new file

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/waveform_painter.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/base_panel.dart';

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
```

#### 2. Add Missing Icons
**File**: `lib/core/theme/app_icons.dart`
**Changes**: Add minimize icon if not present

```dart
static const IconData minimize = Icons.minimize;
```

#### 3. Update Audio Playback Triggers
**File**: `lib/features/dashboard/presentation/components/content_dashboard.dart`
**Changes**: Remove showModalBottomSheet call

Replace the `_handlePlayAudio` method (lines 52-75) with:

```dart
Future<void> _handlePlayAudio(BuildContext context, MessageUiModel message) async {
  if (!message.hasPlayableAudio || message.audioUrl == null) return;

  // Get the audio player BLoC
  final audioBloc = context.read<AudioPlayerBloc>();

  // Stop any currently playing audio (ensure only one audio at a time)
  audioBloc.add(const StopAudio());

  // Load new audio - let the BLoC fetch the pre-signed URL
  audioBloc.add(
    LoadAudio(
      messageId: message.id,
      waveformData: message.playableAudioModel?.waveformData ?? [],
    ),
  );

  // Auto-play after loading
  audioBloc.add(const PlayAudio());

  // Panel will appear automatically via DashboardPanels
}
```

#### 4. Update Message Card Audio Playback
**File**: `lib/features/dashboard/presentation/components/message_card.dart`
**Changes**: Remove showModalBottomSheet call

Replace the `_handlePlayAudio` method (lines 210-233) with:

```dart
void _handlePlayAudio(BuildContext context, MessageUiModel message) {
  if (!message.hasPlayableAudio) return;

  // Get the audio player BLoC
  final audioBloc = context.read<AudioPlayerBloc>();

  // Stop any currently playing audio (ensure only one audio at a time)
  audioBloc.add(const StopAudio());

  // Load new audio - let the BLoC fetch the pre-signed URL
  audioBloc.add(
    LoadAudio(
      messageId: message.id,
      waveformData: message.playableAudioModel?.waveformData ?? [],
    ),
  );

  // Auto-play after loading
  audioBloc.add(const PlayAudio());

  // Panel will appear automatically via DashboardPanels
}
```

#### 5. Remove Bottom Sheet Imports
**File**: `lib/features/dashboard/presentation/components/content_dashboard.dart`
**Changes**: Remove unused import

Remove:
```dart
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_player_sheet.dart';
```

**File**: `lib/features/dashboard/presentation/components/message_card.dart`
**Changes**: Remove unused import

Remove:
```dart
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_player_sheet.dart';
```

### Success Criteria:

#### Automated Verification:
- [x] All tests pass: `flutter test`
- [x] No linting errors: `flutter analyze`
- [x] App builds successfully: `flutter build web`
- [x] Hot reload works: `flutter run -d chrome`

#### Manual Verification:
- [ ] Audio player panel appears when playing audio
- [ ] Panel starts in focused mode with full controls
- [ ] Clicking minimize collapses to compact mode
- [ ] Clicking compact mode expands back to focused mode
- [ ] Compact mode shows play/pause and progress
- [ ] Only one audio plays at a time (new audio stops previous)
- [ ] Panel persists when navigating to different messages
- [ ] Stop button closes the panel
- [ ] All playback controls work in focused mode
- [ ] Waveform visualization displays correctly
- [ ] Speed control works
- [ ] Seek slider and waveform tap work

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that audio playback works correctly in the panel before proceeding to Phase 4.

---

## Phase 4: Final Integration and Polish

### Overview
Fine-tune panel positioning, add final touches, and clean up deprecated code.

### Changes Required:

#### 1. Adjust Panel Positioning in DashboardPanels
**File**: `lib/features/dashboard/presentation/components/dashboard_panels.dart`
**Changes**: Fine-tune positioning logic based on manual testing

Update the positioning logic to handle edge cases:

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<DownloadBloc, DownloadState>(
    builder: (context, downloadState) {
      final showDownloadPanel = downloadState is DownloadInProgress ||
                                 downloadState is DownloadCompleted ||
                                 downloadState is DownloadCancelled;

      final downloadPanelWidth = showDownloadPanel ? 320.0 : 0.0;

      return Stack(
        children: [
          // Download Panel (Right-most)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            right: showDownloadPanel ? 0 : -350,
            bottom: 0,
            width: 320,
            child: const DownloadPanel(),
          ),

          // Message Detail Panel (Center-right, offset by download panel if present)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            right: selectedMessageForDetail != null
                ? downloadPanelWidth
                : -400,
            height: double.infinity,
            width: 400,
            child: selectedMessageForDetail != null
                ? MessageDetailPanel(
                    messageId: selectedMessageForDetail!,
                    onClose: onCloseDetail,
                  )
                : const SizedBox.shrink(),
          ),

          // Audio Player Panel (Center-right, below detail if present, offset by download panel)
          BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
            builder: (context, audioState) {
              final showAudioPanel = audioState is AudioPlayerReady ||
                                     audioState is AudioPlayerLoading;

              // Calculate top position based on detail panel presence
              final topPosition = selectedMessageForDetail != null ? 420.0 : 80.0;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: topPosition,
                right: showAudioPanel ? downloadPanelWidth : -420,
                width: 400,
                child: const AudioPlayerPanel(),
              );
            },
          ),
        ],
      );
    },
  );
}
```

#### 2. Add Elevation/Shadow to Panels
**File**: `lib/features/dashboard/presentation/components/base_panel.dart`
**Changes**: Add shadow for depth

```dart
@override
Widget build(BuildContext context) {
  return Container(
    width: width,
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(-2, 0),
        ),
      ],
    ),
    child: AppContainer(
      backgroundColor: AppColors.surface,
      border: showBorder
          ? const Border(
              left: BorderSide(color: AppColors.border),
            )
          : null,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      child: child,
    ),
  );
}
```

And add the shadow color to `AppColors` if not present:

**File**: `lib/core/theme/app_colors.dart`
**Changes**: Add shadow color

```dart
static const Color shadow = Color(0xFF000000);
```

#### 3. Deprecate Old Bottom Sheet Widgets
**File**: `lib/features/message_download/presentation/widgets/download_progress_sheet.dart`
**Changes**: Add deprecation notice at top of file

```dart
// DEPRECATED: This widget is no longer used. Use DownloadPanel instead.
// This file is kept for reference but will be removed in a future version.
@Deprecated('Use DownloadPanel from dashboard/presentation/components instead')

/// Bottom sheet that displays download progress
class DownloadProgressSheet extends StatelessWidget {
  // ... existing code
}
```

**File**: `lib/features/audio_player/presentation/widgets/audio_player_sheet.dart`
**Changes**: Add deprecation notice at top of file

```dart
// DEPRECATED: This widget is no longer used. Use AudioPlayerPanel instead.
// This file is kept for reference but will be removed in a future version.
@Deprecated('Use AudioPlayerPanel from dashboard/presentation/components instead')

/// Modal bottom sheet for audio playback controls
class AudioPlayerSheet extends StatelessWidget {
  // ... existing code
}
```

#### 4. Test Edge Cases
Manually test the following scenarios:
- Opening all three panels simultaneously
- Rapidly starting/stopping downloads
- Playing audio while downloads are running
- Switching between messages while audio is playing
- Cancelling downloads mid-progress
- Network errors during audio playback
- Minimizing/maximizing audio player while downloading

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] No linting errors: `flutter analyze`
- [ ] App builds successfully for all platforms: `flutter build web`, `flutter build macos`
- [ ] No console errors or warnings during runtime

#### Manual Verification:
- [ ] All three panels can be open simultaneously without overlap issues
- [ ] Panel animations are smooth and don't cause jank
- [ ] Shadows/elevation make panels visually distinct from background
- [ ] Download panel correctly auto-dismisses after 4 seconds
- [ ] Audio player compact mode is usable and intuitive
- [ ] No memory leaks (panels properly dispose resources)
- [ ] All panels work correctly on different screen sizes
- [ ] Panel positioning adjusts correctly when download panel appears/disappears
- [ ] No visual glitches during rapid panel changes
- [ ] User can still interact with main dashboard content when panels are open

**Implementation Note**: This is the final phase. After all verification passes and manual testing is complete, the implementation is done!

---

## Testing Strategy

### Unit Tests:
- Test download panel auto-dismiss timer logic
- Test audio player focus/compact mode state transitions
- Test panel positioning calculations
- Test that only one audio plays at a time

### Widget Tests:
- Test BasePanel rendering
- Test DownloadPanel UI states (InProgress, Completed, Cancelled, Error)
- Test AudioPlayerPanel UI modes (Focused, Compact)
- Test DashboardPanels orchestration

### Integration Tests:
- Test complete download flow with panel
- Test complete audio playback flow with panel
- Test panel interactions (minimize, close, expand)
- Test multiple panels open simultaneously

### Manual Testing Steps:
1. Start a download and verify panel appears on right
2. Verify circular progress updates in real-time
3. Cancel download mid-progress and verify panel state
4. Complete a download and verify auto-dismiss after 4 seconds
5. Play an audio message and verify panel appears
6. Minimize audio player and verify compact mode
7. Expand audio player back to full mode
8. Play a different audio and verify first audio stops
9. Open message detail panel while audio is playing
10. Verify all three panels can be visible together
11. Test panel positioning on different screen sizes
12. Verify smooth animations during all transitions

## Performance Considerations

- Use `AnimatedPositioned` for smooth panel transitions
- Dispose timers properly to avoid memory leaks
- Use `BlocBuilder` selectively to minimize rebuilds
- Lazy-load panel content (don't render when hidden)
- Use `const` constructors where possible
- Optimize waveform rendering (consider caching)

## Migration Notes

### For Developers:
- Old bottom sheet widgets are deprecated but not removed
- Update any custom code that references `DownloadProgressSheet` or `AudioPlayerSheet`
- Panel state is managed via existing BLoCs (no new state management needed)
- Animations can be disabled for testing by setting duration to `Duration.zero`

### Breaking Changes:
- None - this is purely a UI refactor
- All existing BLoC events and states remain unchanged
- API contracts are preserved

## References

- Original download bottom sheet: `lib/features/message_download/presentation/widgets/download_progress_sheet.dart`
- Original audio player bottom sheet: `lib/features/audio_player/presentation/widgets/audio_player_sheet.dart`
- Existing panel pattern: `lib/features/messages/presentation/components/message_detail_panel.dart`
- Download BLoC: `lib/features/message_download/presentation/bloc/download_bloc.dart`
- Audio player BLoC: `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart`
