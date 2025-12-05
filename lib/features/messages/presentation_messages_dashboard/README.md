# Messages Dashboard

## Architecture

The Messages Dashboard uses a **Bloc/Cubit architecture** for state management, separating async operations from UI state.

### Blocs (Async Operations)
- **MessageBloc**: Fetches messages, handles pagination and search
- **AudioPlayerBloc**: Manages audio playback state
- **DownloadBloc**: Handles message downloads and transcripts
- **MessageDetailBloc**: Loads detailed message data

### Cubits (UI State)
- **MessageSelectionCubit**: Manages message selection state
- **MessageCompositionCubit**: Controls composition panel visibility and state
- **MessageDetailCubit**: Controls detail panel visibility

### Widget Tree
```
DashboardScreen (StatefulWidget - for Bloc subscriptions)
├─ DashboardAppBar
└─ DashboardContent (StatelessWidget - layout only)
    ├─ MessagesContent (reads cubits)
    ├─ MessagesActionPanel (reads cubits)
    ├─ PaginationControls
    ├─ AudioMiniPlayerWidget
    └─ InlineMessageCompositionPanel (reads/writes cubit)
```

## Communication Pattern

### User Action → Cubit → UI Update
```dart
// User clicks message checkbox
onPressed: () => context.read<MessageSelectionCubit>().toggleMessage(messageId)

// Cubit emits new state
emit(state.copyWith(selectedMessageIds: newSelection))

// UI rebuilds with BlocBuilder
BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
  builder: (context, state) => /* UI reflects state */
)
```

### No Callback Drilling
- Widgets access Cubits directly via `context.read<>()`
- State flows down via `BlocBuilder`/`BlocSelector`
- No prop drilling through multiple widget layers

## Migration from Callbacks

### Before (Callback Architecture):
```dart
// DashboardContent with 17+ parameters
DashboardContent(
  selectedMessages: _selectedMessages,
  onToggleMessageSelection: _toggleMessageSelection,
  onReply: _onReply,
  // ... 15+ more callbacks
)

// Child widgets receive callbacks
AppIconButton(
  onPressed: () => onReply?.call(message.id, message.conversationId),
)
```

### After (Cubit Architecture):
```dart
// DashboardContent with 4 parameters
DashboardContent(
  isAnyBlocLoading: _isAnyBlocLoading,
  onManualLoadMore: _onManualLoadMore,
  hasMoreMessages: messageState?.hasMoreMessages ?? false,
  isLoadingMore: messageState?.isLoadingMore ?? false,
)

// Child widgets access cubits directly
AppIconButton(
  onPressed: () {
    final workspaceState = context.read<WorkspaceBloc>().state;
    if (workspaceState is WorkspaceLoaded && workspaceState.selectedWorkspace != null) {
      context.read<MessageCompositionCubit>().openReply(
        workspaceId: workspaceState.selectedWorkspace!.id,
        channelId: message.conversationId,
        replyToMessageId: message.id,
      );
    }
  },
)
```

## Benefits

### Before (Callback Architecture):
- ❌ 20+ callback parameters passed through widget tree
- ❌ Deep prop drilling (3-4 levels)
- ❌ setState triggers rebuild entire subtree
- ❌ Difficult to track state changes

### After (Cubit Architecture):
- ✅ 4 essential parameters only
- ✅ Direct Cubit access via context
- ✅ BlocBuilder rebuilds only affected widgets
- ✅ Clear state ownership and flow
- ✅ Better performance (selective rebuilds)
- ✅ Easier testing (pure UI widgets)

## Testing Strategy

### Unit Tests
- **MessageSelectionCubit**: Selection logic, toggle operations
- **MessageCompositionCubit**: Panel state management, reply handling
- **MessageDetailCubit**: Detail panel visibility, bloc integration

### Integration Tests
- Complete user flows (select → download → clear)
- Composition workflows (reply → send → refresh)
- Detail panel interactions

## Performance Considerations

### Selective Rebuilds
```dart
// Only MessagesActionPanel rebuilds when selection changes
BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
  builder: (context, state) {
    return state.hasSelection ? MessagesActionPanel() : SizedBox.shrink();
  },
)

// Only AudioMiniPlayer rebuilds when composition state changes
BlocBuilder<MessageCompositionCubit, MessageCompositionState>(
  builder: (context, state) {
    return Positioned(
      bottom: state.isVisible ? 700 : 24, // Repositions based on state
      child: AudioMiniPlayerWidget(),
    );
  },
)
```

## File Structure

```
lib/features/messages/presentation_messages_dashboard/
├── bloc/                    # Async operations
│   ├── message_bloc.dart
│   ├── message_event.dart
│   └── message_state.dart
├── cubits/                  # UI state management
│   ├── message_selection_cubit.dart
│   ├── message_selection_state.dart
│   └── ...
├── components/              # UI components
│   ├── app_bar_dashboard.dart
│   ├── messages_content.dart
│   ├── messages_action_panel.dart
│   └── ...
├── screens/                 # Screen widgets
│   ├── dashboard_screen.dart
│   └── content_dashboard.dart
└── README.md               # This file
```

## References

- [Bloc Library Documentation](https://bloclibrary.dev)
- [Flutter Bloc Package](https://pub.dev/packages/flutter_bloc)
- [Clean Architecture Guidelines](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
