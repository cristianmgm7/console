# Enhanced Audio File Naming Implementation Plan

## Overview

We need to modify the audio file download system to use a more organized naming convention. Currently, files are saved as `<message-id>.mp3` in date-based folders. The new format should include date, channel ID, message ID, and parent ID for better organization and traceability.

## Current State Analysis

**Current Implementation:**
- Files are stored in: `~/Downloads/CarbonVoice/YYYY-MM-DD/`
- File naming: `<message-id>.mp3`
- Message entity has: `id`, `conversationId` (from channelIds), `createdAt`
- Missing: `parentMessageId` field in domain entity

**Key Findings:**
- Message DTO has `parentMessageId` field but it's not mapped to the domain entity
- Channel ID is available via `message.conversationId` getter
- Date-based folder structure already exists
- File naming logic is in `DownloadAudioMessagesUsecase._processDownloadResponse()`

## Desired End State

Audio files are saved with the new naming format:
```
2025_11_26_cid_<channel-id>_<message-id>_pid_<parent-id>.mp3
```

Where:
- Date format: `YYYY_MM_DD` (from message.createdAt)
- `cid_` prefix for channel/conversation ID
- Message ID (existing)
- `pid_` prefix for parent message ID
- `.mp3` or appropriate extension

## Implementation Approach

We'll implement this in phases to ensure backward compatibility and testability.

## Phase 1: Update Message Entity and Mapping

### Overview
Add the missing `parentMessageId` field to the Message domain entity and update the DTO mapper.

### Changes Required:

#### 1. Update Message Entity
**File**: `lib/features/messages/domain/entities/message.dart`
**Changes**: Add `parentMessageId` field to the Message class

```dart
class Message extends Equatable {
  const Message({
    // ... existing fields ...
    this.parentMessageId,
    // ... rest of fields ...
  });

  // ... existing fields ...
  final String? parentMessageId;

  // ... existing props ...
}
```

#### 2. Update Message DTO Mapper
**File**: `lib/features/messages/data/mappers/message_dto_mapper.dart`
**Changes**: Include `parentMessageId` in the `toDomain()` conversion

```dart
return Message(
  // ... existing fields ...
  parentMessageId: parentMessageId,
  // ... rest of fields ...
);
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `flutter build`
- [ ] Unit tests pass: `flutter test`
- [ ] Message mapping tests pass

#### Manual Verification:
- [ ] Message objects can be created with parentMessageId
- [ ] DTO to domain conversion includes parentMessageId

## Phase 2: Implement New File Naming Logic

### Overview
Modify the download use case to generate the new file naming format using the enhanced Message entity.

### Changes Required:

#### 1. Create File Naming Helper Method
**File**: `lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart`
**Changes**: Add a new method to generate the enhanced file name

```dart
String _generateAudioFileName(Message message, AudioModel audioModel) {
  final dateStr = '${message.createdAt.year}_${message.createdAt.month.toString().padLeft(2, '0')}_${message.createdAt.day.toString().padLeft(2, '0')}';
  final channelId = message.conversationId;
  final messageId = message.id;
  final parentId = message.parentMessageId ?? 'none';
  final audioId = audioModel.id;

  return '${dateStr}_cid_${channelId}_${messageId}_pid_${parentId}.mp3';
}
```

#### 2. Update File Saving Logic
**File**: `lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart`
**Changes**: Modify `_processDownloadResponse` to use the new naming method

```dart
// Generate new file name using message and audio metadata
final fileName = _generateAudioFileName(message, message.audioModels.first);

// Save file using repository (pass message object for metadata access)
final saveResult = await _downloadRepository.saveAudioFile(
  messageId,
  response.bodyBytes,
  fileName,
  contentType,
);
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `flutter build`
- [ ] Unit tests pass: `flutter test`
- [ ] File naming logic can be unit tested

#### Manual Verification:
- [ ] Downloaded files have the new naming format
- [ ] Files include all required components (date, cid, message-id, pid)

## Phase 3: Handle Edge Cases and Testing

### Overview
Add proper handling for edge cases like missing parent IDs and ensure the implementation is robust.

### Changes Required:

#### 1. Handle Missing Parent ID
**File**: `lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart`
**Changes**: Use 'none' or similar placeholder when parentMessageId is null

#### 2. Add Logging for New Naming
**File**: `lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart`
**Changes**: Add debug logging for the new file naming process

#### 3. Update Tests
**File**: `test/message_dto_test.dart` (or create new test file)
**Changes**: Add tests for the new file naming logic

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] Edge cases handled (missing parent ID, empty channel ID)

#### Manual Verification:
- [ ] Download messages with and without parent IDs
- [ ] Verify file names are correctly formatted
- [ ] Check that existing functionality still works

## Testing Strategy

### Unit Tests:
- Test file name generation with various message configurations
- Test edge cases (null parent ID, empty channel ID)
- Test date formatting

### Integration Tests:
- Test complete download flow with new naming
- Verify files are saved with correct names in correct directories

### Manual Testing Steps:
1. Download a message with parent ID - verify naming includes pid_*
2. Download a message without parent ID - verify naming includes pid_none
3. Verify date format matches message creation date
4. Verify channel ID is correctly included

## Performance Considerations

The new naming logic adds minimal computational overhead:
- Date formatting: O(1)
- String concatenation: O(1)
- No additional API calls or file operations

## Migration Notes

This change is backward compatible:
- Existing download functionality remains unchanged
- New downloads will use enhanced naming
- No database migrations required
- Existing files remain accessible

## References

- Original implementation: `lib/features/message_download/domain/usecases/download_audio_messages_usecase.dart`
- Current file naming: `lib/features/message_download/utils/file_name_helper.dart`
- Message entity: `lib/features/messages/domain/entities/message.dart`




















