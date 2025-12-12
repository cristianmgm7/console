# Preview Feature - BLoC Architecture Refactor Implementation Plan

## Overview

This plan replaces the current Cubit-based UI demo implementation with a fully isolated, BLoC-based architecture for the public conversation preview feature. The new approach passes only primitive values (conversationId and messageIds) to the preview screen, where a dedicated PreviewComposerBloc orchestrates all data fetching, state management, and business logic without dependencies on dashboard-level providers.

**Goal**: Create a clean, self-contained preview feature that fetches its own data, manages its own state, and operates independently from the dashboard context.

## Current State Analysis

### What Exists:
- **UI Demo Implementation**: Cubit-based preview feature with mock publish ([preview_composer_cubit.dart](lib/features/preview/presentation/cubit/preview_composer_cubit.dart))
- **Current Flow**: Dashboard → passes conversationId → PreviewComposerScreen initializes from ConversationBloc state → Cubit handles form validation → mock publish
- **State Dependencies**: PreviewComposerScreen reads from `ConversationBloc` in initState to pre-fill form data ([preview_composer_screen.dart:35-49](lib/features/preview/presentation/screens/preview_composer_screen.dart#L35-L49))
- **Message Selection**: `MessageSelectionCubit` tracks selected messages in dashboard ([message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart))
- **Existing Repositories**:
  - `ConversationRepository.getConversation(conversationId)` - fetches single conversation
  - `MessageRepository.getMessage(messageId)` - fetches single message
- **Routing**: Routes accept query parameters, wrapped in `blocProvidersPreview()` provider ([app_router.dart:95-124](lib/core/routing/app_router.dart#L95-L124))

### What's Missing:
- **Domain Layer**: No entities for preview-specific data structures
- **Data Layer**: No repository or use cases for preview operations
- **BLoC State Management**: No PreviewComposerBloc to orchestrate data fetching and publishing
- **Data Fetching Logic**: Preview screen doesn't fetch its own conversation/message data
- **Isolation**: Preview feature depends on dashboard BLoCs (ConversationBloc, MessageSelectionCubit)

### Key Discoveries:
- **Current Architecture Flaw**: PreviewComposerScreen depends on `ConversationBloc` being in loaded state with correct conversation data
- **Dashboard Coupling**: If dashboard doesn't have conversation loaded, preview screen fails to initialize
- **Language/Metadata Issues**: Preview shows whatever metadata is in dashboard cache, not necessarily the correct language or full details
- **Navigation Pattern**: Routes pass primitives via query parameters (good foundation)
- **Provider Isolation**: `blocProvidersPreview()` already exists but only provides Cubit, not full BLoC

## Desired End State

### Specification:
1. **Dashboard Integration**: When user selects 3-5 messages and clicks "Publish Preview", navigate to preview screen passing ONLY `conversationId` and `List<String> messageIds` as query parameters
2. **Preview Screen Initialization**: PreviewComposerBloc receives `PreviewComposerStarted` event with conversationId and messageIds
3. **Data Fetching**: BLoC fetches full conversation details (title, description, cover image) AND selected messages from repositories
4. **State Management**: BLoC emits `PreviewComposerLoaded` state with all required data (conversation metadata + selected messages)
5. **Form Interaction**: User edits title, description, cover image; BLoC tracks form state
6. **Publish Operation**: User taps "Publish Preview" → BLoC executes publish use case (or mock) → emits success/error states
7. **Confirmation**: On success, navigate to confirmation screen with generated preview URL
8. **Zero Dashboard Dependencies**: Preview screen NEVER reads from ConversationBloc, MessageBloc, or MessageSelectionCubit

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No lint errors: `flutter analyze`
- [ ] Unit tests pass for use cases: `flutter test`
- [ ] BLoC tests pass for state transitions: `flutter test`
- [ ] Repository tests pass: `flutter test`

#### Manual Verification:
- [ ] Select 3-5 messages in dashboard
- [ ] Click "Publish Preview" button
- [ ] Verify preview screen shows loading state initially
- [ ] Verify preview screen loads conversation metadata (title, description, image) from API
- [ ] Verify preview screen displays correct message count (3-5)
- [ ] Verify form validation works (title, description, cover URL)
- [ ] Verify user can edit metadata fields
- [ ] Verify publish button triggers loading state
- [ ] Verify success navigates to confirmation screen
- [ ] Verify confirmation shows generated URL
- [ ] Verify dashboard state doesn't affect preview screen (e.g., change conversation in dashboard while preview is open)
- [ ] Verify preview works even if conversation isn't loaded in dashboard

## What We're NOT Doing

- **No Real API Integration**: Still using mock publish operation (real API will come later)
- **No Preview Management**: No edit/delete existing previews functionality
- **No Audio Preview**: Not implementing audio playback in preview screen
- **No Image Upload**: URL input only (consistent with current approach)
- **No Advanced Validation**: Basic required field checks only
- **No Offline Support**: No local caching or offline mode
- **No Analytics**: No tracking or metrics
- **No Preview Page**: No actual public preview page implementation

## Implementation Approach

### Strategy:
1. **Bottom-Up**: Start with domain layer (entities, use cases), then data layer (repositories), then presentation (BLoC, UI)
2. **Incremental Testing**: Verify each layer works before proceeding
3. **Maintain Mock Publish**: Keep mock operation for now, replace with real API later
4. **Minimize Breaking Changes**: Reuse existing widgets where possible
5. **Clean Separation**: Ensure preview feature is 100% self-contained

### Architecture:
```
lib/features/preview/
  ├── domain/
  │   ├── entities/
  │   │   ├── preview_metadata.dart          # Title, description, coverUrl
  │   │   └── preview_composer_data.dart      # Conversation + Messages bundle
  │   ├── repositories/
  │   │   └── preview_repository.dart        # Abstract interface
  │   └── usecases/
  │       ├── get_preview_composer_data_usecase.dart  # Fetch conversation + messages
  │       └── publish_preview_usecase.dart            # Publish operation (mock)
  │
  ├── data/
  │   └── repositories/
  │       └── preview_repository_impl.dart   # Uses ConversationRepository + MessageRepository
  │
  └── presentation/
      ├── bloc/
      │   ├── preview_composer_bloc.dart     # Main BLoC
      │   ├── preview_composer_event.dart
      │   └── preview_composer_state.dart
      ├── screens/
      │   ├── preview_composer_screen.dart   # Updated to use BLoC
      │   └── preview_confirmation_screen.dart
      └── widgets/
          ├── message_selection_counter.dart
          ├── preview_metadata_form.dart
          └── preview_share_panel.dart
```

---

## Phase 1: Domain Layer - Entities & Use Cases

### Overview
Create domain entities to represent preview-specific data structures and use cases to orchestrate data fetching and publishing.

### Changes Required:

#### 1. Preview Metadata Entity

**File**: `lib/features/preview/domain/entities/preview_metadata.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

/// Metadata for a conversation preview (user-editable fields)
class PreviewMetadata extends Equatable {
  const PreviewMetadata({
    required this.title,
    required this.description,
    this.coverImageUrl,
  });

  final String title;
  final String description;
  final String? coverImageUrl;

  @override
  List<Object?> get props => [title, description, coverImageUrl];

  PreviewMetadata copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
  }) {
    return PreviewMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
```

#### 2. Preview Composer Data Entity

**File**: `lib/features/preview/domain/entities/preview_composer_data.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:equatable/equatable.dart';

/// Complete data needed for the preview composer screen
/// Contains conversation details and selected messages
class PreviewComposerData extends Equatable {
  const PreviewComposerData({
    required this.conversation,
    required this.selectedMessages,
    required this.initialMetadata,
  });

  final Conversation conversation;
  final List<Message> selectedMessages;
  final PreviewMetadata initialMetadata;

  @override
  List<Object?> get props => [conversation, selectedMessages, initialMetadata];
}
```

#### 3. Get Preview Composer Data Use Case

**File**: `lib/features/preview/domain/usecases/get_preview_composer_data_usecase.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class GetPreviewComposerDataUsecase {
  GetPreviewComposerDataUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  /// Fetches all data needed for the preview composer screen
  ///
  /// [conversationId] - The conversation to preview
  /// [messageIds] - List of 3-5 message IDs selected by user
  ///
  /// Returns PreviewComposerData with conversation details, messages, and initial metadata
  Future<Result<PreviewComposerData>> call({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    _logger.i('Fetching preview composer data for conversation: $conversationId');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate message count
    if (messageIds.length < 3 || messageIds.length > 5) {
      _logger.w('Invalid message count: ${messageIds.length}');
      return failure(const UnknownFailure(
        details: 'Please select between 3 and 5 messages',
      ));
    }

    return _repository.getPreviewComposerData(
      conversationId: conversationId,
      messageIds: messageIds,
    );
  }
}
```

#### 4. Publish Preview Use Case (Mock)

**File**: `lib/features/preview/domain/usecases/publish_preview_usecase.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PublishPreviewUsecase {
  PublishPreviewUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  /// Publishes a conversation preview (mock operation for now)
  ///
  /// [conversationId] - The conversation being previewed
  /// [metadata] - User-entered preview metadata
  /// [messageIds] - List of selected message IDs
  ///
  /// Returns generated preview URL on success
  Future<Result<String>> call({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    _logger.i('Publishing preview for conversation: $conversationId');
    _logger.d('Metadata: ${metadata.title} - ${metadata.description}');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate
    if (metadata.title.trim().isEmpty) {
      return failure(const UnknownFailure(details: 'Title is required'));
    }

    if (metadata.description.trim().isEmpty) {
      return failure(const UnknownFailure(details: 'Description is required'));
    }

    if (messageIds.length < 3 || messageIds.length > 5) {
      return failure(const UnknownFailure(
        details: 'Please select between 3 and 5 messages',
      ));
    }

    return _repository.publishPreview(
      conversationId: conversationId,
      metadata: metadata,
      messageIds: messageIds,
    );
  }
}
```

#### 5. Preview Repository Interface

**File**: `lib/features/preview/domain/repositories/preview_repository.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';

/// Repository for preview operations
abstract class PreviewRepository {
  /// Fetches all data needed for the preview composer screen
  Future<Result<PreviewComposerData>> getPreviewComposerData({
    required String conversationId,
    required List<String> messageIds,
  });

  /// Publishes a preview (mock operation for now)
  /// Returns generated preview URL
  Future<Result<String>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  });
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All domain files compile: `flutter analyze`
- [ ] No lint errors: `flutter analyze`
- [ ] Use case logic is testable (no external dependencies in domain layer)
- [ ] Entities are immutable (all fields final)
- [ ] Equatable props defined correctly

#### Manual Verification:
- [ ] PreviewMetadata entity has all required fields
- [ ] PreviewComposerData bundles conversation + messages correctly
- [ ] GetPreviewComposerDataUsecase validates message count
- [ ] PublishPreviewUsecase validates metadata fields
- [ ] Repository interface is clear and focused

**Implementation Note**: After Phase 1, verify all types compile and domain logic is sound before proceeding to data layer.

---

## Phase 2: Data Layer - Repository Implementation

### Overview
Implement PreviewRepository using existing ConversationRepository and MessageRepository to fetch data. Add mock publish operation.

### Changes Required:

#### 1. Preview Repository Implementation

**File**: `lib/features/preview/data/repositories/preview_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: PreviewRepository)
class PreviewRepositoryImpl implements PreviewRepository {
  PreviewRepositoryImpl(
    this._conversationRepository,
    this._messageRepository,
    this._logger,
  );

  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  @override
  Future<Result<PreviewComposerData>> getPreviewComposerData({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Fetching preview composer data');
      _logger.d('Conversation ID: $conversationId');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

      // Fetch conversation details
      final conversationResult = await _conversationRepository.getConversation(
        conversationId,
      );

      // Early return if conversation fetch failed
      final conversation = await conversationResult.fold(
        onSuccess: (conv) => conv,
        onFailure: (failure) {
          _logger.e('Failed to fetch conversation: ${failure.failure.code}');
          return throw failure;
        },
      );

      // Fetch all selected messages in parallel
      final messageFutures = messageIds.map((messageId) {
        return _messageRepository.getMessage(messageId);
      }).toList();

      final messageResults = await Future.wait(messageFutures);

      // Extract messages, collecting failures
      final messages = <Message>[];
      for (var i = 0; i < messageResults.length; i++) {
        final result = messageResults[i];
        await result.fold(
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

      _logger.i('Successfully fetched preview composer data');
      return success(composerData);
    } on Failure catch (failure) {
      // Already logged in fold
      return failure(failure.failure);
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching preview data', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<String>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    try {
      _logger.i('Mock publishing preview');
      _logger.d('Conversation: $conversationId');
      _logger.d('Title: ${metadata.title}');
      _logger.d('Description: ${metadata.description}');
      _logger.d('Message IDs: ${messageIds.join(", ")}');

      // Simulate network delay
      await Future<void>.delayed(const Duration(seconds: 1));

      // Generate mock preview URL
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mockUrl = 'https://carbonvoice.app/preview/demo_$timestamp';

      _logger.i('Mock preview published: $mockUrl');

      return success(mockUrl);
    } on Exception catch (e, stack) {
      _logger.e('Error publishing preview', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
```

#### 2. Dependency Injection Registration

**File**: Run code generation
**Changes**: Run build_runner to register PreviewRepositoryImpl

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The `@LazySingleton` annotation should automatically register the repository in the DI container.

### Success Criteria:

#### Automated Verification:
- [ ] Repository compiles without errors: `flutter analyze`
- [ ] Dependency injection works: run app and verify no GetIt errors
- [ ] Unit tests pass for repository (mock conversation/message repos)
- [ ] Handles failures gracefully (conversation not found, message not found)

#### Manual Verification:
- [ ] Repository fetches conversation successfully
- [ ] Repository fetches multiple messages in parallel
- [ ] Repository continues if one message fails to load (as long as ≥3 succeed)
- [ ] Repository returns failure if <3 messages load successfully
- [ ] Mock publish generates unique URL each time
- [ ] Mock publish has 1-second delay (simulates network call)

**Implementation Note**: After Phase 2, write unit tests for the repository before proceeding to BLoC layer.

---

## Phase 3: Presentation Layer - BLoC State Management

### Overview
Replace PreviewComposerCubit with PreviewComposerBloc that handles data fetching, form state, and publishing in one unified state machine.

### Changes Required:

#### 1. Preview Composer Events

**File**: `lib/features/preview/presentation/bloc/preview_composer_event.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:equatable/equatable.dart';

sealed class PreviewComposerEvent extends Equatable {
  const PreviewComposerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start the preview composer and fetch data
class PreviewComposerStarted extends PreviewComposerEvent {
  const PreviewComposerStarted({
    required this.conversationId,
    required this.messageIds,
  });

  final String conversationId;
  final List<String> messageIds;

  @override
  List<Object?> get props => [conversationId, messageIds];
}

/// Event to update the title field
class PreviewTitleUpdated extends PreviewComposerEvent {
  const PreviewTitleUpdated(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

/// Event to update the description field
class PreviewDescriptionUpdated extends PreviewComposerEvent {
  const PreviewDescriptionUpdated(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

/// Event to update the cover image URL field
class PreviewCoverImageUpdated extends PreviewComposerEvent {
  const PreviewCoverImageUpdated(this.coverImageUrl);

  final String? coverImageUrl;

  @override
  List<Object?> get props => [coverImageUrl];
}

/// Event to publish the preview
class PreviewPublishRequested extends PreviewComposerEvent {
  const PreviewPublishRequested();
}

/// Event to reset the composer state
class PreviewComposerReset extends PreviewComposerEvent {
  const PreviewComposerReset();
}
```

#### 2. Preview Composer States

**File**: `lib/features/preview/presentation/bloc/preview_composer_state.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_composer_data.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
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
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
  });

  final PreviewComposerData composerData;
  final PreviewMetadata currentMetadata;
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
        titleError,
        descriptionError,
        coverImageUrlError,
      ];

  PreviewComposerLoaded copyWith({
    PreviewComposerData? composerData,
    PreviewMetadata? currentMetadata,
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
  }) {
    return PreviewComposerLoaded(
      composerData: composerData ?? this.composerData,
      currentMetadata: currentMetadata ?? this.currentMetadata,
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

#### 3. Preview Composer BLoC

**File**: `lib/features/preview/presentation/bloc/preview_composer_bloc.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/get_preview_composer_data_usecase.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/publish_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
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
      onSuccess: (composerData) {
        _logger.i('Preview composer data loaded successfully');
        emit(PreviewComposerLoaded(
          composerData: composerData,
          currentMetadata: composerData.initialMetadata,
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

#### 4. Update BLoC Providers

**File**: `lib/core/providers/bloc_providers.dart`
**Changes**: Replace PreviewComposerCubit with PreviewComposerBloc

```dart
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';

// Update blocProvidersPreview method:
static Widget blocProvidersPreview({required Widget child}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<PreviewComposerBloc>(
        create: (_) => getIt<PreviewComposerBloc>(),
      ),
      // Note: MessageSelectionCubit removed - no longer needed
    ],
    child: child,
  );
}

// Also update blocProvidersDashboard to remove PreviewComposerCubit:
static Widget blocProvidersDashboard() {
  return MultiBlocProvider(
    providers: [
      // ... existing providers ...
      BlocProvider<MessageSelectionCubit>(
        create: (_) => getIt<MessageSelectionCubit>(),
      ),
      // REMOVE: PreviewComposerCubit - no longer used
    ],
    child: const DashboardScreen(),
  );
}
```

#### 5. Code Generation

**File**: Terminal
**Changes**: Run build_runner to register BLoC

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Success Criteria:

#### Automated Verification:
- [ ] All BLoC files compile: `flutter analyze`
- [ ] BLoC registered in DI: app runs without GetIt errors
- [ ] BLoC tests pass (state transitions for all events)
- [ ] Events are equatable and comparable
- [ ] States are immutable

#### Manual Verification:
- [ ] BLoC emits `PreviewComposerLoading` on `PreviewComposerStarted`
- [ ] BLoC emits `PreviewComposerLoaded` with fetched data
- [ ] BLoC emits `PreviewComposerError` if data fetch fails
- [ ] BLoC validates title/description/coverImage on field updates
- [ ] BLoC emits `PreviewComposerPublishing` on publish request
- [ ] BLoC emits `PreviewComposerPublishSuccess` with mock URL
- [ ] BLoC returns to initial state on reset

**Implementation Note**: After Phase 3, write comprehensive BLoC tests before updating UI.

---

## Phase 4: Presentation Layer - Update UI to Use BLoC

### Overview
Update PreviewComposerScreen to use PreviewComposerBloc instead of reading from ConversationBloc. Update navigation to pass messageIds as query parameters.

### Changes Required:

#### 1. Update Preview Composer Screen

**File**: `lib/features/preview/presentation/screens/preview_composer_screen.dart`
**Changes**: Replace implementation with BLoC-based approach

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
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

#### 2. Update Preview Metadata Form Widget

**File**: `lib/features/preview/presentation/widgets/preview_metadata_form.dart`
**Changes**: Update to dispatch BLoC events instead of calling Cubit methods

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form for entering preview metadata
class PreviewMetadataForm extends StatefulWidget {
  const PreviewMetadataForm({super.key});

  @override
  State<PreviewMetadataForm> createState() => _PreviewMetadataFormState();
}

class _PreviewMetadataFormState extends State<PreviewMetadataForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverImageUrlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _coverImageUrlController = TextEditingController();

    // Initialize with BLoC state values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<PreviewComposerBloc>().state;
      if (state is PreviewComposerLoaded) {
        _titleController.text = state.currentMetadata.title;
        _descriptionController.text = state.currentMetadata.description;
        _coverImageUrlController.text = state.currentMetadata.coverImageUrl ?? '';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
      builder: (context, state) {
        if (state is! PreviewComposerLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Preview Title *',
                hintText: 'Enter a catchy title for your preview',
                errorText: state.titleError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLength: PreviewComposerBloc.maxTitleLength,
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                      PreviewTitleUpdated(value),
                    );
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Short Description *',
                hintText: 'Brief description (max ${PreviewComposerBloc.maxDescriptionLength} characters)',
                errorText: state.descriptionError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLines: 3,
              maxLength: PreviewComposerBloc.maxDescriptionLength,
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                      PreviewDescriptionUpdated(value),
                    );
              },
            ),
            const SizedBox(height: 16),

            // Cover image URL field
            TextField(
              controller: _coverImageUrlController,
              decoration: InputDecoration(
                labelText: 'Cover Image URL (optional)',
                hintText: 'https://example.com/image.jpg',
                errorText: state.coverImageUrlError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                helperText: 'Leave empty to use conversation cover image',
              ),
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                      PreviewCoverImageUpdated(value.isEmpty ? null : value),
                    );
              },
            ),
          ],
        );
      },
    );
  }
}
```

#### 3. Update Router to Pass Message IDs

**File**: `lib/core/routing/app_router.dart`
**Changes**: Update preview composer route to accept messageIds parameter

```dart
// Update previewComposer route:
GoRoute(
  path: AppRoutes.previewComposer,
  name: 'previewComposer',
  pageBuilder: (context, state) {
    final conversationId = state.uri.queryParameters['conversationId'] ?? '';
    final messageIdsParam = state.uri.queryParameters['messageIds'] ?? '';

    // Parse comma-separated message IDs
    final messageIds = messageIdsParam.isEmpty
        ? <String>[]
        : messageIdsParam.split(',');

    return NoTransitionPage(
      child: BlocProviders.blocProvidersPreview(
        child: PreviewComposerScreen(
          conversationId: conversationId,
          messageIds: messageIds,
        ),
      ),
    );
  },
),
```

#### 4. Update Dashboard Navigation

**File**: Dashboard button implementation (location varies)
**Changes**: Update navigation to pass messageIds as query parameter

```dart
// Example: In dashboard action button handler
void _onPublishPreviewPressed(BuildContext context) {
  final messageSelectionCubit = context.read<MessageSelectionCubit>();
  final selectedMessageIds = messageSelectionCubit.getSelectedMessageIds();

  // Validate selection count
  if (selectedMessageIds.length < 3 || selectedMessageIds.length > 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select between 3 and 5 messages'),
        backgroundColor: AppColors.warning,
      ),
    );
    return;
  }

  // Get conversation ID from conversation state
  final conversationState = context.read<ConversationBloc>().state;
  if (conversationState is! ConversationLoaded ||
      conversationState.selectedConversationIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a conversation first'),
        backgroundColor: AppColors.warning,
      ),
    );
    return;
  }

  final conversationId = conversationState.selectedConversationIds.first;

  // Join message IDs with commas
  final messageIdsParam = selectedMessageIds.join(',');

  // Navigate to preview composer
  context.go(
    '${AppRoutes.previewComposer}?conversationId=$conversationId&messageIds=$messageIdsParam',
  );

  // Clear message selection
  messageSelectionCubit.clearSelection();
}
```

#### 5. Delete Old Cubit Files (Optional - After Testing)

**Files to Delete** (once BLoC implementation is fully tested):
- `lib/features/preview/presentation/cubit/preview_composer_cubit.dart`
- `lib/features/preview/presentation/cubit/preview_composer_state.dart`

**Note**: Keep these files until BLoC implementation is fully verified, then delete.

### Success Criteria:

#### Automated Verification:
- [ ] All UI files compile: `flutter analyze`
- [ ] No routing errors when navigating
- [ ] No lint warnings: `flutter analyze`
- [ ] Widget tests pass (if written)

#### Manual Verification:
- [ ] Select 3-5 messages in dashboard
- [ ] Click "Publish Preview" button
- [ ] Verify preview screen shows loading state
- [ ] Verify preview screen loads conversation metadata from API (not dashboard cache)
- [ ] Verify preview screen displays correct message count
- [ ] Verify form fields are pre-filled with conversation data
- [ ] Verify real-time validation works (title, description, cover URL)
- [ ] Verify user can edit all fields
- [ ] Verify publish button disabled when form invalid
- [ ] Verify publish button shows loading state during publish
- [ ] Verify success navigates to confirmation screen with URL
- [ ] Verify changing conversation in dashboard doesn't affect open preview screen
- [ ] Verify preview works even if conversation not loaded in dashboard

**Implementation Note**: After Phase 4, perform thorough end-to-end testing before considering this complete.

---

## Testing Strategy

### Unit Tests

#### Domain Layer Tests:
- **Entities**: Test equality, copyWith, props
  - `preview_metadata_test.dart`: Test metadata creation, equality, copyWith
  - `preview_composer_data_test.dart`: Test data bundle creation, equality

- **Use Cases**: Test business logic
  - `get_preview_composer_data_usecase_test.dart`: Test message count validation, repository calls
  - `publish_preview_usecase_test.dart`: Test metadata validation, message count validation

#### Data Layer Tests:
- **Repositories**: Test data fetching and error handling
  - `preview_repository_impl_test.dart`: Mock conversation/message repositories, test parallel fetching, test error handling

#### Presentation Layer Tests:
- **BLoC**: Test state transitions
  - `preview_composer_bloc_test.dart`: Test all event/state transitions, test validation logic

### Widget Tests

- **Screens**: Test UI rendering and BLoC integration
  - `preview_composer_screen_test.dart`: Test loading/error/loaded states, test form submission
  - `preview_confirmation_screen_test.dart`: Test URL display

- **Forms**: Test input validation UI
  - `preview_metadata_form_test.dart`: Test error display, character counters

### Integration Tests

- **End-to-End Flow**: Full preview creation workflow
  - Select messages → navigate to preview → load data → fill form → publish → confirmation
  - Test with mock API responses
  - Verify state isolation (dashboard changes don't affect preview)

### Manual Testing Steps

1. **Happy Path**:
   - [ ] Select exactly 3 messages from conversation
   - [ ] Click "Publish Preview" button
   - [ ] Verify loading state appears
   - [ ] Verify conversation data loads correctly
   - [ ] Edit title and description
   - [ ] Click "Publish Preview"
   - [ ] Verify 1-second delay
   - [ ] Verify confirmation screen shows mock URL
   - [ ] Click "Copy URL"
   - [ ] Verify snackbar shows "URL copied"

2. **Validation Errors**:
   - [ ] Try navigating with <3 messages (should show validation error)
   - [ ] Try navigating with >5 messages (should show validation error)
   - [ ] Clear title field (should show inline error)
   - [ ] Clear description field (should show inline error)
   - [ ] Enter invalid URL in cover image (should show inline error)
   - [ ] Try publish with invalid form (button should be disabled)

3. **Error Handling**:
   - [ ] Test with invalid conversationId (should show error screen)
   - [ ] Test with invalid messageId (should fetch remaining messages if ≥3 succeed)
   - [ ] Test network timeout simulation

4. **Isolation Testing**:
   - [ ] Open preview screen
   - [ ] Switch to different conversation in dashboard
   - [ ] Verify preview screen still shows correct conversation
   - [ ] Open preview for conversation not loaded in dashboard
   - [ ] Verify preview loads data independently

## Performance Considerations

### Optimizations:
- **Parallel Message Fetching**: Repository fetches all selected messages concurrently using `Future.wait()`
- **Graceful Degradation**: If some messages fail to load, preview continues with remaining messages (if ≥3)
- **No Extra Caching**: Repository uses existing conversation/message repository caches
- **Minimal State**: BLoC only stores current form data, not entire history

### Potential Bottlenecks:
- **Multiple API Calls**: Fetching conversation + N messages = N+1 API calls (acceptable for MVP)
- **Form Re-renders**: TextField onChange triggers BLoC event + state update (standard Flutter pattern)

## Migration Notes

### Breaking Changes:
- **PreviewComposerCubit Removed**: Replaced with PreviewComposerBloc
- **Screen Parameters Changed**: PreviewComposerScreen now requires `messageIds` parameter
- **Dashboard Navigation Updated**: Must pass messageIds as query parameter

### Backward Compatibility:
- **Existing Routes**: Old route structure maintained (`/dashboard/preview/composer`)
- **Existing Widgets**: Message selection counter, form widgets reused with minimal changes
- **Existing Repositories**: No changes to ConversationRepository or MessageRepository

### Migration Checklist:
- [ ] Update all navigation calls to pass messageIds parameter
- [ ] Replace BlocProvider<PreviewComposerCubit> with BlocProvider<PreviewComposerBloc>
- [ ] Remove PreviewComposerCubit from dashboard providers
- [ ] Delete old cubit files after verification
- [ ] Update any tests that reference PreviewComposerCubit

## References

- **Original Plans**:
  - [2025-12-09-public-conversation-previews.md](thoughts/shared/plans/2025-12-09-public-conversation-previews.md) - Full API implementation plan
  - [2025-12-11-preview-ui-demo.md](thoughts/shared/plans/2025-12-11-preview-ui-demo.md) - Current UI demo plan
- **Existing Patterns**:
  - [message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart) - Message selection pattern
  - [conversation_repository.dart](lib/features/conversations/domain/repositories/conversation_repository.dart) - Repository interface
  - [message_repository.dart](lib/features/messages/domain/repositories/message_repository.dart) - Message fetching
  - [app_router.dart](lib/core/routing/app_router.dart) - Routing patterns
- **Clean Architecture**: [CLAUDE.md](CLAUDE.md) - Project architecture guide

---

## Summary

This plan transforms the preview feature from a dashboard-dependent UI demo into a fully isolated, self-contained feature with proper clean architecture:

**What Changes:**
- ✅ Dashboard passes ONLY primitive values (conversationId + messageIds)
- ✅ Preview screen fetches its own data via BLoC + use cases
- ✅ BLoC orchestrates all state management (data fetching, form validation, publishing)
- ✅ Zero dependencies on dashboard-level providers (ConversationBloc, MessageBloc)
- ✅ Clean separation: domain (entities/use cases) → data (repositories) → presentation (BLoC/UI)

**What Stays the Same:**
- ✅ Mock publish operation (real API integration deferred)
- ✅ Existing routing structure
- ✅ Existing UI widgets (reused with minimal changes)
- ✅ Message selection in dashboard
- ✅ Confirmation screen flow

**Benefits:**
- 🎯 **Isolation**: Preview feature works independently of dashboard state
- 🎯 **Correctness**: Always fetches fresh conversation metadata (correct language, full details)
- 🎯 **Testability**: Clean architecture makes unit/integration testing straightforward
- 🎯 **Maintainability**: Clear boundaries between features, easy to extend later
- 🎯 **Scalability**: When real API is ready, swap mock publish with real implementation (no architectural changes)

**Next Steps:**
Once this refactor is complete, the feature will be ready for real API integration by simply replacing the mock publish operation in PreviewRepositoryImpl with actual API calls.
