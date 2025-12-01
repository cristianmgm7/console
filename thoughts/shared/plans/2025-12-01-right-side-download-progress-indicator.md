# Right-Side Circular Download Progress Indicator Implementation Plan

## Overview

Replace the current blocking modal bottom sheet download progress with a non-blocking circular progress indicator positioned on the right side of the screen. The indicator will show download percentage in the center of a circular progress bar and automatically disappear when downloads complete, allowing users to continue using the app without interruption.

## Current State Analysis

### Existing Infrastructure
- **DownloadBloc**: Manages download state with progress updates via `DownloadInProgress` state
- **DownloadProgressSheet**: Modal bottom sheet that blocks entire UI workflow
- **BlocConsumer Pattern**: Used in dashboard for handling download state changes
- **Progress States**: `DownloadInProgress`, `DownloadCompleted`, `DownloadCancelled`, `DownloadError`

### Key Findings
- Dashboard currently shows blocking modal bottom sheet (lines 177-220 in `dashboard_screen.dart`)
- Voice memos only shows snackbar notifications, no visual progress indicator
- Download progress includes `current`, `total`, and `progressPercent` fields
- Modal sheet auto-dismisses after completion with 500ms delay
- Current implementation uses linear progress bar in modal sheet

### What We're NOT Doing
- Changing the underlying download BLoC or service logic
- Modifying download APIs or authentication
- Altering the download workflow or cancellation logic

## Desired End State

A seamless download experience where:
1. Users initiate downloads and continue using the app normally
2. A compact circular progress indicator appears on the right side
3. Progress percentage is displayed in the center of the circle
4. Indicator automatically disappears when download completes
5. Users can still navigate, select items, and perform other actions
6. Cancel functionality remains available through the indicator

### Key User Flows
1. **Start Download**: Click download → Circular indicator appears on right → Download starts
2. **During Download**: Continue using app → Indicator shows live progress → Can cancel if needed
3. **Completion**: Download finishes → Indicator auto-disappears → Success notification shown
4. **Multiple Downloads**: Handle concurrent downloads gracefully

## Implementation Approach

Create a floating circular progress indicator that integrates with the existing download BLoC state management, positioned on the right side of the screen using the same Stack pattern as other floating elements.

## Phase 1: Create Circular Download Progress Widget

### Overview
Build a new `CircularDownloadProgressWidget` that displays circular progress with percentage text in the center, integrated with the DownloadBloc.

### Changes Required:

#### 1. Create Circular Progress Widget
**File**: `lib/features/message_download/presentation/widgets/circular_download_progress_widget.dart`
**Changes**: New widget implementing circular progress indicator

```dart
class CircularDownloadProgressWidget extends StatelessWidget {
  const CircularDownloadProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        return switch (state) {
          DownloadInProgress() => _buildProgressIndicator(context, state),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context, DownloadInProgress state) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress
          CircularProgressIndicator(
            value: state.progressPercent / 100,
            strokeWidth: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          // Percentage text
          Text(
            '${state.progressPercent.round()}%',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Widget compiles without errors: `flutter build`
- [ ] Unit tests pass for new widget: `flutter test`
- [ ] BLoC integration works: Download state changes update widget
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [ ] Widget appears when DownloadInProgress state is active
- [ ] Circular progress shows correct percentage
- [ ] Text displays in center of circle
- [ ] Widget disappears when download completes

## Phase 2: Integrate Right-Side Progress in Dashboard

### Overview
Replace the modal bottom sheet with the circular progress indicator positioned on the right side of the dashboard.

### Changes Required:

#### 1. Update Dashboard Stack
**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
**Changes**: Add circular progress indicator to right side of dashboard stack

```dart
@override
Widget build(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Stack(
      children: [
        if (_selectedMessageForDetail == null) _buildFullDashboard() else _buildDashboardWithDetail(),

        // Error listeners
        _buildErrorListeners(),

        // NEW: Right-side circular progress indicator
        Positioned(
          top: 100, // Below app bar
          right: 24,
          child: const CircularDownloadProgressWidget(),
        ),
      ],
    ),
  );
}
```

#### 2. Remove Modal Bottom Sheet Logic
**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
**Changes**: Remove `showModalBottomSheet` calls from download methods

```dart
void _onDownloadAudio() {
  // Check for empty selection
  if (_selectedMessages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No messages selected'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // Create a copy of selected messages for the download
  final messagesToDownload = Set<String>.from(_selectedMessages);

  // Clear selection after capturing the messages to download
  setState(() {
    _selectedMessages.clear();
    _selectAll = false;
  });

  // Start download (no modal shown - progress indicator appears automatically)
  context.read<DownloadBloc>().add(StartDownloadAudio(messagesToDownload));
}
```

#### 3. Update BlocConsumer for Completion Notifications
**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
**Changes**: Add BlocConsumer to handle download completion notifications

```dart
// In the build method, wrap the Stack with BlocConsumer
return BlocConsumer<DownloadBloc, DownloadState>(
  listener: (context, downloadState) {
    if (downloadState is DownloadCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download completed: ${downloadState.successCount} successful, '
            '${downloadState.failureCount} failed',
          ),
          backgroundColor: downloadState.failureCount > 0
              ? AppColors.error
              : AppColors.success,
        ),
      );
    } else if (downloadState is DownloadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${downloadState.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  },
  builder: (context, downloadState) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          if (_selectedMessageForDetail == null) _buildFullDashboard() else _buildDashboardWithDetail(),

          // Error listeners
          _buildErrorListeners(),

          // Right-side circular progress indicator
          Positioned(
            top: 100,
            right: 24,
            child: const CircularDownloadProgressWidget(),
          ),
        ],
      ),
    );
  },
);
```

### Success Criteria:

#### Automated Verification:
- [x] Dashboard compiles without errors: `flutter build`
- [x] No references to DownloadProgressSheet in dashboard: `grep -r DownloadProgressSheet lib/features/dashboard/`
- [ ] Unit tests pass: `flutter test`

#### Manual Verification:
- [ ] Download starts without showing modal bottom sheet
- [ ] Circular progress indicator appears on right side
- [ ] Progress updates in real-time during download
- [ ] Indicator disappears automatically when download completes
- [ ] Success/error notifications still work via snackbar

## Phase 3: Integrate Right-Side Progress in Voice Memos

### Overview
Add the circular progress indicator to the voice memos screen, replacing the current snackbar-only approach.

### Changes Required:

#### 1. Update Voice Memos Stack
**File**: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
**Changes**: Add circular progress indicator to right side of voice memos stack

```dart
@override
Widget build(BuildContext context) {
  return AppContainer(
    backgroundColor: AppColors.surface,
    child: BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, downloadState) {
        if (downloadState is DownloadCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Download completed: ${downloadState.successCount} successful, '
                '${downloadState.failureCount} failed',
              ),
              backgroundColor: downloadState.failureCount > 0
                  ? AppColors.error
                  : AppColors.success,
            ),
          );
        } else if (downloadState is DownloadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${downloadState.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
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

            // NEW: Right-side circular progress indicator
            Positioned(
              top: 24,
              right: 24,
              child: const CircularDownloadProgressWidget(),
            ),
          ],
        );
      },
    ),
  );
}
```

#### 2. Remove Redundant SnackBar Logic
**File**: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
**Changes**: Remove the existing snackbar logic since we now have visual progress indicator

```dart
// Remove this listener block that shows progress snackbars:
listener: (context, downloadState) {
  if (downloadState is DownloadInProgress) {
    // Remove this - we now have visual progress indicator
  } else if (downloadState is DownloadCompleted) {
    // Keep completion notifications
  } else if (downloadState is DownloadError) {
    // Keep error notifications
  } else if (downloadState is DownloadCancelled) {
    // Keep cancellation notifications
  }
},
```

### Success Criteria:

#### Automated Verification:
- [x] Voice memos screen compiles: `flutter build`
- [ ] No breaking changes to existing functionality: `flutter test`

#### Manual Verification:
- [ ] Voice memo downloads show circular progress indicator
- [ ] Progress indicator positioned correctly on right side
- [ ] Auto-disappears when download completes
- [ ] Success/error notifications still work

## Phase 4: Add Cancellation Support

### Overview
Add the ability to cancel downloads by tapping the circular progress indicator.

### Changes Required:

#### 1. Update Circular Progress Widget
**File**: `lib/features/message_download/presentation/widgets/circular_download_progress_widget.dart`
**Changes**: Add tap gesture for cancellation

```dart
Widget _buildProgressIndicator(BuildContext context, DownloadInProgress state) {
  return GestureDetector(
    onTap: () {
      // Show confirmation dialog before cancelling
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel Download'),
          content: const Text('Are you sure you want to cancel the download?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                context.read<DownloadBloc>().add(const CancelDownload());
                Navigator.pop(dialogContext);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    },
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress
          CircularProgressIndicator(
            value: state.progressPercent / 100,
            strokeWidth: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          // Cancel icon overlay
          const Icon(
            Icons.close,
            size: 16,
            color: AppColors.textSecondary,
          ),
          // Percentage text
          Text(
            '${state.progressPercent.round()}%',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [x] Cancellation functionality compiles: `flutter build`
- [ ] Unit tests pass: `flutter test`

#### Manual Verification:
- [ ] Tapping progress indicator shows cancellation dialog
- [ ] Cancel action properly stops download
- [ ] Dialog dismisses correctly on cancel/no

## Testing Strategy

### Unit Tests:
- Test circular progress widget renders correctly for different progress states
- Test BLoC integration and state updates
- Test tap gesture for cancellation
- Test auto-dismissal when download completes

### Integration Tests:
- Test dashboard download flow: Start download → Progress indicator appears → Completes → Auto-disappears
- Test voice memos download flow: Same as dashboard
- Test cancellation: Tap indicator → Confirm dialog → Download cancels

### Manual Testing Steps:
1. [ ] Start audio download in dashboard → Circular indicator appears on right
2. [ ] Verify progress updates in real-time during download
3. [ ] Continue using dashboard (select messages, navigate) while downloading
4. [ ] Download completes → Indicator disappears automatically
5. [ ] Success notification appears via snackbar
6. [ ] Repeat steps 1-5 for voice memos screen
7. [ ] Test cancellation by tapping indicator → Confirm dialog appears
8. [ ] Cancel download → Indicator disappears, cancellation notification shows
9. [ ] Test on different screen sizes → Positioning works correctly

## Performance Considerations

- Progress indicator only renders when DownloadBloc is in progress state
- Circular progress animation is lightweight
- Auto-disposal prevents memory leaks
- No additional rebuilds beyond necessary state updates

## Migration Notes

- Existing download BLoC and service logic remains unchanged
- Backward compatibility maintained for any other download consumers
- Users can still cancel downloads through the indicator
- Progress information remains the same (current/total/percentage)

## References

- Current DownloadProgressSheet: `lib/features/message_download/presentation/widgets/download_progress_sheet.dart`
- Dashboard screen integration: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Voice memos screen: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
- DownloadBloc: `lib/features/message_download/presentation/bloc/download_bloc.dart`</contents>
</xai:function_call">Created file: thoughts/shared/plans/2025-12-01-right-side-download-progress-indicator.md
