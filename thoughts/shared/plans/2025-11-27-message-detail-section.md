# Message Detail Section Implementation Plan

## Overview

Add a new "Message Detail" section to the dashboard that displays comprehensive information about a selected message. When users tap on a message in the dashboard, they will navigate to a detail screen showing all available message information including content, metadata, audio details, and usage statistics.

## Current State Analysis

The dashboard currently displays messages using `MessageCard` widgets in a `ListView`. Each card shows basic information (date, creator, content preview, duration) and has a popup menu with "View Details" option that is currently unimplemented.

**Existing Infrastructure:**
- `MessageUiModel` contains comprehensive message data
- `MessageRepository.getMessage(String messageId)` fetches detailed message data using `/v5/messages/{messageId}` endpoint
- `MessageBloc` manages message state with BLoC pattern
- `GoRouter` handles navigation with routes defined in `AppRoutes`
- Dashboard is accessible at `/dashboard` route

**Data Available in MessageUiModel:**
- Basic info: id, creatorId, createdAt, duration, status, type
- Relationships: workspaceIds, channelIds, conversationId, userId
- Content: text, transcriptText, audioUrl, notes
- Audio data: audioModels (waveform, language, format, streaming status)
- Text data: textModels (transcripts, summaries with timecodes)
- Usage data: lastHeardAt, heardDuration, totalHeardDuration, lastUpdatedAt

## Desired End State

After implementation, users can:
1. Tap "View Details" on any message card in the dashboard
2. Navigate to a dedicated message detail screen
3. View all message information in an organized, readable format
4. Navigate back to dashboard seamlessly

The detail screen displays message information in logical sections with proper formatting and responsive design.

## What We're NOT Doing

- Modifying existing message list functionality
- Changing dashboard layout or MessageCard design
- Adding message editing capabilities (beyond what's already in the menu)
- Implementing bulk operations for message details

## Implementation Approach

Use existing patterns and infrastructure:
- Follow BLoC pattern for state management (MessageBloc already provided at dashboard level)
- Use dashboard state to show/hide detail panel instead of navigation
- Follow existing UI component patterns and theming
- Leverage existing `getMessage` API endpoint

## Phase 1: Add Message Detail Panel to Dashboard

### Overview
Add a detail panel/section to the dashboard that shows when a message is selected, instead of navigating to a separate screen.

### Changes Required:

#### 1. Add Selected Message State to Dashboard
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Add state to track selected message for detail view
```dart
class _DashboardScreenState extends State<DashboardScreen> {
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;

  // Add selected message for detail view
  String? _selectedMessageForDetail;
```

#### 2. Update Dashboard Layout for Detail Panel
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Modify build method to show detail panel when message is selected
```dart
@override
Widget build(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Stack(
      children: [
        // Main dashboard content
        if (_selectedMessageForDetail == null)
          _buildFullDashboard()
        else
          _buildDashboardWithDetail(),

        // Floating Action Panel (existing)
        // ...
      ],
    ),
  );
}
```

#### 3. Implement Message Selection in MessageCard
**File**: `lib/features/dashboard/presentation/components/message_card.dart`
**Changes**: Update popup menu to trigger detail panel instead of navigation
```dart
onSelected: (value) {
  switch (value) {
    case 'view':
      // Trigger showing detail panel in dashboard
      // This will be passed as callback from dashboard
      onViewDetail?.call(message.id);
      break;
    // ... other cases
  }
},
```

### Success Criteria:

#### Automated Verification:
- [x] App builds without errors
- [x] Dashboard state tracks selected message for detail
- [x] MessageCard triggers detail panel callback
- [x] Dashboard layout adapts when detail is shown

#### Manual Verification:
- [ ] Tapping "View Details" shows detail panel in dashboard
- [ ] Dashboard layout changes to accommodate detail panel
- [ ] Detail panel can be closed to return to full dashboard

## Phase 2: Implement Message Detail Panel in Dashboard

### Overview
Create the message detail panel component that integrates with the existing dashboard and MessageBloc.

### Changes Required:

#### 1. Add BLoC Event for Single Message Loading
**File**: `lib/features/messages/presentation/bloc/message_event.dart`
**Changes**: Add new event for loading message details
```dart
class LoadMessageDetail extends MessageEvent {
  const LoadMessageDetail(this.messageId);
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}
```

#### 2. Add BLoC State for Message Detail
**File**: `lib/features/messages/presentation/bloc/message_state.dart`
**Changes**: Add state for single message detail
```dart
class MessageDetailLoaded extends MessageState {
  const MessageDetailLoaded({
    required this.message,
    required this.user,
  });
  final MessageUiModel message;
  final User? user;

  @override
  List<Object?> get props => [message, user];
}
```

#### 3. Handle Message Detail Event in BLoC
**File**: `lib/features/messages/presentation/bloc/message_bloc.dart`
**Changes**: Add event handler for loading message details
```dart
on<LoadMessageDetail>(_onLoadMessageDetail);

Future<void> _onLoadMessageDetail(
  LoadMessageDetail event,
  Emitter<MessageState> emit,
) async {
  emit(const MessageLoading());
  final result = await _messageRepository.getMessage(event.messageId);

  if (result.isSuccess) {
    final message = result.valueOrNull!.toUiModel();
    final userResult = await _userRepository.getUsers([message.userId]);
    final user = userResult.valueOrNull?.firstOrNull;

    emit(MessageDetailLoaded(message: message, user: user));
  } else {
    emit(MessageError(FailureMapper.mapToMessage(result.failureOrNull!)));
  }
}
```

#### 4. Create Message Detail Panel Component
**File**: `lib/features/messages/presentation/components/message_detail_panel.dart`
**Changes**: Create panel component that works with dashboard's MessageBloc
```dart
class MessageDetailPanel extends StatelessWidget {
  const MessageDetailPanel({
    required this.messageId,
    required this.onClose,
    super.key
  });
  final String messageId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Trigger loading the message detail when panel is shown
    context.read<MessageBloc>().add(LoadMessageDetail(messageId));

    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, state) {
        return Container(
          width: 400, // Fixed width panel
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Message Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
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

  Widget _buildContent(MessageState state) {
    if (state is MessageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MessageDetailLoaded) {
      return MessageDetailContent(state: state);
    }
    if (state is MessageError) {
      return Center(child: Text('Error: ${state.message}'));
    }
    return const SizedBox.shrink();
  }
}
```

#### 5. Create Message Detail Content Component
**File**: `lib/features/messages/presentation/components/message_detail_content.dart`
**Changes**: Extract content sections from previous implementation
```dart
class MessageDetailContent extends StatelessWidget {
  const MessageDetailContent({required this.state, super.key});
  final MessageDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildContentSection(),
          const SizedBox(height: 24),
          _buildMetadataSection(),
        ],
      ),
    );
  }

  // ... section building methods (same as before)
}
```

### Success Criteria:

#### Automated Verification:
- [ ] App builds without errors
- [ ] BLoC handles new event correctly
- [ ] Panel renders within dashboard layout
- [ ] Close functionality works

#### Manual Verification:
- [ ] Detail panel shows loading state initially
- [ ] Message data loads and displays correctly
- [ ] Panel can be closed to return to full dashboard
- [ ] Panel layout works well with dashboard

## Phase 3: Implement Message Detail UI Components

### Overview
Create detailed UI components for displaying message information in organized sections.

### Changes Required:

#### 1. Basic Info Section Component
**File**: `lib/features/messages/presentation/components/message_detail_sections.dart`
**Changes**: Create section components for different types of message data
```dart
class MessageBasicInfoSection extends StatelessWidget {
  const MessageBasicInfoSection({
    required this.message,
    required this.user,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('ID', message.id),
            _buildInfoRow('Creator', message.creatorId),
            _buildInfoRow('Created', _formatDate(message.createdAt)),
            _buildInfoRow('Duration', _formatDuration(message.duration)),
            _buildInfoRow('Status', message.status),
            _buildInfoRow('Type', message.type),
          ],
        ),
      ),
    );
  }
}
```

#### 2. Content Section Component
**File**: `lib/features/messages/presentation/components/message_detail_sections.dart`
**Changes**: Add content display section
```dart
class MessageContentSection extends StatelessWidget {
  const MessageContentSection({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Content', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (message.transcriptText != null) ...[
              Text('Transcript',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message.transcriptText!,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (message.text != null) ...[
              Text('Text', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message.text!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (message.audioUrl != null) ...[
              const SizedBox(height: 16),
              Text('Audio URL', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(message.audioUrl!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### 3. Metadata Section Component
**File**: `lib/features/messages/presentation/components/message_detail_sections.dart`
**Changes**: Add metadata display section
```dart
class MessageMetadataSection extends StatelessWidget {
  const MessageMetadataSection({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metadata', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (message.lastHeardAt != null)
              _buildInfoRow('Last Heard', _formatDate(message.lastHeardAt!)),
            if (message.heardDuration != null)
              _buildInfoRow('Heard Duration',
                  _formatDuration(message.heardDuration!)),
            if (message.totalHeardDuration != null)
              _buildInfoRow('Total Heard Duration',
                  _formatDuration(message.totalHeardDuration!)),
            if (message.lastUpdatedAt != null)
              _buildInfoRow('Last Updated',
                  _formatDate(message.lastUpdatedAt!)),
            _buildInfoRow('Workspace IDs',
                message.workspaceIds.join(', ')),
            _buildInfoRow('Channel IDs',
                message.channelIds.join(', ')),
            _buildInfoRow('Conversation ID', message.conversationId),
            _buildInfoRow('User ID', message.userId),
          ],
        ),
      ),
    );
  }
}
```

#### 4. Audio Models Section Component
**File**: `lib/features/messages/presentation/components/message_detail_sections.dart`
**Changes**: Add audio models display section
```dart
class MessageAudioModelsSection extends StatelessWidget {
  const MessageAudioModelsSection({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    if (message.audioModels.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audio Models',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...message.audioModels.map((audioModel) =>
              _buildAudioModelTile(context, audioModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioModelTile(BuildContext context, AudioModel audioModel) {
    return ListTile(
      title: Text('Audio Model ${audioModel.id}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Language: ${audioModel.language}'),
          Text('Format: ${audioModel.format}'),
          Text('Duration: ${_formatDuration(audioModel.duration)}'),
          Text('Streaming: ${audioModel.isStreaming}'),
          Text('Original: ${audioModel.isOriginal}'),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () {
          // TODO: Implement audio playback
        },
      ),
    );
  }
}
```

#### 5. Update Detail View to Use Sections
**File**: `lib/features/messages/presentation/components/message_detail_view.dart`
**Changes**: Integrate section components
```dart
Widget _buildDetailContent(BuildContext context, MessageDetailLoaded state) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MessageBasicInfoSection(
          message: state.message,
          user: state.user,
        ),
        const SizedBox(height: 24),
        MessageContentSection(message: state.message),
        const SizedBox(height: 24),
        MessageAudioModelsSection(message: state.message),
        const SizedBox(height: 24),
        MessageMetadataSection(message: state.message),
      ],
    ),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All UI components render without errors
- [ ] App builds successfully
- [ ] No linting errors

#### Manual Verification:
- [ ] All message data displays correctly in organized sections
- [ ] Sections are visually distinct and well-formatted
- [ ] Content is readable and properly formatted
- [ ] Screen handles different message types appropriately
- [ ] Responsive layout works on different screen sizes

## Testing Strategy

### Unit Tests:
- Test BLoC event handling for message detail loading
- Test UI components render correctly with mock data
- Test navigation logic

### Integration Tests:
- Test full navigation flow from dashboard to detail screen
- Test data loading and error handling
- Test back navigation

### Manual Testing Steps:
1. Navigate to dashboard with messages loaded
2. Tap "View Details" on a message card
3. Verify detail screen loads and displays all information
4. Test back navigation returns to dashboard
5. Test with different types of messages (text, audio, etc.)
6. Test error scenarios (invalid message ID, network issues)

## Performance Considerations

- Message detail data is fetched on-demand, not preloaded
- Single message API call is efficient for detail view
- UI uses standard Flutter widgets for good performance
- Consider caching message details if users frequently revisit the same messages

## Migration Notes

- No database changes required
- Existing message list functionality remains unchanged
- New feature is additive and doesn't affect existing workflows
- Backwards compatible - users can continue using dashboard without the detail feature

## References

- Original user request for message detail section
- API documentation: `docs/API_ENDPOINTS.md`
- Existing message models and UI patterns
