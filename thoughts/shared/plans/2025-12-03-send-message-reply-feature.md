# Send Message / Reply Feature Implementation Plan

## Overview

This plan implements the ability to send new messages and reply to existing messages within conversations in the Carbon Voice Console. Users will be able to click a "Reply" action button in the message table, which opens a form panel to compose and send text messages through the API.

## Current State Analysis

### Existing Infrastructure:
- **Message Display**: Messages are displayed in an `AppTable` in `content_dashboard.dart` (lines 139-234)
- **Action Buttons**: Currently has "View Details" and "Download" buttons (lines 216-229)
- **Message DTO**: `MessageDto` exists at `lib/features/messages/data/models/api/message_dto.dart` with comprehensive field mapping
- **UTM Data DTO**: `UtmDataDto` exists for UTM tracking fields
- **HTTP Service**: `AuthenticatedHttpService` provides authenticated POST requests (lines 47-66)
- **Repository Pattern**: Message repository follows clean architecture with datasource → repository → usecase flow
- **BLoC Architecture**: Uses BLoC pattern for state management with events/states

### Key Discoveries:
- API endpoint: `POST /v3/messages/start` requires specific payload structure
- **API returns the same `MessageDto` structure** for both reading and sending messages - we can reuse it!
- Table actions are implemented as inline buttons in `AppTableRow` cells
- Clean architecture enforced: domain → data → presentation layers
- Authentication handled automatically via `AuthenticatedHttpService`

## Desired End State

### Functional Requirements:
1. "Reply" button appears in the Actions column of the message table
2. Clicking "Reply" opens a panel/modal with a text form
3. Form includes:
   - Text input for message content
   - Send button to submit
   - Cancel button to close
4. Sending message creates a POST request to `/v3/messages/start`
5. Success: Show confirmation, close panel, optionally refresh messages
6. Error: Display error message to user

### Technical Requirements:
1. New `SendMessageBloc` for send operation state management
2. New `SendMessageUseCase` in domain layer
3. New repository method `sendMessage` in `MessageRepository`
4. New datasource method in `MessageRemoteDataSource`
5. New `SendMessageRequestDto` for outgoing payload
6. **Reuse existing `MessageDto`** for API response (matches response schema exactly)
7. Reply panel UI component with form

### Verification Criteria:

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No linting errors: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/`
- [ ] Type checking passes (implicit in Flutter)

#### Manual Verification:
- [ ] Reply button appears on message table rows
- [ ] Clicking Reply opens the send message panel
- [ ] Form accepts text input
- [ ] Send button triggers API call
- [ ] Success shows confirmation and closes panel
- [ ] Error displays user-friendly message
- [ ] Sent message appears in the conversation (after refresh)
- [ ] Reply-to context correctly references parent message

## What We're NOT Doing

- Real-time message updates (WebSocket/polling) - requires manual refresh
- Message editing or deletion
- File attachments or voice recording
- Rich text formatting
- @mentions or emoji pickers
- Message threading UI (only backend reply-to linkage)
- Audio message creation (only text messages)
- UTM tracking data input (will use null/empty values)
- Forward message creation

## Implementation Approach

We'll follow the clean architecture pattern used throughout the codebase:
1. **Bottom-up approach**: Data layer → Domain layer → Presentation layer
2. **DTOs**: Create `SendMessageRequestDto` for request payload, reuse existing `MessageDto` for response
3. **BLoC**: Dedicated bloc for send operation (isolated from MessageBloc)
4. **UI**: Reusable panel component that can be invoked from table actions
5. **Error Handling**: Consistent with existing patterns (ServerException → ServerFailure → user message)

---

## Phase 1: Data Layer - DTOs and API Integration

### Overview
Create the data transfer objects and remote datasource method for sending messages via the API.

### Changes Required:

#### 1. Create Send Message Request DTO
**File**: `lib/features/messages/data/models/api/send_message_request_dto.dart`

```dart
import 'package:carbon_voice_console/features/messages/data/models/api/utm_data_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_message_request_dto.g.dart';

/// DTO for sending a message to the API
@JsonSerializable()
class SendMessageRequestDto {
  const SendMessageRequestDto({
    required this.transcript,
    required this.isTextMessage,
    required this.channelId,
    required this.workspaceGuid,
    this.uniqueClientId,
    this.releaseDate,
    this.utmData,
    this.isStreaming = false,
    this.announceUser = true,
    this.voice,
    this.kind = 'text',
    this.replyToMessageId,
    this.createForward,
  });

  factory SendMessageRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestDtoFromJson(json);

  final String transcript;

  @JsonKey(name: 'is_text_message')
  final bool isTextMessage;

  @JsonKey(name: 'unique_client_id')
  final String? uniqueClientId;

  @JsonKey(name: 'release_date')
  final DateTime? releaseDate;

  @JsonKey(name: 'utm_data')
  final UtmDataDto? utmData;

  @JsonKey(name: 'is_streaming')
  final bool isStreaming;

  @JsonKey(name: 'announce_user')
  final bool announceUser;

  final String? voice;

  final String kind;

  @JsonKey(name: 'channel_id')
  final String channelId;

  @JsonKey(name: 'workspace_guid')
  final String workspaceGuid;

  @JsonKey(name: 'reply_to_message_id')
  final String? replyToMessageId;

  @JsonKey(name: 'createForward')
  final CreateForwardDto? createForward;

  Map<String, dynamic> toJson() => _$SendMessageRequestDtoToJson(this);
}

/// DTO for forward message creation
@JsonSerializable()
class CreateForwardDto {
  const CreateForwardDto({
    required this.forwardedMessageId,
    this.endAccessAt,
  });

  factory CreateForwardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateForwardDtoFromJson(json);

  @JsonKey(name: 'forwarded_message_id')
  final String forwardedMessageId;

  @JsonKey(name: 'end_access_at')
  final DateTime? endAccessAt;

  Map<String, dynamic> toJson() => _$CreateForwardDtoToJson(this);
}
```

**Implementation Note**: After creating this file, run code generation to create the `.g.dart` file.

#### 2. Update Message Remote Datasource Interface
**File**: `lib/features/messages/data/datasources/message_remote_datasource.dart`

Add new method to the abstract interface (after line 24):

```dart
  /// Sends a new message or reply
  /// Returns the created message as MessageDto
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageDto> sendMessage(SendMessageRequestDto request);
```

#### 3. Implement Send Message in Datasource
**File**: `lib/features/messages/data/datasources/message_remote_datasource_impl.dart`

Add import at top:
```dart
import 'package:carbon_voice_console/features/messages/data/models/api/send_message_request_dto.dart';
```

Add method implementation (after the `getMessage` method, around line 132):

```dart
  @override
  Future<MessageDto> sendMessage(SendMessageRequestDto request) async {
    try {
      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/start',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // API returns the full message DTO structure
          final messageDto = MessageDto.fromJson(data);
          _logger.d('Successfully sent message: ${messageDto.messageId}');
          return messageDto;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse send message response: $e', error: e, stackTrace: stack);
          throw ServerException(statusCode: 422, message: 'Failed to parse response: $e');
        }
      } else {
        _logger.e('Failed to send message: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to send message: ${response.body}',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error sending message', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to send message: $e');
    }
  }
```

### Success Criteria:

#### Automated Verification:
- [ ] DTOs compile without errors
- [ ] Code generation runs successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No import errors in datasource files
- [ ] Linting passes: `flutter analyze`

#### Manual Verification:
- [ ] Review generated `.g.dart` files contain correct JSON serialization
- [ ] Verify field names match API specification (snake_case)
- [ ] Check that `SendMessageRequestDto` includes all required fields from API spec

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the DTOs correctly match the API specification before proceeding to the next phase.

---

## Phase 2: Domain Layer - Entities, Repository, Use Case

### Overview
Create domain entities and business logic for sending messages, following clean architecture principles.

### Changes Required:

#### 1. Create Send Message Request Entity
**File**: `lib/features/messages/domain/entities/send_message_request.dart`

```dart
import 'package:equatable/equatable.dart';

/// Domain entity for composing a message to send
class SendMessageRequest extends Equatable {
  const SendMessageRequest({
    required this.text,
    required this.channelId,
    required this.workspaceId,
    this.replyToMessageId,
  });

  final String text;
  final String channelId;
  final String workspaceId;
  final String? replyToMessageId;

  @override
  List<Object?> get props => [text, channelId, workspaceId, replyToMessageId];
}
```

#### 2. Create DTO Mapper for Send Message Request
**File**: `lib/features/messages/data/mappers/send_message_request_mapper.dart`

```dart
import 'package:carbon_voice_console/features/messages/data/models/api/send_message_request_dto.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:uuid/uuid.dart';

/// Maps domain SendMessageRequest to DTO
extension SendMessageRequestMapper on SendMessageRequest {
  SendMessageRequestDto toDto() {
    return SendMessageRequestDto(
      transcript: text,
      isTextMessage: true,
      channelId: channelId,
      workspaceGuid: workspaceId,
      uniqueClientId: const Uuid().v4(), // Generate unique client ID
      releaseDate: DateTime.now(),
      kind: 'text',
      replyToMessageId: replyToMessageId,
      isStreaming: false,
      announceUser: true,
    );
  }
}
```

**Note**:
- Add `uuid: ^4.5.1` to `pubspec.yaml` dependencies for unique client ID generation
- Response uses existing `MessageDto` and `MessageDtoMapper` (already exists at `lib/features/messages/data/mappers/message_dto_mapper.dart`)

#### 3. Update Message Repository Interface
**File**: `lib/features/messages/domain/repositories/message_repository.dart`

Add import at top:
```dart
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
```

Add method to interface (after line 18):

```dart
  /// Sends a new message or reply to a conversation
  /// Returns the created message as a Message entity
  Future<Result<Message>> sendMessage(SendMessageRequest request);
```

#### 4. Implement Send Message in Repository
**File**: `lib/features/messages/data/repositories/message_repository_impl.dart`

Add imports at top:
```dart
import 'package:carbon_voice_console/features/messages/data/mappers/send_message_request_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
```

Add method implementation (after `getMessage`, around line 100):

```dart
  @override
  Future<Result<Message>> sendMessage(SendMessageRequest request) async {
    try {
      final requestDto = request.toDto();
      final messageDto = await _remoteDataSource.sendMessage(requestDto);

      // Convert DTO to domain entity using existing mapper
      final message = messageDto.toDomain();

      // Invalidate cache for the conversation to reflect new message
      clearCacheForConversation(request.channelId);

      return success(message);
    } on ServerException catch (e) {
      _logger.e('Server error sending message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error sending message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error sending message', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
```

#### 5. Create Send Message Use Case
**File**: `lib/features/messages/domain/usecases/send_message_usecase.dart`

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for sending a message to a conversation
@injectable
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessageRepository _repository;

  Future<Result<Message>> call(SendMessageRequest request) {
    return _repository.sendMessage(request);
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All domain files compile without errors
- [ ] Repository implementation compiles
- [ ] Use case is properly annotated with `@injectable`
- [ ] Linting passes: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/`

#### Manual Verification:
- [ ] Verify domain entities use `Equatable` correctly
- [ ] Check mapper logic correctly transforms data (review `toDto()` and `toDomain()`)
- [ ] Confirm repository invalidates cache after sending
- [ ] Ensure error handling follows existing patterns

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that domain logic is correct before proceeding to the next phase.

---

## Phase 3: Presentation Layer - BLoC for Send Message

### Overview
Create dedicated BLoC for managing the state of sending messages, following the existing BLoC pattern.

### Changes Required:

#### 1. Create Send Message Event
**File**: `lib/features/messages/presentation/bloc/send_message_event.dart`

```dart
import 'package:equatable/equatable.dart';

/// Events for SendMessageBloc
sealed class SendMessageEvent extends Equatable {
  const SendMessageEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send a new message
class SendMessage extends SendMessageEvent {
  const SendMessage({
    required this.text,
    required this.channelId,
    required this.workspaceId,
    this.replyToMessageId,
  });

  final String text;
  final String channelId;
  final String workspaceId;
  final String? replyToMessageId;

  @override
  List<Object?> get props => [text, channelId, workspaceId, replyToMessageId];
}

/// Event to reset the send message state
class ResetSendMessage extends SendMessageEvent {
  const ResetSendMessage();
}
```

#### 2. Create Send Message State
**File**: `lib/features/messages/presentation/bloc/send_message_state.dart`

```dart
import 'package:equatable/equatable.dart';

/// States for SendMessageBloc
sealed class SendMessageState extends Equatable {
  const SendMessageState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no action taken
class SendMessageInitial extends SendMessageState {
  const SendMessageInitial();
}

/// Sending message in progress
class SendMessageInProgress extends SendMessageState {
  const SendMessageInProgress();
}

/// Message sent successfully
class SendMessageSuccess extends SendMessageState {
  const SendMessageSuccess({
    required this.messageId,
    required this.createdAt,
  });

  final String messageId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [messageId, createdAt];
}

/// Error sending message
class SendMessageError extends SendMessageState {
  const SendMessageError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

#### 3. Create Send Message BLoC
**File**: `lib/features/messages/presentation/bloc/send_message_bloc.dart`

```dart
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:carbon_voice_console/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class SendMessageBloc extends Bloc<SendMessageEvent, SendMessageState> {
  SendMessageBloc(
    this._sendMessageUseCase,
    this._logger,
  ) : super(const SendMessageInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ResetSendMessage>(_onResetSendMessage);
  }

  final SendMessageUseCase _sendMessageUseCase;
  final Logger _logger;

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<SendMessageState> emit,
  ) async {
    emit(const SendMessageInProgress());

    final request = SendMessageRequest(
      text: event.text,
      channelId: event.channelId,
      workspaceId: event.workspaceId,
      replyToMessageId: event.replyToMessageId,
    );

    final result = await _sendMessageUseCase(request);

    result.fold(
      onSuccess: (sendResult) {
        _logger.i('Message sent successfully: ${sendResult.messageId}');
        emit(SendMessageSuccess(
          messageId: sendResult.messageId,
          createdAt: sendResult.createdAt,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to send message: ${failure.code}');
        emit(SendMessageError(failure.message));
      },
    );
  }

  void _onResetSendMessage(
    ResetSendMessage event,
    Emitter<SendMessageState> emit,
  ) {
    emit(const SendMessageInitial());
  }
}
```

#### 4. Register BLoC in Dependency Injection
**File**: `lib/core/providers/bloc_providers.dart`

Add import at top:
```dart
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_bloc.dart';
```

Add BLoC provider in the `MultiBlocProvider` (after `MessageBloc`, maintaining alphabetical order):

```dart
        BlocProvider<SendMessageBloc>(
          create: (context) => getIt<SendMessageBloc>(),
        ),
```

### Success Criteria:

#### Automated Verification:
- [ ] BLoC files compile without errors
- [ ] Code generation runs successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] BLoC is registered in DI system
- [ ] Linting passes: `flutter analyze`

#### Manual Verification:
- [ ] Verify BLoC follows existing event/state patterns
- [ ] Check that error handling uses `failure.message` for user display
- [ ] Confirm state transitions: Initial → InProgress → Success/Error
- [ ] Test BLoC provider is accessible in widget tree

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that BLoC is properly integrated before proceeding to the next phase.

---

## Phase 4: Presentation Layer - UI Components

### Overview
Create the UI components for the reply functionality: add Reply button to table actions and create a panel/modal for composing messages.

### Changes Required:

#### 1. Create Reply Message Panel Widget
**File**: `lib/features/messages/presentation/components/reply_message_panel.dart`

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/send_message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReplyMessagePanel extends StatefulWidget {
  const ReplyMessagePanel({
    required this.workspaceId,
    required this.channelId,
    required this.replyToMessageId,
    this.onClose,
    this.onSuccess,
    super.key,
  });

  final String workspaceId;
  final String channelId;
  final String replyToMessageId;
  final VoidCallback? onClose;
  final VoidCallback? onSuccess;

  @override
  State<ReplyMessagePanel> createState() => _ReplyMessagePanelState();
}

class _ReplyMessagePanelState extends State<ReplyMessagePanel> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return;
    }

    context.read<SendMessageBloc>().add(
          SendMessage(
            text: text,
            channelId: widget.channelId,
            workspaceId: widget.workspaceId,
            replyToMessageId: widget.replyToMessageId,
          ),
        );
  }

  void _handleClose() {
    // Reset bloc state when closing
    context.read<SendMessageBloc>().add(const ResetSendMessage());
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendMessageBloc, SendMessageState>(
      listener: (context, state) {
        if (state is SendMessageSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onSuccess?.call();
          _handleClose();
        } else if (state is SendMessageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: GlassContainer(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reply to Message',
                  style: AppTextStyle.headingMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.close,
                  onPressed: _handleClose,
                  size: AppIconButtonSize.small,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message Input
            TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTextStyle.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            BlocBuilder<SendMessageBloc, SendMessageState>(
              builder: (context, state) {
                final isLoading = state is SendMessageInProgress;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      onPressed: isLoading ? null : _handleClose,
                      variant: AppButtonVariant.secondary,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      onPressed: isLoading ? null : _handleSend,
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2. Add Reply Button to Table Actions
**File**: `lib/features/dashboard/presentation/components/content_dashboard.dart`

Modify the Actions cell section (lines 212-230) to add Reply button:

**Before:**
```dart
              // Horizontal Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: AppIcons.eye,
                    tooltip: 'View Details',
                    onPressed: () => widget.onViewDetail?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () => widget.onDownloadMessage?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
```

**After:**
```dart
              // Horizontal Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: AppIcons.eye,
                    tooltip: 'View Details',
                    onPressed: () => widget.onViewDetail?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.reply,
                    tooltip: 'Reply',
                    onPressed: () => widget.onReply?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () => widget.onDownloadMessage?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
```

Add `onReply` callback to `DashboardContent` widget constructor (add after line 27):

```dart
  final ValueChanged<String>? onReply;
```

Update constructor in class signature (line 20):

```dart
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    required this.onToggleSelectAll,
    required this.selectAll,
    required this.onManualLoadMore,
    this.onViewDetail,
    this.onReply,  // Add this line
    this.onDownloadMessage,
    this.onDownloadAudio,
    this.onDownloadTranscript,
    this.onSummarize,
    this.onAIChat,
    super.key,
  });
```

#### 3. Integrate Reply Panel in Dashboard Screen
**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Add state variable for reply panel (after line 36):

```dart
  // Reply panel state
  String? _selectedMessageForReply;
```

Add handler method (after `_onAIChat`, around line 218):

```dart
  void _onReply(String messageId) {
    setState(() {
      _selectedMessageForReply = messageId;
    });
  }

  void _onCloseReplyPanel() {
    setState(() {
      _selectedMessageForReply = null;
    });
  }

  void _onReplySuccess() {
    // Refresh messages after successful reply
    context.read<MessageBloc>().add(const msg_events.RefreshMessages());
  }
```

Update `DashboardContent` widget calls to include `onReply` callback (lines 271-285 and 309-323):

Add this line in both places where `DashboardContent` is instantiated:
```dart
                    onReply: _onReply,
```

Add reply panel overlay in the Stack widget (in `build` method, after the download progress widget, around line 238):

```dart
              // Reply panel overlay
              if (_selectedMessageForReply != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _onCloseReplyPanel,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {}, // Prevent closing when clicking panel
                          child: BlocBuilder<ConversationBloc, ConversationState>(
                            builder: (context, conversationState) {
                              final selectedConversationIds = conversationState is ConversationLoaded
                                  ? conversationState.selectedConversationIds
                                  : <String>{};

                              final channelId = selectedConversationIds.isEmpty
                                  ? ''
                                  : selectedConversationIds.first;

                              return BlocBuilder<WorkspaceBloc, WorkspaceState>(
                                builder: (context, workspaceState) {
                                  final workspaceId = workspaceState is WorkspaceLoaded &&
                                          workspaceState.selectedWorkspace != null
                                      ? workspaceState.selectedWorkspace!.id
                                      : '';

                                  if (channelId.isEmpty || workspaceId.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return ReplyMessagePanel(
                                    workspaceId: workspaceId,
                                    channelId: channelId,
                                    replyToMessageId: _selectedMessageForReply!,
                                    onClose: _onCloseReplyPanel,
                                    onSuccess: _onReplySuccess,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
```

Add import at top:
```dart
import 'package:carbon_voice_console/features/messages/presentation/components/reply_message_panel.dart';
```

#### 4. Add Reply Icon (if not exists)
**File**: `lib/core/theme/app_icons.dart`

Check if `reply` icon exists. If not, add it:

```dart
  static const IconData reply = Icons.reply;
```

#### 5. Add Success/Error Colors (if not exists)
**File**: `lib/core/theme/app_colors.dart`

Check if `success` and `error` colors exist. If not, add them:

```dart
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444);   // Red
```

### Success Criteria:

#### Automated Verification:
- [ ] All UI components compile without errors
- [ ] No import errors
- [ ] Linting passes: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/`

#### Manual Verification:
- [ ] Reply button appears in the Actions column on each message row
- [ ] Clicking Reply opens the overlay with the reply panel
- [ ] Panel displays text input and Send/Cancel buttons
- [ ] Clicking outside the panel or Cancel closes it
- [ ] Text input auto-focuses when panel opens
- [ ] Empty message shows validation error
- [ ] Send button shows loading indicator while sending
- [ ] Success message appears on successful send
- [ ] Error message appears on failure
- [ ] Panel closes after successful send
- [ ] Messages refresh after successful send

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the UI works correctly and integrates with BLoC before proceeding to final testing.

---

## Phase 5: Final Integration & Testing

### Overview
Final verification that all components work together end-to-end, including API integration.

### Changes Required:

#### 1. Add UUID Dependency
**File**: `pubspec.yaml`

Add under dependencies:
```yaml
  uuid: ^4.5.1
```

Then run:
```bash
flutter pub get
```

#### 2. Run Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. Verify DI Registration
Check that `injection.config.dart` includes all new classes after regeneration.

### Success Criteria:

#### Automated Verification:
- [ ] All dependencies install successfully: `flutter pub get`
- [ ] Code generation completes without errors
- [ ] No compilation errors: `flutter analyze`
- [ ] Code formatting is clean: `dart format lib/`
- [ ] App builds successfully: `flutter build web` (or platform target)

#### Manual Verification:
- [ ] **End-to-End Flow**:
  1. Launch app and navigate to dashboard
  2. Select a workspace and conversation with messages
  3. Click Reply button on a message
  4. Enter text in the reply panel
  5. Click Send
  6. Verify success message appears
  7. Verify panel closes
  8. Verify messages list refreshes (may need manual refresh)
  9. Verify sent message appears in conversation

- [ ] **Error Handling**:
  1. Test with empty message (should show validation error)
  2. Test with network disconnected (should show network error)
  3. Test with invalid credentials (should show auth error)

- [ ] **UI/UX**:
  1. Verify Reply button icon and tooltip
  2. Verify panel styling matches design system (GlassContainer)
  3. Verify overlay darkens background
  4. Verify clicking outside closes panel
  5. Verify ESC key closes panel (if applicable)
  6. Verify loading state disables buttons
  7. Verify success/error snackbars display correctly

- [ ] **API Integration**:
  1. Check browser DevTools Network tab for POST to `/v3/messages/start`
  2. Verify request payload matches API specification
  3. Verify response is parsed correctly
  4. Verify reply-to relationship is set (`reply_to_message_id` field)

**Implementation Note**: This is the final phase. Once all automated and manual verification passes, the feature is complete and ready for production use.

---

## Testing Strategy

### Unit Tests:
- **SendMessageBloc**:
  - Test event handling (SendMessage, ResetSendMessage)
  - Test state transitions (Initial → InProgress → Success/Error)
  - Mock use case to test error handling

- **SendMessageUseCase**:
  - Test successful message send
  - Test error propagation from repository

- **MessageRepositoryImpl**:
  - Test sendMessage method with mocked datasource
  - Test error handling (ServerException, NetworkException)
  - Test cache invalidation

- **SendMessageMappers**:
  - Test `toDto()` creates correct DTO structure
  - Test `toDomain()` maps response correctly
  - Test unique client ID generation

### Integration Tests:
- Test complete flow from UI button click to API call
- Test BLoC provider access in widget tree
- Test panel open/close behavior
- Test success callback triggers message refresh

### Manual Testing Steps:
1. **Happy Path**:
   - Send a simple text message reply
   - Verify message appears in conversation

2. **Edge Cases**:
   - Very long message text (test textarea scrolling)
   - Special characters in message
   - Emoji in message

3. **Error Cases**:
   - Network timeout
   - Server error (500)
   - Unauthorized (401)
   - Invalid request (400)

## Performance Considerations

- **Cache Invalidation**: After sending, only the specific conversation cache is cleared (not all messages)
- **Unique Client IDs**: Generated locally using UUID v4 (no server round-trip)
- **Lazy BLoC**: SendMessageBloc is created once via DI and reused
- **Text Input**: No real-time validation to avoid performance overhead
- **Panel Overlay**: Uses efficient Stack/Positioned for minimal reflow

## Migration Notes

No data migration required - this is a new feature that adds functionality without modifying existing data structures.

## Future Enhancements (Out of Scope)

- Real-time message updates via WebSocket
- Message drafts (save unfinished messages)
- Rich text editor with formatting
- @mentions and emoji picker
- File attachments
- Voice message recording
- Message editing/deletion
- Threading UI (show reply chain)
- Read receipts
- Typing indicators

## References

- API Specification: `/v3/messages/start` endpoint (provided in task description)
- Existing patterns:
  - `MessageBloc`: [lib/features/messages/presentation/bloc/message_bloc.dart:14-278](lib/features/messages/presentation/bloc/message_bloc.dart)
  - `MessageRepository`: [lib/features/messages/domain/repositories/message_repository.dart:5-19](lib/features/messages/domain/repositories/message_repository.dart)
  - `MessageRemoteDataSource`: [lib/features/messages/data/datasources/message_remote_datasource_impl.dart:11-133](lib/features/messages/data/datasources/message_remote_datasource_impl.dart)
  - `AuthenticatedHttpService`: [lib/core/network/authenticated_http_service.dart:8-116](lib/core/network/authenticated_http_service.dart)
  - Table Actions: [lib/features/dashboard/presentation/components/content_dashboard.dart:212-230](lib/features/dashboard/presentation/components/content_dashboard.dart)
