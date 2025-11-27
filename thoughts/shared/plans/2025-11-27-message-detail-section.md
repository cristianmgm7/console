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
- Follow BLoC pattern for state management
- Use GoRouter for navigation with parameterized routes
- Follow existing UI component patterns and theming
- Leverage existing `getMessage` API endpoint

## Phase 1: Add Message Detail Route and Navigation

### Overview
Add routing infrastructure and basic navigation from MessageCard to detail screen.

### Changes Required:

#### 1. Add Message Detail Route
**File**: `lib/core/routing/app_routes.dart`
**Changes**: Add new route constant for message details
```dart
static const String messageDetail = '/dashboard/messages/:messageId';
```

#### 2. Add Route to Router
**File**: `lib/core/routing/app_router.dart`
**Changes**: Add GoRoute for message detail screen
```dart
GoRoute(
  path: AppRoutes.messageDetail,
  name: 'messageDetail',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: MessageDetailScreen(
      messageId: state.pathParameters['messageId']!,
    ),
  ),
),
```

#### 3. Implement Navigation in MessageCard
**File**: `lib/features/dashboard/presentation/components/message_card.dart`
**Changes**: Replace TODO in popup menu handler with navigation logic
```dart
onSelected: (value) {
  switch (value) {
    case 'view':
      context.go('/dashboard/messages/${message.id}');
      break;
    // ... other cases
  }
},
```

### Success Criteria:

#### Automated Verification:
- [x] App builds without errors
- [x] New route is registered in router
- [x] Navigation from MessageCard triggers route change
- [x] Route parameters are correctly passed

#### Manual Verification:
- [ ] Tapping "View Details" on a message navigates to detail screen
- [ ] URL shows correct message ID parameter
- [ ] Back navigation works correctly

## Phase 2: Create Message Detail Screen and BLoC

### Overview
Create the message detail screen with basic structure and implement data fetching using existing patterns.

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

#### 4. Create Message Detail Screen
**File**: `lib/features/messages/presentation/pages/message_detail_screen.dart`
**Changes**: Create new screen component
```dart
class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({required this.messageId, super.key});
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MessageBloc>()..add(LoadMessageDetail(messageId)),
      child: const Scaffold(
        appBar: AppBar(title: Text('Message Details')),
        body: MessageDetailView(),
      ),
    );
  }
}
```

#### 5. Create Message Detail View
**File**: `lib/features/messages/presentation/components/message_detail_view.dart`
**Changes**: Create main content widget with basic structure
```dart
class MessageDetailView extends StatelessWidget {
  const MessageDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, state) {
        if (state is MessageLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MessageDetailLoaded) {
          return _buildDetailContent(context, state);
        }
        if (state is MessageError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDetailContent(BuildContext context, MessageDetailLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info section
          _buildBasicInfoSection(state),
          const SizedBox(height: 24),
          // Content section
          _buildContentSection(state),
          const SizedBox(height: 24),
          // Metadata section
          _buildMetadataSection(state),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] App builds without errors
- [x] BLoC handles new event correctly
- [x] Screen renders without crashes
- [x] Navigation to detail screen works

#### Manual Verification:
- [ ] Detail screen shows loading state initially
- [ ] Message data loads and displays correctly
- [ ] Error state shows appropriate message
- [ ] Screen is scrollable and responsive

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
