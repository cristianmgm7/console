# Preview Visualization Implementation Plan

## Overview

This plan implements a complete preview visualization system for the Carbon Voice Console. The preview feature will display how a conversation podcast will look to end users, showing conversation metadata (name, description, participants with avatars/names, message count, total duration) and the selected messages in a format that replicates the Carbon Voice application's display patterns.

## Current State Analysis

### What Exists:
- ✅ `GetPreviewComposerDataUsecase` - Fetches conversation and messages
- ✅ `PreviewComposerBloc` - Manages metadata editing state
- ✅ `PreviewComposerScreen` - Displays metadata form for title/description/cover
- ✅ Domain entities: `Conversation` (with collaborators), `Message` (with duration, audioModels, textModels)
- ✅ `UserRepository` - For fetching user profiles with avatars and names
- ✅ Conversation entity contains `totalMessages`, `totalDurationMilliseconds`, and `collaborators` list

### What's Missing:
- ❌ **User profile enrichment** - Use case doesn't fetch participant user profiles
- ❌ **UI model** - No presentation model that combines conversation + messages + users
- ❌ **Preview visualization component** - No UI showing how the preview looks
- ❌ **Total duration calculation** - Need to sum durations from selected messages
- ❌ **Participant display** - Need to show participant avatars and names
- ❌ **Message list display** - Need to show selected messages in preview format
- ❌ **BLoC transformation** - BLoC needs to transform domain entities to UI model

## Desired End State

### User Experience:
1. User navigates to preview composer screen with selected conversation and messages
2. Screen loads and displays:
   - **Top Section**: Metadata form (title, description, cover image) - **Already exists**
   - **Bottom Section**: Preview visualization showing:
     - Conversation name
     - Conversation description
     - Participant grid with avatars and names
     - Message count (e.g., "5 messages")
     - Total duration of selected messages (e.g., "12:45")
     - List of selected messages with:
       - Creator avatar and name
       - Message creation timestamp
       - Message duration
       - Message summary/transcript text
       - Audio playback button (optional enhancement)
3. User can see exactly how their preview will look before publishing
4. User clicks "Publish Preview" when satisfied

### Technical Implementation:
- Use case fetches conversation, messages, AND user profiles for all participants
- BLoC transforms domain entities into a `PreviewUiModel` containing all display-ready data
- BLoC state holds the UI model in `PreviewComposerLoaded`
- Preview visualization widget renders the UI model
- All formatting (duration MM:SS, participant names) happens in UI model mapper

### Verification:
**Automated:**
- [ ] Code generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] All imports resolve: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/`

**Manual:**
- [ ] Preview screen loads with conversation data
- [ ] Participant avatars and names display correctly
- [ ] Message count displays correctly (matches selected messages)
- [ ] Total duration displays in MM:SS format
- [ ] Selected messages display with creator info, timestamps, and summaries
- [ ] Preview accurately represents how Carbon Voice displays conversations

## What We're NOT Doing

- ❌ Audio playback in preview (can be added later)
- ❌ Editing participants or messages from preview screen
- ❌ Real-time preview updates (preview is snapshot at load time)
- ❌ Downloading audio from preview
- ❌ Waveform visualization (can reuse existing patterns if needed later)
- ❌ Publishing API integration changes (out of scope)

## Implementation Approach

We'll follow the existing codebase patterns:
1. Create **UI model** and **mapper** (following `MessageUiModel` and `MessageUiMapper` patterns)
2. Enhance **use case** to fetch user profiles (inject `UserRepository`)
3. Update **BLoC** to transform domain entities to UI model
4. Create **preview visualization widget** (reuse existing app components)
5. Integrate visualization into **preview composer screen**

---

## Phase 1: Create UI Model and Mapper

### Overview
Create a presentation-layer model that combines conversation, messages, and user data into a single, display-ready structure. This follows the existing pattern used by `MessageUiModel` and `VoiceMemoUiModel`.

### Changes Required:

#### 1. Create PreviewUiModel
**File**: `lib/features/preview/presentation/models/preview_ui_model.dart` (NEW)

```dart
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

/// UI model for preview visualization
/// Contains all display-ready data for the preview screen
class PreviewUiModel extends Equatable {
  const PreviewUiModel({
    required this.conversationName,
    required this.conversationDescription,
    required this.conversationCoverUrl,
    required this.participants,
    required this.messageCount,
    required this.totalDuration,
    required this.totalDurationFormatted,
    required this.messages,
  });

  // Conversation metadata
  final String conversationName;
  final String conversationDescription;
  final String? conversationCoverUrl;

  // Participants
  final List<PreviewParticipant> participants;

  // Message statistics
  final int messageCount;
  final Duration totalDuration;
  final String totalDurationFormatted; // MM:SS format

  // Selected messages with creator info
  final List<PreviewMessage> messages;

  @override
  List<Object?> get props => [
        conversationName,
        conversationDescription,
        conversationCoverUrl,
        participants,
        messageCount,
        totalDuration,
        totalDurationFormatted,
        messages,
      ];
}

/// Participant in the conversation
class PreviewParticipant extends Equatable {
  const PreviewParticipant({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, fullName, avatarUrl];
}

/// Message for preview display
class PreviewMessage extends Equatable {
  const PreviewMessage({
    required this.id,
    required this.creatorName,
    required this.creatorAvatarUrl,
    required this.createdAt,
    required this.createdAtFormatted,
    required this.duration,
    required this.durationFormatted,
    required this.summary,
    required this.audioUrl,
  });

  final String id;
  final String creatorName;
  final String? creatorAvatarUrl;
  final DateTime createdAt;
  final String createdAtFormatted; // e.g., "12/11/25 2:30 PM"
  final Duration duration;
  final String durationFormatted; // MM:SS format
  final String? summary;
  final String? audioUrl;

  @override
  List<Object?> get props => [
        id,
        creatorName,
        creatorAvatarUrl,
        createdAt,
        createdAtFormatted,
        duration,
        durationFormatted,
        summary,
        audioUrl,
      ];
}
```

#### 2. Create PreviewUiMapper
**File**: `lib/features/preview/presentation/mappers/preview_ui_mapper.dart` (NEW)

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Extension methods to create preview UI models from domain entities
extension PreviewUiMapper on Conversation {
  /// Creates a preview UI model from conversation, messages, and user data
  ///
  /// [messages] - Selected messages to include in preview
  /// [userMap] - Map of userId -> User for enrichment
  PreviewUiModel toPreviewUiModel(
    List<Message> messages,
    Map<String, User> userMap,
  ) {
    // Calculate total duration from selected messages
    final totalDuration = messages.fold<Duration>(
      Duration.zero,
      (sum, message) => sum + message.duration,
    );

    // Get unique participants from conversation collaborators
    final participantsList = _mapParticipants(userMap);

    // Map messages with creator info
    final previewMessages = messages.map((message) {
      return _mapMessage(message, userMap);
    }).toList();

    return PreviewUiModel(
      conversationName: name,
      conversationDescription: description ?? '',
      conversationCoverUrl: imageUrl,
      participants: participantsList,
      messageCount: messages.length,
      totalDuration: totalDuration,
      totalDurationFormatted: _formatDuration(totalDuration),
      messages: previewMessages,
    );
  }

  /// Maps conversation collaborators to preview participants
  List<PreviewParticipant> _mapParticipants(Map<String, User> userMap) {
    if (collaborators == null || collaborators!.isEmpty) {
      return [];
    }

    return collaborators!.map((collaborator) {
      // Try to get user from map, fallback to collaborator data
      final user = userMap[collaborator.userGuid];
      return PreviewParticipant(
        id: collaborator.userGuid,
        fullName: user?.fullName ??
                  '${collaborator.firstName ?? ''} ${collaborator.lastName ?? ''}'.trim(),
        avatarUrl: user?.avatarUrl ?? collaborator.imageUrl,
      );
    }).toList();
  }

  /// Maps a message to preview message with creator info
  PreviewMessage _mapMessage(Message message, Map<String, User> userMap) {
    final creator = userMap[message.creatorId];

    return PreviewMessage(
      id: message.id,
      creatorName: creator?.fullName ?? message.creatorId,
      creatorAvatarUrl: creator?.avatarUrl,
      createdAt: message.createdAt,
      createdAtFormatted: _formatDateTime(message.createdAt),
      duration: message.duration,
      durationFormatted: _formatDuration(message.duration),
      summary: _getMessageText(message.textModels),
      audioUrl: _getPlayableAudioUrl(message.audioModels),
    );
  }

  /// Formats duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats datetime as "MM/DD/YY h:mm A"
  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString().substring(2);
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hour:$minute $period';
  }

  /// Gets summary or transcript text from message
  String? _getMessageText(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    // Priority: summary > transcription > first text
    final summary = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'summary',
      orElse: () => null,
    );
    if (summary != null && summary.text.isNotEmpty) return summary.text;

    final transcription = textModels.cast<TextModel?>().firstWhere(
      (model) => model?.type.toLowerCase() == 'transcription',
      orElse: () => null,
    );
    if (transcription != null && transcription.text.isNotEmpty) {
      return transcription.text;
    }

    return textModels.first.text.isNotEmpty ? textModels.first.text : null;
  }

  /// Gets playable audio URL (MP3 preferred)
  String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    try {
      final mp3Audio = audioModels.firstWhere(
        (audio) => audio.format == 'mp3',
      );
      return mp3Audio.presignedUrl ?? mp3Audio.url;
    } on StateError {
      return audioModels.first.presignedUrl ?? audioModels.first.url;
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Files created successfully
- [ ] No import errors: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/features/preview/`
- [ ] Models extend Equatable correctly
- [ ] All fields are final and immutable

#### Manual Verification:
- [ ] PreviewUiModel structure matches requirements
- [ ] Mapper logic correctly formats durations as MM:SS
- [ ] Mapper logic correctly formats dates
- [ ] Participant mapping handles missing user data gracefully
- [ ] Message text extraction prioritizes summary > transcription

---

## Phase 2: Enhance Use Case for User Profile Fetching

### Overview
Update `GetPreviewComposerDataUsecase` to fetch user profiles for all conversation participants. This enriches the domain data with user information needed for display.

### Changes Required:

#### 1. Update GetPreviewComposerDataUsecase
**File**: `lib/features/preview/domain/usecases/get_preview_composer_data_usecase.dart`

**Changes**:
1. Inject `UserRepository` via constructor
2. After fetching conversation and messages, extract all participant user IDs
3. Fetch user profiles in parallel
4. Return enriched data structure

```dart
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Result containing conversation, messages, users, and initial metadata
class EnrichedPreviewComposerData {
  const EnrichedPreviewComposerData({
    required this.composerData,
    required this.userMap,
  });

  final PreviewComposerData composerData;
  final Map<String, User> userMap; // userId -> User
}

@injectable
class GetPreviewComposerDataUsecase {
  GetPreviewComposerDataUsecase(
    this._conversationRepository,
    this._messageRepository,
    this._userRepository, // INJECT UserRepository
    this._logger,
  );

  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final UserRepository _userRepository; // NEW
  final Logger _logger;

  /// Fetches all data needed for the preview composer screen
  ///
  /// [conversationId] - The conversation to preview
  /// [messageIds] - List of 3-5 message IDs selected by user
  ///
  /// Returns EnrichedPreviewComposerData with conversation, messages, users, and metadata
  Future<Result<EnrichedPreviewComposerData>> call({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Fetching preview composer data');
      _logger.d('Conversation ID: $conversationId');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

      // Validate message count
      if (messageIds.length < 3 || messageIds.length > 5) {
        _logger.w('Invalid message count: ${messageIds.length}');
        return failure(const UnknownFailure(
          details: 'Please select between 3 and 5 messages',
        ));
      }

      // Fetch conversation details
      final conversationResult = await _conversationRepository.getConversation(
        conversationId,
      );

      // Early return if conversation fetch failed
      final conversation = conversationResult.fold(
        onSuccess: (conv) => conv,
        onFailure: (failure) {
          _logger.e('Failed to fetch conversation: ${failure.failure.code}');
          return null;
        },
      );

      if (conversation == null) {
        return failure(const UnknownFailure(
          details: 'Failed to fetch conversation',
        ));
      }

      // Fetch all selected messages in parallel
      final messageFutures = messageIds.map((messageId) =>
        _messageRepository.getMessage(messageId)).toList();

      final messageResults = await Future.wait(messageFutures);

      // Extract messages, collecting failures
      final messages = <Message>[];
      for (var i = 0; i < messageResults.length; i++) {
        final result = messageResults[i];
        result.fold(
          onSuccess: (message) {
            messages.add(message);
          },
          onFailure: (failure) {
            _logger.w(
              'Failed to fetch message ${messageIds[i]}: ${failure.failure.code}',
            );
            // Continue fetching other messages even if one fails
          },
        );
      }

      // Ensure we have at least 3 messages
      if (messages.length < 3) {
        _logger.e('Insufficient messages fetched: ${messages.length}');
        return failure(const UnknownFailure(
          details: 'Could not load enough messages for preview',
        ));
      }

      // Extract all user IDs from conversation collaborators and message creators
      final userIds = <String>{};

      // Add message creator IDs
      for (final message in messages) {
        userIds.add(message.creatorId);
      }

      // Add conversation collaborators
      if (conversation.collaborators != null) {
        for (final collaborator in conversation.collaborators!) {
          userIds.add(collaborator.userGuid);
        }
      }

      _logger.d('Fetching ${userIds.length} user profiles');

      // Fetch all user profiles in batch
      final usersResult = await _userRepository.getUsers(userIds.toList());

      final userMap = <String, User>{};
      usersResult.fold(
        onSuccess: (users) {
          for (final user in users) {
            userMap[user.id] = user;
          }
          _logger.d('Loaded ${userMap.length} user profiles');
        },
        onFailure: (failure) {
          _logger.w('Failed to fetch some users: ${failure.failure.code}');
          // Continue without user enrichment
        },
      );

      // Create initial metadata from conversation
      final initialMetadata = PreviewMetadata(
        title: conversation.name,
        description: conversation.description ?? '',
        coverImageUrl: conversation.imageUrl,
      );

      final composerData = PreviewComposerData(
        conversation: conversation,
        selectedMessages: messages,
        initialMetadata: initialMetadata,
      );

      final enrichedData = EnrichedPreviewComposerData(
        composerData: composerData,
        userMap: userMap,
      );

      _logger.i('Successfully fetched preview composer data with ${userMap.length} users');
      return success(enrichedData);
    } on Failure<EnrichedPreviewComposerData> catch (failure) {
      // Already logged in fold
      return failure;
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching preview data', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze`
- [ ] Dependency injection recognizes new parameter: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] UserRepository properly injected via GetIt
- [ ] No import errors

#### Manual Verification:
- [ ] Use case successfully fetches user profiles
- [ ] User map contains all participants and message creators
- [ ] User fetching doesn't block if some users fail to load
- [ ] Logger outputs show user count fetched

---

## Phase 3: Update BLoC to Use UI Model

### Overview
Update `PreviewComposerBloc` and `PreviewComposerState` to transform domain entities into `PreviewUiModel` and store it in state. This makes the UI layer consume presentation-ready data.

### Changes Required:

#### 1. Update PreviewComposerState
**File**: `lib/features/preview/presentation/bloc/preview_composer_state.dart`

**Changes**: Add `previewUiModel` field to `PreviewComposerLoaded` state

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:equatable/equatable.dart';

sealed class PreviewComposerState extends Equatable {
  const PreviewComposerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class PreviewComposerInitial extends PreviewComposerState {
  const PreviewComposerInitial();
}

/// Loading conversation and message data
class PreviewComposerLoading extends PreviewComposerState {
  const PreviewComposerLoading();
}

/// Data loaded successfully, ready for user input
class PreviewComposerLoaded extends PreviewComposerState {
  const PreviewComposerLoaded({
    required this.composerData,
    required this.currentMetadata,
    required this.previewUiModel, // NEW
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
  });

  final PreviewComposerData composerData;
  final PreviewMetadata currentMetadata;
  final PreviewUiModel previewUiModel; // NEW - UI model for visualization
  final String? titleError;
  final String? descriptionError;
  final String? coverImageUrlError;

  bool get isValid =>
      currentMetadata.title.trim().isNotEmpty &&
      currentMetadata.description.trim().isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      coverImageUrlError == null;

  @override
  List<Object?> get props => [
        composerData,
        currentMetadata,
        previewUiModel, // NEW
        titleError,
        descriptionError,
        coverImageUrlError,
      ];

  PreviewComposerLoaded copyWith({
    PreviewComposerData? composerData,
    PreviewMetadata? currentMetadata,
    PreviewUiModel? previewUiModel, // NEW
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
  }) {
    return PreviewComposerLoaded(
      composerData: composerData ?? this.composerData,
      currentMetadata: currentMetadata ?? this.currentMetadata,
      previewUiModel: previewUiModel ?? this.previewUiModel, // NEW
      titleError: titleError,
      descriptionError: descriptionError,
      coverImageUrlError: coverImageUrlError,
    );
  }
}

/// Publishing preview in progress
class PreviewComposerPublishing extends PreviewComposerState {
  const PreviewComposerPublishing({
    required this.composerData,
    required this.metadata,
  });

  final PreviewComposerData composerData;
  final PreviewMetadata metadata;

  @override
  List<Object?> get props => [composerData, metadata];
}

/// Preview published successfully
class PreviewComposerPublishSuccess extends PreviewComposerState {
  const PreviewComposerPublishSuccess({
    required this.previewUrl,
  });

  final String previewUrl;

  @override
  List<Object?> get props => [previewUrl];
}

/// Error loading data or publishing
class PreviewComposerError extends PreviewComposerState {
  const PreviewComposerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

#### 2. Update PreviewComposerBloc
**File**: `lib/features/preview/presentation/bloc/preview_composer_bloc.dart`

**Changes**: Transform enriched data to UI model in `_onStarted` handler

```dart
import 'package:carbon_voice_console/features/preview/domain/usecases/get_preview_composer_data_usecase.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/publish_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/mappers/preview_ui_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerBloc
    extends Bloc<PreviewComposerEvent, PreviewComposerState> {
  PreviewComposerBloc(
    this._getPreviewComposerDataUsecase,
    this._publishPreviewUsecase,
    this._logger,
  ) : super(const PreviewComposerInitial()) {
    on<PreviewComposerStarted>(_onStarted);
    on<PreviewTitleUpdated>(_onTitleUpdated);
    on<PreviewDescriptionUpdated>(_onDescriptionUpdated);
    on<PreviewCoverImageUpdated>(_onCoverImageUpdated);
    on<PreviewPublishRequested>(_onPublishRequested);
    on<PreviewComposerReset>(_onReset);
  }

  final GetPreviewComposerDataUsecase _getPreviewComposerDataUsecase;
  final PublishPreviewUsecase _publishPreviewUsecase;
  final Logger _logger;

  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 200;

  Future<void> _onStarted(
    PreviewComposerStarted event,
    Emitter<PreviewComposerState> emit,
  ) async {
    emit(const PreviewComposerLoading());

    final result = await _getPreviewComposerDataUsecase(
      conversationId: event.conversationId,
      messageIds: event.messageIds,
    );

    result.fold(
      onSuccess: (enrichedData) {
        _logger.i('Preview composer data loaded successfully');

        // Transform to UI model using mapper
        final previewUiModel = enrichedData.composerData.conversation
            .toPreviewUiModel(
          enrichedData.composerData.selectedMessages,
          enrichedData.userMap,
        );

        emit(PreviewComposerLoaded(
          composerData: enrichedData.composerData,
          currentMetadata: enrichedData.composerData.initialMetadata,
          previewUiModel: previewUiModel, // NEW - UI model
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to load preview composer data: ${failure.failure.code}');
        emit(PreviewComposerError(
          failure.failure.details ?? 'Failed to load preview data',
        ));
      },
    );
  }

  // Rest of the BLoC methods remain unchanged
  void _onTitleUpdated(
    PreviewTitleUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.title.trim().isEmpty) {
      error = 'Title is required';
    } else if (event.title.trim().length > maxTitleLength) {
      error = 'Title must be $maxTitleLength characters or less';
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      title: event.title,
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      titleError: error,
    ));
  }

  void _onDescriptionUpdated(
    PreviewDescriptionUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.description.trim().isEmpty) {
      error = 'Description is required';
    } else if (event.description.trim().length > maxDescriptionLength) {
      error = 'Description must be $maxDescriptionLength characters or less';
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      description: event.description,
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      descriptionError: error,
    ));
  }

  void _onCoverImageUpdated(
    PreviewCoverImageUpdated event,
    Emitter<PreviewComposerState> emit,
  ) {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;
    String? error;

    if (event.coverImageUrl != null && event.coverImageUrl!.trim().isNotEmpty) {
      final uri = Uri.tryParse(event.coverImageUrl!);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Invalid URL format';
      }
    }

    final updatedMetadata = loadedState.currentMetadata.copyWith(
      coverImageUrl: event.coverImageUrl?.trim(),
    );

    emit(loadedState.copyWith(
      currentMetadata: updatedMetadata,
      coverImageUrlError: error,
    ));
  }

  Future<void> _onPublishRequested(
    PreviewPublishRequested event,
    Emitter<PreviewComposerState> emit,
  ) async {
    if (state is! PreviewComposerLoaded) return;

    final loadedState = state as PreviewComposerLoaded;

    // Final validation
    if (!loadedState.isValid) {
      _logger.w('Publish requested but form is invalid');
      return;
    }

    emit(PreviewComposerPublishing(
      composerData: loadedState.composerData,
      metadata: loadedState.currentMetadata,
    ));

    final messageIds = loadedState.composerData.selectedMessages
        .map((msg) => msg.id)
        .toList();

    final result = await _publishPreviewUsecase(
      conversationId: loadedState.composerData.conversation.id,
      metadata: loadedState.currentMetadata,
      messageIds: messageIds,
    );

    result.fold(
      onSuccess: (previewUrl) {
        _logger.i('Preview published successfully: $previewUrl');
        emit(PreviewComposerPublishSuccess(previewUrl: previewUrl));
      },
      onFailure: (failure) {
        _logger.e('Failed to publish preview: ${failure.failure.code}');
        // Return to loaded state with error message
        emit(PreviewComposerError(
          failure.failure.details ?? 'Failed to publish preview',
        ));
      },
    );
  }

  void _onReset(
    PreviewComposerReset event,
    Emitter<PreviewComposerState> emit,
  ) {
    emit(const PreviewComposerInitial());
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No type errors: `flutter analyze`
- [ ] Imports resolve correctly
- [ ] BLoC compiles with new state structure

#### Manual Verification:
- [ ] BLoC successfully transforms domain data to UI model
- [ ] PreviewComposerLoaded state contains previewUiModel
- [ ] UI model contains correct participant count
- [ ] UI model contains correct message count
- [ ] UI model total duration matches sum of selected messages
- [ ] Logger shows successful data transformation

---

## Phase 4: Create Preview Visualization Widget

### Overview
Create a reusable widget that displays the preview visualization using the `PreviewUiModel`. This widget shows conversation metadata, participants, statistics, and selected messages in a card-based layout.

### Changes Required:

#### 1. Create PreviewVisualization Widget
**File**: `lib/features/preview/presentation/widgets/preview_visualization.dart` (NEW)

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar_grid.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_message_item.dart';
import 'package:flutter/material.dart';

/// Widget that visualizes how the preview will look to end users
/// Displays conversation metadata, participants, statistics, and messages
class PreviewVisualization extends StatelessWidget {
  const PreviewVisualization({
    required this.preview,
    super.key,
  });

  final PreviewUiModel preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Preview',
              style: AppTextStyle.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is how your conversation preview will appear',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Conversation header section
            _buildConversationHeader(context),
            const SizedBox(height: 24),

            // Statistics section
            _buildStatistics(context),
            const SizedBox(height: 24),

            // Participants section
            if (preview.participants.isNotEmpty) ...[
              _buildParticipantsSection(context),
              const SizedBox(height: 24),
            ],

            // Messages section
            _buildMessagesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        if (preview.conversationCoverUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(preview.conversationCoverUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (preview.conversationCoverUrl != null) const SizedBox(height: 16),

        // Conversation name
        Text(
          preview.conversationName,
          style: AppTextStyle.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Conversation description
        if (preview.conversationDescription.isNotEmpty)
          Text(
            preview.conversationDescription,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Row(
      children: [
        // Message count
        _buildStatItem(
          context,
          icon: Icons.message_outlined,
          label: 'Messages',
          value: preview.messageCount.toString(),
        ),
        const SizedBox(width: 24),

        // Total duration
        _buildStatItem(
          context,
          icon: Icons.access_time,
          label: 'Duration',
          value: preview.totalDurationFormatted,
        ),
        const SizedBox(width: 24),

        // Participants count
        _buildStatItem(
          context,
          icon: Icons.people_outline,
          label: 'Participants',
          value: preview.participants.length.toString(),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ParticipantAvatarGrid(participants: preview.participants),
      ],
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Messages',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...preview.messages.map((message) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PreviewMessageItem(message: message),
          );
        }),
      ],
    );
  }
}
```

#### 2. Create ParticipantAvatarGrid Widget
**File**: `lib/features/preview/presentation/widgets/participant_avatar_grid.dart` (NEW)

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:flutter/material.dart';

/// Displays participant avatars and names in a grid layout
class ParticipantAvatarGrid extends StatelessWidget {
  const ParticipantAvatarGrid({
    required this.participants,
    super.key,
  });

  final List<PreviewParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: participants.map((participant) {
        return _buildParticipantItem(context, participant);
      }).toList(),
    );
  }

  Widget _buildParticipantItem(
    BuildContext context,
    PreviewParticipant participant,
  ) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: participant.avatarUrl != null
                ? NetworkImage(participant.avatarUrl!)
                : null,
            child: participant.avatarUrl == null
                ? Text(
                    _getInitials(participant.fullName),
                    style: AppTextStyle.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            participant.fullName,
            style: AppTextStyle.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
```

#### 3. Create PreviewMessageItem Widget
**File**: `lib/features/preview/presentation/widgets/preview_message_item.dart` (NEW)

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:flutter/material.dart';

/// Displays a single message in the preview visualization
class PreviewMessageItem extends StatelessWidget {
  const PreviewMessageItem({
    required this.message,
    super.key,
  });

  final PreviewMessage message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: message.creatorAvatarUrl != null
                  ? NetworkImage(message.creatorAvatarUrl!)
                  : null,
              child: message.creatorAvatarUrl == null
                  ? Text(
                      _getInitials(message.creatorName),
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator name and timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.creatorName,
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        message.createdAtFormatted,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.durationFormatted,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Message summary/text
                  if (message.summary != null)
                    Text(
                      message.summary!,
                      style: AppTextStyle.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All widget files compile: `flutter analyze`
- [ ] No import errors
- [ ] Widgets use existing app theme constants (AppColors, AppTextStyle)

#### Manual Verification:
- [ ] Preview visualization displays conversation name
- [ ] Preview visualization displays conversation description
- [ ] Cover image displays when present
- [ ] Statistics show correct message count
- [ ] Statistics show formatted total duration (MM:SS)
- [ ] Participant grid shows all participants with avatars/initials
- [ ] Participant names display correctly
- [ ] Messages display with creator avatar/name
- [ ] Messages display formatted timestamps
- [ ] Messages display formatted durations
- [ ] Message summaries display with ellipsis for long text

---

## Phase 5: Integrate Visualization into Composer Screen

### Overview
Update `PreviewComposerScreen` to display the `PreviewVisualization` widget below the metadata form when data is loaded.

### Changes Required:

#### 1. Update PreviewComposerScreen
**File**: `lib/features/preview/presentation/screens/preview_composer_screen.dart`

**Changes**: Add PreviewVisualization widget to `_buildLoadedView` method

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_visualization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview
/// Receives conversationId and messageIds as parameters, fetches own data
class PreviewComposerScreen extends StatefulWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    required this.messageIds,
    super.key,
  });

  final String conversationId;
  final List<String> messageIds;

  @override
  State<PreviewComposerScreen> createState() => _PreviewComposerScreenState();
}

class _PreviewComposerScreenState extends State<PreviewComposerScreen> {
  @override
  void initState() {
    super.initState();

    // Start the BLoC - it will fetch conversation and message data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreviewComposerBloc>().add(
            PreviewComposerStarted(
              conversationId: widget.conversationId,
              messageIds: widget.messageIds,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreviewComposerBloc, PreviewComposerState>(
      listener: (context, state) {
        // Listen for publish success
        if (state is PreviewComposerPublishSuccess) {
          // Navigate to confirmation screen
          context.go(
            '${AppRoutes.previewConfirmation}?url=${Uri.encodeComponent(state.previewUrl)}',
          );

          // Reset BLoC state
          context.read<PreviewComposerBloc>().add(const PreviewComposerReset());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
            builder: (context, state) {
              return switch (state) {
                PreviewComposerInitial() => const Center(
                    child: Text('Initializing...'),
                  ),
                PreviewComposerLoading() => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading conversation details...'),
                      ],
                    ),
                  ),
                PreviewComposerError(message: final message) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go(AppRoutes.dashboard),
                          child: const Text('Back to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                PreviewComposerLoaded() => _buildLoadedView(context, state),
                PreviewComposerPublishing() => _buildPublishingView(context, state),
                PreviewComposerPublishSuccess() => const Center(
                    child: CircularProgressIndicator(),
                  ),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    PreviewComposerLoaded state,
  ) {
    final selectedCount = state.composerData.selectedMessages.length;
    final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversation info
          Text(
            'Creating preview for:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            state.composerData.conversation.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Selection counter
          MessageSelectionCounter(
            selectedCount: selectedCount,
            minCount: 3,
            maxCount: 5,
          ),

          if (!isValidSelection) ...[
            const SizedBox(height: 8),
            Text(
              'Please select between 3 and 5 messages.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
          ],

          const SizedBox(height: 24),

          // Form title
          Text(
            'Preview Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Metadata form
          const PreviewMetadataForm(),
          const SizedBox(height: 32),

          // NEW: Preview Visualization
          PreviewVisualization(preview: state.previewUiModel),
          const SizedBox(height: 32),

          // Publish button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.publish),
              label: const Text('Publish Preview'),
              onPressed: isValidSelection && state.isValid
                  ? () {
                      context.read<PreviewComposerBloc>().add(
                            const PreviewPublishRequested(),
                          );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishingView(
    BuildContext context,
    PreviewComposerPublishing state,
  ) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Publishing preview...'),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Screen compiles: `flutter analyze`
- [ ] No import errors
- [ ] PreviewVisualization widget renders without errors

#### Manual Verification:
- [ ] Preview screen displays metadata form at top
- [ ] Preview visualization appears below form
- [ ] Visualization shows all conversation metadata
- [ ] Visualization shows all participants
- [ ] Visualization shows all selected messages
- [ ] Publish button remains at bottom
- [ ] Scroll works smoothly through entire content
- [ ] Layout is visually balanced and readable

---

## Phase 6: Run Code Generation and Test

### Overview
Generate dependency injection code and perform comprehensive manual testing to ensure the entire preview flow works end-to-end.

### Changes Required:

#### 1. Run Code Generation
**Command**: `flutter pub run build_runner build --delete-conflicting-outputs`

This will:
- Register `UserRepository` injection in `GetPreviewComposerDataUsecase`
- Update dependency injection configuration
- Ensure all `@injectable` classes are registered

#### 2. Verify Dependency Injection
**File**: Check `lib/core/di/injection.config.dart` (GENERATED)

Verify that:
- `GetPreviewComposerDataUsecase` constructor receives `UserRepository`
- `PreviewComposerBloc` is properly registered
- All dependencies resolve correctly

### Success Criteria:

#### Automated Verification:
- [ ] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No analyzer errors: `flutter analyze`
- [ ] No type errors or warnings
- [ ] Code formatting passes: `dart format lib/features/preview/`
- [ ] App builds successfully: `flutter build web` or `flutter build macos`

#### Manual Verification (End-to-End Testing):
- [ ] Navigate to dashboard with selected messages
- [ ] Click "Preview" button
- [ ] Preview composer screen loads without errors
- [ ] Loading state displays while fetching data
- [ ] Loaded state displays with:
  - [ ] Metadata form (title, description, cover URL)
  - [ ] Preview visualization section
  - [ ] Conversation name displays correctly
  - [ ] Conversation description displays correctly
  - [ ] Cover image displays when URL provided
  - [ ] Participant count matches conversation collaborators
  - [ ] Participant avatars display correctly
  - [ ] Participant names display correctly
  - [ ] Message count matches selected messages (3-5)
  - [ ] Total duration displays in MM:SS format
  - [ ] Total duration equals sum of individual message durations
  - [ ] All selected messages display in list
  - [ ] Each message shows:
    - [ ] Creator avatar (or initials)
    - [ ] Creator name
    - [ ] Formatted timestamp
    - [ ] Formatted duration (MM:SS)
    - [ ] Message summary/transcript text
- [ ] Edit title/description/cover in form
- [ ] Preview visualization does NOT update (snapshot behavior)
- [ ] Publish button enables when form valid
- [ ] Click publish (test publishing flow still works)

#### Edge Case Testing:
- [ ] Preview with conversation that has no collaborators
- [ ] Preview with messages from users not in collaborators list
- [ ] Preview with messages that have no summary (show transcript fallback)
- [ ] Preview with messages that have no transcript (show empty)
- [ ] Preview with users who have no avatar (show initials)
- [ ] Preview with very long message summaries (check ellipsis)
- [ ] Preview with very short total duration (e.g., "0:45")
- [ ] Preview with very long total duration (e.g., "125:30")

#### Performance Testing:
- [ ] Preview loads within 2-3 seconds with normal network
- [ ] User profile fetching doesn't significantly delay load time
- [ ] Scrolling through preview is smooth
- [ ] No memory leaks when navigating away from preview

**Implementation Note**: After all automated verification passes and manual testing confirms the feature works correctly, this implementation is complete and ready for user review.

---

## Testing Strategy

### Unit Tests (Future Enhancement):
- `PreviewUiMapper.toPreviewUiModel()` - Verify transformation logic
- `PreviewUiMapper._formatDuration()` - Verify MM:SS formatting
- `PreviewUiMapper._formatDateTime()` - Verify timestamp formatting
- `PreviewUiMapper._getMessageText()` - Verify text priority logic
- `GetPreviewComposerDataUsecase.call()` - Verify user fetching logic

### Widget Tests (Future Enhancement):
- `PreviewVisualization` - Verify all sections render
- `ParticipantAvatarGrid` - Verify avatar display logic
- `PreviewMessageItem` - Verify message display

### Integration Tests (Future Enhancement):
- End-to-end preview creation flow
- Verify data flows from use case → BLoC → UI
- Verify user profile enrichment works

### Manual Testing Steps:
See Phase 6 Success Criteria - Manual Verification section above.

---

## Performance Considerations

### User Profile Fetching:
- ✅ Batch fetch with `UserRepository.getUsers()` - minimizes API calls
- ✅ UserRepository has in-memory cache - reduces redundant fetches
- ✅ Fetching happens in parallel with messages - doesn't block load
- ✅ Partial failures allowed - preview shows without some user data

### UI Rendering:
- ✅ Use `const` constructors where possible
- ✅ PreviewUiModel is immutable - safe for caching
- ✅ Formatting done once in mapper - not recalculated on rebuilds
- ✅ Card-based layout with controlled image sizes - prevents memory bloat

### State Management:
- ✅ UI model created once on load - not recalculated on metadata edits
- ✅ BLoC only updates metadata state - preview visualization stays stable
- ✅ Equatable props ensure efficient change detection

---

## Migration Notes

### Breaking Changes:
- `GetPreviewComposerDataUsecase.call()` now returns `EnrichedPreviewComposerData` instead of `PreviewComposerData`
  - **Impact**: Existing code calling this use case directly will break
  - **Mitigation**: Only `PreviewComposerBloc` calls this use case, which is updated in this plan

### Data Structure Changes:
- `PreviewComposerLoaded` state now includes `previewUiModel` field
  - **Impact**: Any code reading this state needs to handle new field
  - **Mitigation**: Only `PreviewComposerScreen` reads this state, which is updated in this plan

### No Database/API Changes:
- ✅ No API changes required
- ✅ No database migrations required
- ✅ Uses existing endpoints and repositories

---

## References

### Original Requirements:
- User request in conversation context (see conversation history)

### Similar Implementations:
- **MessageUiModel**: `lib/features/messages/presentation_messages_dashboard/models/message_ui_model.dart`
- **MessageUiMapper**: `lib/features/messages/presentation_messages_dashboard/mappers/message_ui_mapper.dart`
- **VoiceMemoUiModel**: `lib/features/voice_memos/presentation/models/voice_memo_ui_model.dart`
- **MessageDetailContent**: `lib/features/messages/presentation_messages_detail/components/message_detail_content.dart`

### Related Features:
- **User Repository**: `lib/features/users/domain/repositories/user_repository.dart`
- **Conversation Display**: `lib/features/conversations/presentation/widgets/conversation_cover_art.dart`
- **Message Display**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_content_container.dart`

### Architecture Documentation:
- **CLAUDE.md**: `/Users/cristian/Documents/tech/carbon_voice_console/CLAUDE.md`
