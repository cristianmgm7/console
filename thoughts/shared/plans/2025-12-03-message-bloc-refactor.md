# Message Bloc Refactoring Implementation Plan

## Overview

Refactor the monolithic `MessageBloc` into three focused blocs (fetch, detail, send) with proper separation of concerns. Extract user profile enrichment logic into a reusable usecase and add message sending functionality with new API integration.

## Current State Analysis

### Current Architecture
- **Single large MessageBloc** (279 lines) handling multiple responsibilities:
  - Message fetching with pagination
  - Conversation selection
  - User profile caching and enrichment
  - Message refresh operations

- **Duplicated logic**: User enrichment exists in both `MessageBloc` and `MessageDetailBloc`

- **Repository Interface**: Currently only has read operations (`getRecentMessages`, `getMessage`)

- **Data Source**: Has GET operations but missing send functionality

### Key Discoveries:
- Message fetching uses `/v3/messages/recent` endpoint
- Message detail uses `/v5/messages/{id}` endpoint
- User enrichment is duplicated across blocs
- No existing message sending functionality

## Desired End State

Three focused blocs in separate folders:
- `bloc_message_fetch/` - Handles conversation message loading and pagination
- `bloc_message_detail/` - Handles individual message details (existing)
- `bloc_message_send/` - Handles message sending operations

New usecase for user enrichment and message sending API integration.

### Success Verification:
- All three blocs compile and inject properly
- Existing message fetching functionality unchanged
- Message sending works with new API endpoint
- User enrichment logic centralized and reusable

## What We're NOT Doing

- Changing existing UI components (will be handled in follow-up task)
- Modifying existing API contracts for reading messages
- Changing authentication or network layer
- Adding message editing or deletion functionality

## Implementation Approach

Incremental refactoring following clean architecture principles:
1. Extract user enrichment logic to usecase
2. Create message sending DTOs and API integration
3. Split existing bloc into three focused blocs
4. Update dependency injection
5. Integrate blocs into presentation layer (future task)

## Phase 1: Extract User Enrichment Use Case

### Overview
Create reusable usecase for user profile enrichment with caching, removing this logic from blocs.

### Changes Required:

#### 1. Create User Enrichment Use Case
**File**: `lib/features/messages/domain/usecases/enrich_messages_with_users_usecase.dart`

```dart
@injectable
class EnrichMessagesWithUsersUsecase {
  const EnrichMessagesWithUsersUsecase(
    this._userRepository,
    this._logger,
  );

  final UserRepository _userRepository;
  final Logger _logger;
  final Map<String, User> _profileCache = {};

  Future<List<MessageUiModel>> call(List<Message> messages) async {
    final userIds = messages.map((m) => m.userId).toSet();
    final userMap = await _getUsersWithCache(userIds);

    return messages.map((message) {
      final creator = userMap[message.creatorId];
      return message.toUiModel(creator);
    }).toList();
  }

  Future<Map<String, User>> _getUsersWithCache(Set<String> userIds) async {
    // Extract existing caching logic from MessageBloc
  }
}
```

#### 2. Create Send Message DTOs
**File**: `lib/features/messages/data/models/api/send_message_request_dto.dart`

```dart
class SendMessageRequestDto {
  const SendMessageRequestDto({
    required this.transcript,
    required this.isTextMessage,
    required this.uniqueClientId,
    this.releaseDate,
    this.utmData,
    this.isStreaming = true,
    this.announceUser = true,
    this.voice,
    this.kind = 'audio',
    required this.channelId,
    required this.workspaceGuid,
    this.replyToMessageId,
    this.createForward,
  });

  final String transcript;
  final bool isTextMessage;
  final String uniqueClientId;
  final DateTime? releaseDate;
  final UtmDataDto? utmData;
  final bool isStreaming;
  final bool announceUser;
  final String? voice;
  final String kind;
  final String channelId;
  final String workspaceGuid;
  final String? replyToMessageId;
  final CreateForwardDto? createForward;

  Map<String, dynamic> toJson() => {
    'transcript': transcript,
    'is_text_message': isTextMessage,
    'unique_client_id': uniqueClientId,
    if (releaseDate != null) 'release_date': releaseDate!.toIso8601String(),
    if (utmData != null) 'utm_data': utmData!.toJson(),
    'is_streaming': isStreaming,
    'announce_user': announceUser,
    if (voice != null) 'voice': voice,
    'kind': kind,
    'channel_id': channelId,
    'workspace_guid': workspaceGuid,
    if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
    if (createForward != null) 'createForward': createForward!.toJson(),
  };
}

class UtmDataDto {
  // UTM tracking data fields
}

class CreateForwardDto {
  // Forward message data fields
}
```

#### 3. Create Send Message Response DTO
**File**: `lib/features/messages/data/models/api/send_message_response_dto.dart`

```dart
class SendMessageResponseDto {
  const SendMessageResponseDto({
    required this.messageId,
    required this.status,
    // other response fields
  });

  factory SendMessageResponseDto.fromJson(Map<String, dynamic> json) {
    // JSON parsing logic
  }
}
```

#### 4. Update Repository Interface
**File**: `lib/features/messages/domain/repositories/message_repository.dart`

```dart
abstract class MessageRepository {
  // existing methods...

  /// Sends a new message
  Future<Result<SendMessageResponse>> sendMessage(SendMessageRequest request);
}
```

#### 5. Update Data Source Interface
**File**: `lib/features/messages/data/datasources/message_remote_datasource.dart`

```dart
abstract class MessageRemoteDataSource {
  // existing methods...

  /// Sends a message via POST to /v3/messages/start
  Future<SendMessageResponseDto> sendMessage(SendMessageRequestDto request);
}
```

#### 6. Implement Send Message in Data Source
**File**: `lib/features/messages/data/datasources/message_remote_datasource_impl.dart`

```dart
@override
Future<SendMessageResponseDto> sendMessage(SendMessageRequestDto request) async {
  try {
    final response = await _httpService.post(
      '${OAuthConfig.apiBaseUrl}/v3/messages/start',
      body: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return SendMessageResponseDto.fromJson(data);
    } else {
      throw ServerException(
        statusCode: response.statusCode,
        message: 'Failed to send message',
      );
    }
  } on Exception catch (e, stack) {
    _logger.e('Network error sending message', error: e, stackTrace: stack);
    throw NetworkException(message: 'Failed to send message: $e');
  }
}
```

#### 7. Create Send Message Use Case
**File**: `lib/features/messages/domain/usecases/send_message_usecase.dart`

```dart
@injectable
class SendMessageUsecase {
  const SendMessageUsecase(
    this._messageRepository,
    this._logger,
  );

  final MessageRepository _messageRepository;
  final Logger _logger;

  Future<Result<SendMessageResponse>> call(SendMessageRequest request) async {
    try {
      return await _messageRepository.sendMessage(request);
    } on Exception catch (e, stack) {
      _logger.e('Error sending message', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] New DTOs compile without errors
- [ ] Use case injects properly: `flutter pub run build_runner build`
- [ ] Repository interface compiles
- [ ] Data source implementation compiles

#### Manual Verification:
- [ ] DTOs serialize/deserialize JSON correctly
- [ ] API endpoint URL is correct for the environment

## Phase 2: Create Message Fetch Bloc

### Overview
Extract message fetching logic into dedicated bloc with proper folder structure.

### Changes Required:

#### 1. Create Bloc Folder Structure
**Directory**: `lib/features/messages/presentation/bloc_message_fetch/`

#### 2. Create Fetch Bloc Files
**File**: `lib/features/messages/presentation/bloc_message_fetch/message_fetch_bloc.dart`

```dart
@injectable
class MessageFetchBloc extends Bloc<MessageFetchEvent, MessageFetchState> {
  MessageFetchBloc(
    this._getMessagesFromConversationsUsecase,
    this._enrichMessagesWithUsersUsecase,
    this._logger,
  ) : super(const MessageFetchInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  // Implementation extracted from current MessageBloc
  // Uses the new EnrichMessagesWithUsersUsecase
}
```

**File**: `lib/features/messages/presentation/bloc_message_fetch/message_fetch_event.dart`

```dart
// Events for message fetching operations
```

**File**: `lib/features/messages/presentation/bloc_message_fetch/message_fetch_state.dart`

```dart
// States for message fetching operations
```

### Success Criteria:

#### Automated Verification:
- [ ] Bloc compiles and injects properly
- [ ] All existing message fetching tests pass
- [ ] No breaking changes to public API

#### Manual Verification:
- [ ] Message loading works as before
- [ ] Pagination works correctly
- [ ] Conversation selection works

## Phase 3: Create Message Send Bloc

### Overview
Create new bloc for message sending operations.

### Changes Required:

#### 1. Create Bloc Folder Structure
**Directory**: `lib/features/messages/presentation/bloc_message_send/`

#### 2. Create Send Bloc Files
**File**: `lib/features/messages/presentation/bloc_message_send/message_send_bloc.dart`

```dart
@injectable
class MessageSendBloc extends Bloc<MessageSendEvent, MessageSendState> {
  MessageSendBloc(
    this._sendMessageUsecase,
    this._logger,
  ) : super(const MessageSendInitial()) {
    on<SendMessage>(_onSendMessage);
  }

  final SendMessageUsecase _sendMessageUsecase;
  final Logger _logger;

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageSendState> emit,
  ) async {
    emit(const MessageSendLoading());

    final result = await _sendMessageUsecase(
      SendMessageRequest(
        transcript: event.transcript,
        isTextMessage: event.isTextMessage,
        uniqueClientId: event.uniqueClientId,
        channelId: event.channelId,
        workspaceGuid: event.workspaceGuid,
        // map other fields...
      ),
    );

    if (result.isSuccess) {
      emit(MessageSendSuccess(result.valueOrNull!));
    } else {
      emit(MessageSendError(result.failureOrNull!.message));
    }
  }
}
```

**File**: `lib/features/messages/presentation/bloc_message_send/message_send_event.dart`

```dart
class SendMessage extends MessageSendEvent {
  const SendMessage({
    required this.transcript,
    required this.isTextMessage,
    required this.uniqueClientId,
    required this.channelId,
    required this.workspaceGuid,
    // other fields...
  });
}
```

**File**: `lib/features/messages/presentation/bloc_message_send/message_send_state.dart`

```dart
abstract class MessageSendState {}

class MessageSendInitial extends MessageSendState {}
class MessageSendLoading extends MessageSendState {}
class MessageSendSuccess extends MessageSendState {
  const MessageSendSuccess(this.response);
  final SendMessageResponse response;
}
class MessageSendError extends MessageSendState {
  const MessageSendError(this.message);
  final String message;
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Bloc compiles and injects properly
- [ ] Can send message via API (integration test)
- [ ] Proper error handling for network failures

#### Manual Verification:
- [ ] Message sending works with test data
- [ ] Error states display correctly
- [ ] Loading states work properly

## Phase 4: Create Message Detail Bloc Folder

### Overview
Move existing message detail bloc into proper folder structure.

### Changes Required:

#### 1. Create Bloc Folder Structure
**Directory**: `lib/features/messages/presentation/bloc_message_detail/`

#### 2. Move Existing Files
Move `message_detail_bloc.dart`, `message_detail_event.dart`, `message_detail_state.dart` to the new folder.

#### 3. Update Detail Bloc
Update `MessageDetailBloc` to use the new `EnrichMessagesWithUsersUsecase`.

### Success Criteria:

#### Automated Verification:
- [ ] Bloc still compiles and works after move
- [ ] All existing tests pass
- [ ] User enrichment still works correctly

## Phase 5: Update Dependency Injection

### Overview
Update injection configuration to register new blocs and usecases.

### Changes Required:

#### 1. Update Injection Modules
**File**: `lib/core/di/modules/message_module.dart` (or equivalent)

```dart
@module
abstract class MessageModule {
  // Register new usecases and blocs
  @injectable
  EnrichMessagesWithUsersUsecase get enrichMessagesWithUsersUsecase;

  @injectable
  SendMessageUsecase get sendMessageUsecase;

  @injectable
  MessageFetchBloc get messageFetchBloc;

  @injectable
  MessageSendBloc get messageSendBloc;

  // Update existing detail bloc registration
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Application builds successfully: `flutter build`
- [ ] All blocs inject without errors
- [ ] No circular dependencies

## Phase 6: Clean Up Old Bloc

### Overview
Remove old monolithic bloc after confirming all functionality is properly split.

### Changes Required:

#### 1. Remove Old Files
Delete the original `message_bloc.dart`, `message_event.dart`, `message_state.dart`

### Success Criteria:

#### Automated Verification:
- [ ] Application still builds after removal
- [ ] All tests pass
- [ ] No import errors

#### Manual Verification:
- [ ] All message functionality still works
- [ ] No regressions in existing features

## Testing Strategy

### Unit Tests:
- Test each usecase in isolation
- Test each bloc with mocked dependencies
- Test DTO serialization/deserialization
- Test error handling scenarios

### Integration Tests:
- Test message sending API integration
- Test user enrichment with real repository
- Test bloc coordination (future task)

### Manual Testing Steps:
1. Load messages from conversation - verify user profiles appear
2. Send a test message - verify API call succeeds
3. Test error scenarios (network failure, invalid data)
4. Test pagination still works
5. Test message detail loading still works

## Performance Considerations

- User profile caching should reduce API calls
- Message sending should not block UI
- Consider lazy loading for user profiles in large message lists

## Migration Notes

- Existing message loading functionality should work unchanged
- UI components will need updates in follow-up task
- No database migrations required
- API contracts remain backward compatible for reading operations

## References

- Current MessageBloc implementation: `lib/features/messages/presentation/bloc/message_bloc.dart`
- Message repository interface: `lib/features/messages/domain/repositories/message_repository.dart`
- Message remote datasource: `lib/features/messages/data/datasources/message_remote_datasource_impl.dart`
