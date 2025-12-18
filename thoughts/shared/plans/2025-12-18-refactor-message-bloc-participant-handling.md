# Message Bloc Participant Handling Refactor Implementation Plan

## Overview

Refactor the `MessageBloc` to remove its dependency on `UserRepository` and move participant information loading to the domain layer. The bloc currently handles user profile fetching and caching, which violates separation of concerns. This refactor will create a new use case that returns messages with participant information from conversation collaborators.

## Current State Analysis

### Problems Identified

**File**: `lib/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart`

1. **Mixed Responsibilities** (lines 17-38):
   - Bloc manages message fetching (appropriate)
   - Bloc fetches user profiles (domain layer concern)
   - Bloc caches user data (infrastructure concern)

2. **Inefficient API Calls** (lines 41-71):
   - Separate `UserRepository.getUsers()` calls for every message batch
   - Manual profile caching implementation in presentation layer

3. **Poor Separation of Concerns**:
   - User enrichment is presentation logic, but data fetching should be in domain layer

### What Already Exists

**Good News**: The `Conversation` entity already contains collaborator information:
- **File**: `lib/features/conversations/domain/entities/conversation_entity.dart:86`
- Field: `List<ConversationCollaborator>? collaborators`
- Contains: `userGuid`, `imageUrl`, `firstName`, `lastName`, `permission`, etc.

### Key Discoveries

- The API already returns participant data with conversations
- Current use case (`GetMessagesFromConversationsUsecase`) only returns messages
- The `ConversationRepository.getConversation()` method can fetch individual conversations with collaborators
- Pattern to follow: `EnrichedPreviewComposerData` pattern (Pattern 1 from research)

## Desired End State

After this refactor:

1. **New Use Case**: `GetMessagesFromConversationsWithParticipantsUsecase` that returns messages + participants
2. **Simplified Bloc**: `MessageBloc` only handles UI state, no user fetching or caching
3. **Clean Separation**: Domain layer provides all necessary data, presentation layer only converts to UI models
4. **Better Performance**: Participant data comes from conversation collaborators (already cached by API)

### Verification

To verify the refactor is complete:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] No compilation errors: `flutter analyze`
- [ ] Code formatting: `dart format --set-exit-if-changed .`

#### Manual Verification:
- [ ] Messages load correctly in the dashboard
- [ ] Message creator names and avatars display properly
- [ ] Pagination (load more) works correctly
- [ ] Multiple conversation selection shows correct participants
- [ ] Refresh functionality works as expected
- [ ] No performance degradation observed

**Implementation Note**: After completing this refactor and all automated verification passes, pause for manual confirmation from the human that the manual testing was successful.

## What We're NOT Doing

- NOT implementing conversation caching in the repository (future enhancement)
- NOT changing the message entity structure
- NOT modifying the conversation entity or collaborator structure
- NOT updating other blocs that may use `UserRepository` (out of scope)
- NOT adding new API endpoints (using existing ones)

## Implementation Approach

We'll follow the **EnrichedPreviewComposerData** pattern:
1. Create a composite result class at the top of the use case file
2. Fetch messages from message repository
3. Identify unique conversations from messages
4. Fetch conversations to get collaborators
5. Build a map of participants keyed by userGuid
6. Return composite result with messages, participants, and pagination info

All changes will be done in a single phase (no incremental approach).

---

## Phase 1: Create New Use Case and Result Class

### Overview
Create the new use case that fetches messages along with participant information from conversations.

### Changes Required

#### 1. Create Result Entity Class
**File**: `lib/features/messages/domain/usecases/get_messages_from_conversations_with_participants_usecase.dart` (new file)

**Changes**: Create new file with result class and use case implementation

```dart
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Result of fetching messages with participant information
class MessagesWithParticipants {
  const MessagesWithParticipants({
    required this.messages,
    required this.participants,
    required this.hasMoreMessages,
  });

  final List<Message> messages;
  final Map<String, ConversationCollaborator> participants;
  final bool hasMoreMessages;
}

/// Use case for fetching messages from multiple conversations with participant info
@injectable
class GetMessagesFromConversationsWithParticipantsUsecase {
  const GetMessagesFromConversationsWithParticipantsUsecase(
    this._messageRepository,
    this._conversationRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;
  final Logger _logger;

  /// Fetches messages from multiple conversations with participant information
  ///
  /// [conversationCursors] - Map of conversation ID to the last loaded message timestamp
  /// [count] - Number of messages to fetch per conversation (default: 50)
  ///
  /// Returns merged list sorted by createdAt (newest first) with participants and pagination info
  Future<Result<MessagesWithParticipants>> call({
    required Map<String, DateTime?> conversationCursors,
    int count = 50,
  }) async {
    try {
      final allMessages = <Message>[];
      final conversationResults = <String, int>{}; // conversationId -> messagesReceived

      // Fetch messages from each conversation using recent endpoint
      for (final entry in conversationCursors.entries) {
        final conversationId = entry.key;
        final beforeTimestamp = entry.value ?? DateTime.now(); // Use current time if null

        try {
          final result = await _messageRepository.getRecentMessages(
            conversationId: conversationId,
            count: count,
            beforeTimestamp: beforeTimestamp,
          );

          if (result.isSuccess) {
            final messages = result.valueOrNull!;
            allMessages.addAll(messages);
            conversationResults[conversationId] = messages.length;
          } else {
            _logger.w('Failed to fetch messages from $conversationId: ${result.failureOrNull}');
            conversationResults[conversationId] = 0; // Treat as no messages received
          }
        } on Exception catch (e) {
          // Log warning but continue with other conversations
          _logger.e('Failed to fetch messages from $conversationId: $e');
          conversationResults[conversationId] = 0; // Treat as no messages received
        }
      }

      // Filter out deleted and inactive messages
      final activeMessages = allMessages.where((message) {
        // Filter out messages that have been deleted or are not active
        return message.deletedAt == null && message.status.toLowerCase() == 'active';
      }).toList();

      // Determine if there are more messages available
      final hasMoreMessages = conversationResults.values.any((received) => received >= count);

      // Sort all messages by date (newest first)
      activeMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Fetch participant information from conversations
      final participantMap = <String, ConversationCollaborator>{};
      final uniqueConversationIds = conversationCursors.keys.toSet();

      // Fetch conversations in parallel to get collaborators
      final conversationFutures = uniqueConversationIds.map(
        (conversationId) => _conversationRepository.getConversation(conversationId),
      ).toList();

      final conversationResults = await Future.wait(conversationFutures);

      // Extract all collaborators from all conversations
      for (var i = 0; i < conversationResults.length; i++) {
        final result = conversationResults[i];
        final conversationId = uniqueConversationIds.elementAt(i);

        result.fold(
          onSuccess: (conversation) {
            final collaborators = conversation.collaborators ?? [];
            for (final collaborator in collaborators) {
              if (collaborator.userGuid != null) {
                // Add to map, later entries will overwrite earlier ones (same user data)
                participantMap[collaborator.userGuid!] = collaborator;
              }
            }
          },
          onFailure: (failure) {
            _logger.w(
              'Failed to fetch conversation $conversationId for participants: ${failure.failure.code}',
            );
            // Continue without participants from this conversation
          },
        );
      }

      return success(MessagesWithParticipants(
        messages: activeMessages,
        participants: participantMap,
        hasMoreMessages: hasMoreMessages,
      ));
    } on Exception catch (e, stack) {
      _logger.e('Error fetching messages with participants', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] File compiles without errors: `flutter analyze`
- [ ] Code formatting passes: `dart format --set-exit-if-changed lib/features/messages/domain/usecases/`
- [ ] Injectable generates correctly: `dart run build_runner build`

#### Manual Verification:
- [ ] New use case is properly structured with dependency injection
- [ ] Result class follows the pattern established in the codebase
- [ ] Error handling covers all failure scenarios

---

## Phase 2: Update Message UI Mapper to Support ConversationCollaborator

### Overview
Modify the message UI mapper to accept `ConversationCollaborator` instead of `User` entity.

### Changes Required

#### 1. Update Message UI Model
**File**: `lib/features/messages/presentation_messages_dashboard/models/message_ui_model.dart`

**Changes**: Update the `creator` field type and add support for `ConversationCollaborator`

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// UI model for message presentation
/// Contains computed properties for presentation layer
class MessageUiModel extends Equatable {
  const MessageUiModel({
    required this.id,
    required this.creatorId,
    required this.createdAt,
    required this.workspaceIds,
    required this.channelIds,
    required this.duration,
    required this.audioModels,
    required this.textModels,
    required this.status,
    required this.type,
    required this.lastHeardAt,
    required this.heardDuration,
    required this.totalHeardDuration,
    required this.isTextMessage,
    required this.notes,
    required this.lastUpdatedAt,
    required this.parentMessageId,
    // Computed properties for UI
    required this.conversationId,
    required this.userId,
    required this.text,
    required this.transcriptText,
    required this.audioUrl,
    // Participant data (replaces User creator)
    this.participant,
  });

  // Original message properties
  final String id;
  final String creatorId;
  final DateTime createdAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final Duration duration;
  final List<AudioModel> audioModels;
  final List<TextModel> textModels;
  final String status;
  final String type;
  final DateTime? lastHeardAt;
  final Duration? heardDuration;
  final Duration? totalHeardDuration;
  final bool isTextMessage;
  final String notes;
  final DateTime? lastUpdatedAt;
  final String? parentMessageId;

  // Participant data (replaces User creator)
  final ConversationCollaborator? participant;

  // Computed UI properties
  final String conversationId;
  final String userId;
  final String? text;
  final String? transcriptText;
  final String? audioUrl;

  // Computed properties for creator display
  /// Full name of the message creator
  String? get creatorFullName {
    if (participant == null) return null;
    final firstName = participant!.firstName ?? '';
    final lastName = participant!.lastName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return null;
    return '$firstName $lastName'.trim();
  }

  /// Avatar URL of the message creator
  String? get creatorAvatarUrl => participant?.imageUrl;

  /// Initials for avatar fallback
  String get creatorInitials {
    if (participant == null) return '?';
    final firstName = participant!.firstName ?? '';
    final lastName = participant!.lastName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return '?';
    if (lastName.isEmpty) return firstName[0].toUpperCase();
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  // Computed properties
  /// Whether this message has MP3 audio
  bool get hasPlayableAudio => audioModels.any((audio) => audio.format == 'mp3');

  /// Gets the MP3 audio model if available, null otherwise
  AudioModel? get playableAudioModel => audioModels.firstWhere(
        (audio) => audio.format == 'mp3',
        orElse: () => audioModels.first,
      );

  @override
  List<Object?> get props => [
        id,
        creatorId,
        createdAt,
        workspaceIds,
        channelIds,
        duration,
        audioModels,
        textModels,
        status,
        type,
        lastHeardAt,
        heardDuration,
        totalHeardDuration,
        isTextMessage,
        notes,
        lastUpdatedAt,
        parentMessageId,
        participant,
        conversationId,
        userId,
        text,
        transcriptText,
        audioUrl,
      ];
}
```

#### 2. Update Message UI Mapper
**File**: `lib/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart`

**Changes**: Update `toUiModel()` to accept `ConversationCollaborator` instead of `User`

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_collaborator.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension MessageUiMapper on Message {
  /// Gets the URL of the MP3 audio if available
  static String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    final mp3Audio = audioModels.firstWhere(
      (audio) => audio.format == 'mp3',
      orElse: () => audioModels.first,
    );
    return mp3Audio.presignedUrl ?? mp3Audio.url;
  }

  /// Gets the message text to display, prioritizing summary over transcription
  /// Returns summary if available, otherwise falls back to transcription
  static String? _getMessageText(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    // Try to find summary first
    final summary = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'summary',
      orElse: () => null,
    );
    if (summary != null && summary.text.isNotEmpty) return summary.text;

    // Fall back to transcription
    final transcription = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'transcription',
      orElse: () => null,
    );
    if (transcription != null && transcription.text.isNotEmpty) {
      return transcription.text;
    }

    // Last resort: return the first text model's text if not empty
    return textModels.first.text.isNotEmpty ? textModels.first.text : null;
  }

  /// Creates a UI model with optional participant enrichment
  MessageUiModel toUiModel([ConversationCollaborator? participant]) {
    return MessageUiModel(
      // Original message properties
      id: id,
      creatorId: creatorId,
      createdAt: createdAt,
      workspaceIds: workspaceIds,
      channelIds: channelIds,
      duration: duration,
      audioModels: audioModels,
      textModels: textModels,
      status: status,
      type: type,
      lastHeardAt: lastHeardAt,
      heardDuration: heardDuration,
      totalHeardDuration: totalHeardDuration,
      isTextMessage: isTextMessage,
      notes: notes,
      lastUpdatedAt: lastUpdatedAt,
      parentMessageId: parentMessageId,
      // Participant data
      participant: participant,
      // Computed UI properties
      conversationId: channelIds.isNotEmpty ? channelIds.first : '',
      userId: creatorId,
      text: notes.isNotEmpty ? notes : _getMessageText(textModels),
      transcriptText: textModels.isNotEmpty ? textModels.first.text : null,
      audioUrl: audioModels.isNotEmpty ? _getPlayableAudioUrl(audioModels) : null,
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Files compile without errors: `flutter analyze`
- [ ] Code formatting passes: `dart format --set-exit-if-changed lib/features/messages/`
- [ ] All existing tests still pass: `flutter test`

#### Manual Verification:
- [ ] Message UI model correctly exposes participant data
- [ ] Computed properties for creator name/avatar work correctly
- [ ] Mapper creates valid UI models with participant data

---

## Phase 3: Update MessageBloc to Use New Use Case

### Overview
Replace the old use case and remove all UserRepository dependencies from the bloc.

### Changes Required

#### 1. Update MessageBloc
**File**: `lib/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart`

**Changes**: Replace use case, remove UserRepository dependency, update message mapping logic

```dart
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/usecases/get_messages_from_conversations_with_participants_usecase.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc(
    this._getMessagesFromConversationsWithParticipantsUsecase,
    this._logger,
  ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  final GetMessagesFromConversationsWithParticipantsUsecase
      _getMessagesFromConversationsWithParticipantsUsecase;
  final Logger _logger;
  final int _messagesPerPage = 50;

  Set<String> _currentConversationIds = {};

  // Track oldest timestamp per conversation for pagination
  final Map<String, DateTime> _conversationCursors = {};

  Future<void> _onConversationSelected(
    ConversationSelectedEvent event,
    Emitter<MessageState> emit,
  ) async {
    // If no conversations are selected, clear everything
    if (event.conversationIds.isEmpty) {
      _currentConversationIds = {};
      _conversationCursors.clear(); // Clear cursors
      emit(const MessageLoaded(messages: []));
      return;
    }

    // Only load messages if the conversation selection has actually changed
    if (_currentConversationIds != event.conversationIds) {
      _currentConversationIds = event.conversationIds;
      _conversationCursors.clear(); // Clear cursors on conversation change
      add(LoadMessages(event.conversationIds));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    emit(const MessageLoading());
    _currentConversationIds = event.conversationIds;
    _conversationCursors.clear(); // Reset cursors on new load

    if (event.conversationIds.isEmpty) {
      emit(const MessageLoaded(messages: []));
      return;
    }

    try {
      // Initialize cursors for new conversations (null = start from now)
      final cursors = {for (final id in event.conversationIds) id: null};

      final result = await _getMessagesFromConversationsWithParticipantsUsecase(
        conversationCursors: cursors,
        count: _messagesPerPage,
      );

      if (result.isSuccess) {
        final resultData = result.valueOrNull!;
        final allMessages = resultData.messages;
        final participantMap = resultData.participants;
        final hasMoreMessages = resultData.hasMoreMessages;

        // Update cursors for each conversation based on the oldest message received for that conversation
        for (final conversationId in event.conversationIds) {
          final conversationMessages = allMessages.where(
            (m) => m.channelIds.contains(conversationId),
          );
          if (conversationMessages.isNotEmpty) {
            final oldestInConversation = conversationMessages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        }

        // Calculate overall oldest timestamp
        final oldestTimestamp = allMessages.isNotEmpty
            ? allMessages.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
            : null;

        // Map messages to UI models with participant data
        final enrichedMessages = allMessages.map((message) {
          final participant = participantMap[message.creatorId];
          return message.toUiModel(participant);
        }).toList();

        emit(
          MessageLoaded(
            messages: enrichedMessages,
            hasMoreMessages: hasMoreMessages,
            oldestMessageTimestamp: oldestTimestamp,
          ),
        );
      } else {
        _logger.e('Failed to load messages: ${result.failureOrNull}');
        emit(
          MessageError(
            'Failed to load messages: ${result.failureOrNull?.details ?? result.failureOrNull?.code}',
          ),
        );
      }
    } on Exception catch (e, stack) {
      _logger.e('Error loading messages from multiple conversations', error: e, stackTrace: stack);
      emit(MessageError('Failed to load messages: $e'));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<MessageState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessageLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;
    if (_currentConversationIds.isEmpty) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // Use current cursors for pagination
      final result = await _getMessagesFromConversationsWithParticipantsUsecase(
        conversationCursors: _conversationCursors,
        count: _messagesPerPage,
      );

      if (result.isSuccess) {
        final resultData = result.valueOrNull!;
        final newMessages = resultData.messages;
        final participantMap = resultData.participants;
        final hasMoreMessages = resultData.hasMoreMessages;

        // Update cursors for each conversation
        for (final conversationId in _currentConversationIds) {
          final conversationMessages = newMessages.where(
            (m) => m.channelIds.contains(conversationId),
          );
          if (conversationMessages.isNotEmpty) {
            final oldestInConversation = conversationMessages
                .map((m) => m.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b);
            _conversationCursors[conversationId] = oldestInConversation;
          }
        }

        // If no new messages were fetched, we've reached the end
        if (newMessages.isEmpty) {
          emit(
            currentState.copyWith(
              isLoadingMore: false,
              hasMoreMessages: false,
            ),
          );
          return;
        }

        // Sort new messages by date (newest first)
        newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Calculate new overall oldest timestamp
        final newOldestTimestamp = newMessages.isNotEmpty
            ? newMessages.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
            : currentState.oldestMessageTimestamp;

        // Map new messages to UI models with participant data
        final newEnrichedMessages = newMessages.map((message) {
          final participant = participantMap[message.creatorId];
          return message.toUiModel(participant);
        }).toList();

        // Append to existing messages
        final allMessages = [...currentState.messages, ...newEnrichedMessages];

        // Sort entire list by date (newest first) to maintain order across pagination batches
        allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(
          currentState.copyWith(
            messages: allMessages,
            isLoadingMore: false,
            hasMoreMessages: hasMoreMessages,
            oldestMessageTimestamp: newOldestTimestamp,
          ),
        );
      } else {
        _logger.w('Failed to load more messages: ${result.failureOrNull}');
        emit(currentState.copyWith(isLoadingMore: false));
      }
    } on Exception catch (e, stack) {
      _logger.e('Error loading more messages', error: e, stackTrace: stack);
      emit(currentState.copyWith(isLoadingMore: false));
      emit(MessageError('Failed to load more messages: $e'));
    }
  }

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentConversationIds.isEmpty) return;

    add(LoadMessages(_currentConversationIds));
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] File compiles without errors: `flutter analyze`
- [ ] Code formatting passes: `dart format --set-exit-if-changed lib/features/messages/`
- [ ] Injectable regeneration succeeds: `dart run build_runner build --delete-conflicting-outputs`
- [ ] All bloc tests pass: `flutter test test/features/messages/presentation_messages_dashboard/bloc/`

#### Manual Verification:
- [ ] Bloc no longer depends on UserRepository
- [ ] All caching logic has been removed
- [ ] Message loading uses new use case correctly
- [ ] Participant mapping works correctly

---

## Phase 4: Delete Old Use Case and Clean Up

### Overview
Remove the old use case file since it's been completely replaced.

### Changes Required

#### 1. Delete Old Use Case
**File**: `lib/features/messages/domain/usecases/get_messages_from_conversations_usecase.dart`

**Changes**: Delete entire file (it's been replaced by the new use case)

#### 2. Verify No Other References
**Action**: Search codebase for any remaining imports or usages of the old use case

```bash
# Search for references to the old use case
grep -r "GetMessagesFromConversationsUsecase" lib/
grep -r "get_messages_from_conversations_usecase" lib/
```

If any other files reference the old use case, update them to use the new one.

### Success Criteria

#### Automated Verification:
- [ ] No compilation errors after deletion: `flutter analyze`
- [ ] No import errors: `flutter analyze`
- [ ] Build runner completes: `dart run build_runner build --delete-conflicting-outputs`
- [ ] All tests pass: `flutter test`

#### Manual Verification:
- [ ] No references to old use case remain in codebase
- [ ] Dependency injection graph is clean (no dangling dependencies)

---

## Phase 5: Testing and Verification

### Overview
Run comprehensive tests to ensure the refactor works correctly.

### Testing Strategy

#### Unit Tests
**Location**: `test/features/messages/presentation_messages_dashboard/bloc/message_bloc_test.dart`

**Test Cases to Verify**:
- [ ] MessageBloc loads messages with participants correctly
- [ ] Pagination works with the new use case
- [ ] Conversation selection triggers correct use case calls
- [ ] Error handling works when use case fails
- [ ] Empty participant map is handled gracefully
- [ ] Messages without matching participants display correctly

#### Integration Tests
**Location**: Manual testing in the running app

**Scenarios to Test**:
1. **Initial Load**:
   - Select a single conversation
   - Verify messages load with creator names and avatars

2. **Multiple Conversations**:
   - Select multiple conversations
   - Verify messages from all conversations appear
   - Verify all participants from all conversations are included

3. **Pagination**:
   - Load initial messages
   - Scroll to bottom to trigger "load more"
   - Verify new messages load with correct participants

4. **Refresh**:
   - Load messages
   - Pull to refresh
   - Verify data reloads correctly

5. **Edge Cases**:
   - Conversation with no collaborators
   - Message creator not in collaborators list
   - Conversation fetch fails
   - Empty message list

### Manual Testing Steps

1. **Start the application**: `flutter run`

2. **Test Initial Load**:
   - Navigate to messages dashboard
   - Select a conversation
   - Verify: Messages display with correct creator names and avatars

3. **Test Multiple Conversations**:
   - Select 2-3 conversations
   - Verify: Messages from all conversations appear correctly
   - Verify: Creator information displays for all messages

4. **Test Pagination**:
   - Scroll to bottom of message list
   - Verify: "Load more" functionality works
   - Verify: New messages have correct participant data

5. **Test Refresh**:
   - Pull down to refresh
   - Verify: Messages reload correctly
   - Verify: No duplicate messages appear

6. **Test Edge Cases**:
   - Select conversation with many participants
   - Verify: Performance is acceptable
   - Test with slow network (Chrome DevTools throttling)

### Performance Considerations

#### Metrics to Monitor:
- Initial load time (should be comparable or better than before)
- Memory usage (no participant cache, but conversation data)
- Network requests (fewer total requests - no separate user fetches)

#### Performance Testing:
```bash
# Run performance tests
flutter test --profile test/performance/
```

### Success Criteria

#### Automated Verification:
- [ ] All unit tests pass: `flutter test`
- [ ] All integration tests pass (if any exist)
- [ ] No memory leaks detected
- [ ] Performance benchmarks pass

#### Manual Verification:
- [ ] Initial message load works correctly
- [ ] Multiple conversation selection works
- [ ] Pagination loads additional messages correctly
- [ ] Refresh functionality works
- [ ] Creator names and avatars display correctly
- [ ] Edge cases are handled gracefully
- [ ] No performance degradation observed
- [ ] No console errors or warnings appear

**Implementation Note**: After completing all phases and automated verification passes, the human must confirm that all manual testing scenarios pass before considering this refactor complete.

---

## Migration Notes

### Breaking Changes
None - this is an internal refactor that doesn't affect public APIs or external contracts.

### Rollback Plan
If issues are discovered:
1. Revert the commit containing these changes
2. The old use case and UserRepository approach will be restored
3. No data migration needed (all changes are in-memory)

### Future Enhancements
After this refactor, potential improvements:
1. Implement conversation caching in repository layer
2. Add optimistic updates for new messages
3. Consider WebSocket updates for real-time participant changes
4. Implement participant profile prefetching

---

## References

- Current bloc implementation: `lib/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart:1-278`
- Old use case: `lib/features/messages/domain/usecases/get_messages_from_conversations_usecase.dart:1-95`
- Conversation entity: `lib/features/conversations/domain/entities/conversation_entity.dart:1-276`
- Collaborator entity: `lib/features/conversations/domain/entities/conversation_collaborator.dart:1-46`
- Pattern reference: `lib/features/preview/domain/usecases/get_preview_composer_data_usecase.dart:12-22`
