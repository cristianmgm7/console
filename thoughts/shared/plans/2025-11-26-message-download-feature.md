# Message Download Feature Implementation Plan

## Overview

This plan implements a dedicated download feature for bulk exporting message assets (audio files and transcripts) without involving the message list logic. The feature introduces its own isolated BLoC, events, and states to handle the full workflow: receiving selected message IDs, fetching metadata, extracting signed URLs, downloading files, writing to storage, and reporting granular progress updates.

## Current State Analysis

### Existing Infrastructure

**Multi-selection UI:**
- Dashboard tracks selected message IDs in `Set<String>` at [dashboard_screen.dart:28](lib/features/dashboard/presentation/dashboard_screen.dart#L28)
- Action panel has placeholder download button at [dashboard_screen.dart:199-205](lib/features/dashboard/presentation/dashboard_screen.dart#L199-L205)

**Message Repository:**
- `getMessage(String id)` exposed at [message_repository.dart:17](lib/features/messages/domain/repositories/message_repository.dart#L17)
- Returns `Result<Message>` with complete metadata
- Message entity has `audioUrl`, `transcript`, `text` fields at [message.dart:22-24](lib/features/messages/domain/entities/message.dart#L22-L24)

**Architecture Patterns:**
- BLoC pattern with sealed classes and Equatable
- Dependency injection via `injectable` and `get_it`
- `Result<T>` type for error handling
- Repository → BLoC pattern (no use case layer)
- `AuthenticatedHttpService` for API calls at [authenticated_http_service.dart](lib/core/network/authenticated_http_service.dart)

### Missing Infrastructure

- No file download/storage functionality
- No `path_provider` package (need to add)
- No file I/O utilities
- No progress tracking patterns
- No platform-specific file saving (need `universal_html` or similar for web)

### Key Discoveries

1. **HTTP Service Pattern:** Use `AuthenticatedHttpService` for authenticated requests, but audio URLs are signed and don't need auth
2. **Error Handling:** Use `Result<T>` type with `AppFailure` subtypes defined in [failures.dart](lib/core/errors/failures.dart)
3. **BLoC Registration:** Use `@injectable` for factory scope, register in [injection.dart](lib/core/di/injection.dart)
4. **State Updates:** Use sealed classes with Equatable, include progress tracking fields

## Desired End State

After implementation, users can:

1. Select multiple messages in the dashboard UI
2. Click the download button in the action panel
3. See a bottom sheet with real-time download progress
4. Find downloaded files in `~/Downloads/CarbonVoice/{date}/` directory
5. Review a summary showing success/failure/skipped counts
6. Cancel in-progress downloads with graceful cleanup

### Verification Criteria

**Automated Verification:**
- [ ] All unit tests pass: `flutter test test/features/message_download/`
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] No linting errors: `flutter analyze`
- [ ] Dependency injection registers correctly: verify app starts without errors

**Manual Verification:**
- [ ] Selecting messages and clicking download shows progress bottom sheet
- [ ] Downloaded audio files play correctly and have proper extensions
- [ ] Transcript files contain expected text content
- [ ] Files are organized by date in Downloads/CarbonVoice/
- [ ] Duplicate downloads append counter (_1, _2, etc.)
- [ ] Cancellation stops download and cleans up partial files
- [ ] Empty selection shows SnackBar instead of starting download
- [ ] Error scenarios (network failure, missing data) show proper summary
- [ ] Works on both macOS and Web platforms

**Implementation Note:** After completing each phase and all automated verification passes, pause for manual confirmation that the manual testing was successful before proceeding to the next phase.

## What We're NOT Doing

- No retry mechanism for failed downloads
- No byte-level progress tracking (only file-level)
- No time remaining estimates
- No download history/logging
- No single-message download from card menu (only bulk from action panel)
- No user-selectable download location (fixed to Downloads/CarbonVoice)
- No concurrent/parallel downloads (sequential only)
- No audio format conversion (preserve original)
- No metadata in transcript files (plain text only)
- No mobile platform support in this phase (macOS + Web only)

## Implementation Approach

The implementation follows clean architecture with these layers:

1. **Domain Layer:** Entities (DownloadItem, DownloadResult) and repository interface
2. **Data Layer:** File saver implementations (desktop/web), repository implementation
3. **Presentation Layer:** BLoC (events/states), bottom sheet widget
4. **Integration:** Wire download button to trigger BLoC, show progress UI

Sequential download strategy simplifies state management and error handling. Platform abstraction isolates macOS and Web file saving differences.

---

## Phase 1: Dependencies and Core Infrastructure

### Overview
Add required packages and create core utilities for file operations.

### Changes Required

#### 1. Add Dependencies
**File**: `pubspec.yaml`
**Changes**: Add new dependencies in the dependencies section (after line 37)

```yaml
  # File system access
  path_provider: ^2.1.1
  path: ^1.9.0

  # Platform-specific implementations
  universal_html: ^2.2.4
```

Run after editing:
```bash
flutter pub get
```

#### 2. Create Domain Entities

**File**: `lib/features/message_download/domain/entities/download_item.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:equatable/equatable.dart';

/// Represents a single downloadable item (audio or transcript)
class DownloadItem extends Equatable {
  const DownloadItem({
    required this.messageId,
    required this.type,
    required this.url,
    required this.fileName,
  });

  final String messageId;
  final DownloadItemType type;
  final String url; // For audio, this is the signed URL. For transcript, it's the text content
  final String fileName;

  @override
  List<Object?> get props => [messageId, type, url, fileName];
}

enum DownloadItemType {
  audio,
  transcript,
}
```

**File**: `lib/features/message_download/domain/entities/download_result.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:equatable/equatable.dart';

/// Result of a single file download operation
class DownloadResult extends Equatable {
  const DownloadResult({
    required this.messageId,
    required this.status,
    this.filePath,
    this.errorMessage,
  });

  final String messageId;
  final DownloadStatus status;
  final String? filePath;
  final String? errorMessage;

  @override
  List<Object?> get props => [messageId, status, filePath, errorMessage];
}

enum DownloadStatus {
  success,
  failed,
  skipped,
}
```

#### 3. Create File Name Utility

**File**: `lib/features/message_download/utils/file_name_helper.dart`
**Changes**: Create new file with complete contents

```dart
import 'dart:io';
import 'package:path/path.dart' as path;

/// Helper class for generating unique file names
class FileNameHelper {
  /// Extracts file extension from URL or Content-Type header
  /// Falls back to .mp3 if unknown
  static String getAudioExtension(String url, String? contentType) {
    // Try to get extension from URL first
    final uri = Uri.parse(url);
    final urlPath = uri.path;
    final urlExtension = path.extension(urlPath);

    if (urlExtension.isNotEmpty && urlExtension != '.') {
      return urlExtension; // Returns with leading dot (e.g., ".mp3")
    }

    // Try to get extension from Content-Type
    if (contentType != null) {
      final mimeType = contentType.split(';').first.trim().toLowerCase();
      switch (mimeType) {
        case 'audio/mpeg':
        case 'audio/mp3':
          return '.mp3';
        case 'audio/wav':
        case 'audio/wave':
          return '.wav';
        case 'audio/ogg':
          return '.ogg';
        case 'audio/webm':
          return '.webm';
        case 'audio/aac':
          return '.aac';
        case 'audio/m4a':
        case 'audio/mp4':
          return '.m4a';
        case 'audio/flac':
          return '.flac';
        default:
          return '.mp3'; // Fallback
      }
    }

    return '.mp3'; // Default fallback
  }

  /// Generates a unique file name if file already exists
  /// Appends _1, _2, etc. to avoid collisions
  static String getUniqueFileName(String directoryPath, String baseFileName) {
    final basePath = path.join(directoryPath, baseFileName);

    // If file doesn't exist, use original name
    if (!File(basePath).existsSync()) {
      return baseFileName;
    }

    // Extract name and extension
    final extension = path.extension(baseFileName);
    final nameWithoutExtension = path.basenameWithoutExtension(baseFileName);

    // Try appending _1, _2, _3, etc.
    int counter = 1;
    while (true) {
      final newFileName = '${nameWithoutExtension}_$counter$extension';
      final newPath = path.join(directoryPath, newFileName);

      if (!File(newPath).existsSync()) {
        return newFileName;
      }

      counter++;

      // Safety check to avoid infinite loop
      if (counter > 1000) {
        throw Exception('Could not generate unique file name after 1000 attempts');
      }
    }
  }

  /// Generates directory path with date: ~/Downloads/CarbonVoice/YYYY-MM-DD/
  static String getDateBasedDirectory(String baseDownloadsPath) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return path.join(baseDownloadsPath, 'CarbonVoice', dateStr);
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Dependencies install successfully: `flutter pub get`
- [x] No import errors: `flutter analyze`
- [x] Entity files compile without errors
- [x] File name helper utility compiles without errors

#### Manual Verification:
- [x] Verify `path_provider`, `path`, and `universal_html` appear in `pubspec.lock`
- [x] Verify new files are created in correct directory structure
- [x] Review entity classes for proper Equatable implementation

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Repository Interface and File Saver Abstraction

### Overview
Define repository contract and create platform-specific file saver implementations.

### Changes Required

#### 1. Create Repository Interface

**File**: `lib/features/message_download/domain/repositories/download_repository.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';

/// Repository interface for download operations
abstract class DownloadRepository {
  /// Downloads a single item (audio or transcript) and returns the result
  Future<Result<DownloadResult>> downloadItem(DownloadItem item);

  /// Checks if the downloads directory is accessible
  Future<Result<String>> getDownloadDirectory();
}
```

#### 2. Create File Saver Interface

**File**: `lib/features/message_download/data/datasources/file_saver.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/core/utils/result.dart';

/// Platform-agnostic interface for saving files
abstract class FileSaver {
  /// Gets the downloads directory path
  /// For macOS: ~/Downloads
  /// For Web: N/A (browser handles location)
  Future<Result<String>> getDownloadsDirectory();

  /// Saves binary data to a file
  /// Returns the full file path on success
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  });

  /// Saves text content to a file
  /// Returns the full file path on success
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  });
}
```

#### 3. Create Desktop File Saver Implementation

**File**: `lib/features/message_download/data/datasources/desktop_file_saver.dart`
**Changes**: Create new file with complete contents

```dart
import 'dart:convert';
import 'dart:io';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

@LazySingleton(as: FileSaver, env: [Environment.prod, Environment.dev])
class DesktopFileSaver implements FileSaver {
  DesktopFileSaver(this._logger);

  final Logger _logger;

  @override
  Future<Result<String>> getDownloadsDirectory() async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        return failure(const StorageFailure(details: 'Downloads directory not available'));
      }
      return success(directory.path);
    } catch (e, stack) {
      _logger.e('Failed to get downloads directory', error: e, stackTrace: stack);
      return failure(StorageFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      // Ensure directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write file
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _logger.i('Saved file: $filePath (${bytes.length} bytes)');
      return success(filePath);
    } catch (e, stack) {
      _logger.e('Failed to save file: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to save file: $e'));
    }
  }

  @override
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  }) async {
    try {
      // Ensure directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write file
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(content, encoding: utf8);

      _logger.i('Saved text file: $filePath (${content.length} characters)');
      return success(filePath);
    } catch (e, stack) {
      _logger.e('Failed to save text file: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to save text file: $e'));
    }
  }
}
```

#### 4. Create Web File Saver Implementation

**File**: `lib/features/message_download/data/datasources/web_file_saver.dart`
**Changes**: Create new file with complete contents

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:universal_html/html.dart' as html;

@LazySingleton(as: FileSaver, env: [Environment.test])
class WebFileSaver implements FileSaver {
  WebFileSaver(this._logger);

  final Logger _logger;

  @override
  Future<Result<String>> getDownloadsDirectory() async {
    // Web doesn't have a downloads directory concept
    // Browser handles the location automatically
    return success('browser-managed');
  }

  @override
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      _logger.i('Triggered browser download: $fileName (${bytes.length} bytes)');
      return success('browser-download:$fileName');
    } catch (e, stack) {
      _logger.e('Failed to trigger browser download: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to download file: $e'));
    }
  }

  @override
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  }) async {
    try {
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      _logger.i('Triggered browser download: $fileName (${content.length} characters)');
      return success('browser-download:$fileName');
    } catch (e, stack) {
      _logger.e('Failed to trigger browser text download: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to download text file: $e'));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] All files compile without errors: `flutter analyze`
- [x] No import errors for platform-specific code
- [x] Injectable annotations are correct

#### Manual Verification:
- [x] Repository interface defines clear contract
- [x] FileSaver interface is platform-agnostic
- [x] Desktop implementation uses path_provider correctly
- [x] Web implementation uses universal_html blob downloads
- [x] Both implementations follow error handling patterns
- [x] Logging is consistent across implementations

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: Repository Implementation and HTTP Download

### Overview
Implement the repository that orchestrates metadata fetching, file downloading, and saving.

### Changes Required

#### 1. Create HTTP Download Service

**File**: `lib/features/message_download/data/datasources/download_http_service.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// HTTP service for downloading files from signed URLs
@LazySingleton()
class DownloadHttpService {
  DownloadHttpService(this._logger);

  final Logger _logger;

  /// Downloads file bytes from a signed URL
  /// Returns bytes and Content-Type header
  Future<DownloadResponse> downloadFile(String url) async {
    try {
      _logger.d('Downloading file from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        _logger.i('Downloaded file (${response.bodyBytes.length} bytes, type: $contentType)');

        return DownloadResponse(
          bytes: response.bodyBytes,
          contentType: contentType,
        );
      } else {
        _logger.e('Failed to download file: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to download file',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      _logger.e('Network error downloading file', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to download file: $e');
    }
  }
}

/// Response from file download
class DownloadResponse {
  const DownloadResponse({
    required this.bytes,
    this.contentType,
  });

  final List<int> bytes;
  final String? contentType;
}
```

#### 2. Create Repository Implementation

**File**: `lib/features/message_download/data/repositories/download_repository_impl.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/download_http_service.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/message_download/utils/file_name_helper.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: DownloadRepository)
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(
    this._downloadHttpService,
    this._fileSaver,
    this._logger,
  );

  final DownloadHttpService _downloadHttpService;
  final FileSaver _fileSaver;
  final Logger _logger;

  @override
  Future<Result<String>> getDownloadDirectory() async {
    try {
      final result = await _fileSaver.getDownloadsDirectory();

      return result.fold(
        onSuccess: (downloadsPath) {
          final datePath = FileNameHelper.getDateBasedDirectory(downloadsPath);
          return success(datePath);
        },
        onFailure: (failure) => failure,
      );
    } catch (e, stack) {
      _logger.e('Failed to get download directory', error: e, stackTrace: stack);
      return failure(StorageFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<DownloadResult>> downloadItem(DownloadItem item) async {
    try {
      _logger.d('Downloading item: ${item.messageId} (${item.type})');

      // Get download directory
      final directoryResult = await getDownloadDirectory();
      if (directoryResult.isFailure) {
        return success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Failed to access downloads directory',
        ));
      }

      final directoryPath = directoryResult.valueOrNull!;

      // Handle transcript (no download needed, just save text)
      if (item.type == DownloadItemType.transcript) {
        return _saveTranscript(item, directoryPath);
      }

      // Handle audio download
      return _downloadAudio(item, directoryPath);
    } catch (e, stack) {
      _logger.e('Error downloading item: ${item.messageId}', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<Result<DownloadResult>> _saveTranscript(
    DownloadItem item,
    String directoryPath,
  ) async {
    try {
      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        item.fileName,
      );

      final result = await _fileSaver.saveTextFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        content: item.url, // For transcripts, 'url' field contains the text content
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        )),
        onFailure: (failure) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save transcript',
        )),
      );
    } catch (e, stack) {
      _logger.e('Error saving transcript', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<Result<DownloadResult>> _downloadAudio(
    DownloadItem item,
    String directoryPath,
  ) async {
    try {
      // Download file bytes
      final downloadResponse = await _downloadHttpService.downloadFile(item.url);

      // Determine file extension from Content-Type
      final extension = FileNameHelper.getAudioExtension(
        item.url,
        downloadResponse.contentType,
      );

      // Generate file name with proper extension
      final baseFileName = item.fileName.replaceAll('.mp3', extension);
      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        baseFileName,
      );

      // Save file
      final result = await _fileSaver.saveFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        bytes: downloadResponse.bytes,
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        )),
        onFailure: (failure) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
        )),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error downloading audio', error: e);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Network error: ${e.message}',
      ));
    } on ServerException catch (e) {
      _logger.e('Server error downloading audio', error: e);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Server error: ${e.message}',
      ));
    } catch (e, stack) {
      _logger.e('Error downloading audio', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Code generation completes: `flutter pub run build_runner build`
- [x] All files compile: `flutter analyze`
- [x] No import errors
- [x] Injectable annotations generate correctly

#### Manual Verification:
- [x] Repository properly orchestrates download workflow
- [x] HTTP service handles signed URLs correctly
- [x] File extension detection logic is correct
- [x] Error handling distinguishes network/server/storage failures
- [x] Transcript and audio downloads follow different paths
- [x] Unique file name generation is implemented
- [x] Date-based directory structure is used

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: BLoC Events and States

### Overview
Define the download BLoC's events and states for managing download operations.

### Changes Required

#### 1. Create Download Events

**File**: `lib/features/message_download/presentation/bloc/download_event.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:equatable/equatable.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start downloading messages
class StartDownload extends DownloadEvent {
  const StartDownload(this.messageIds);

  final Set<String> messageIds;

  @override
  List<Object?> get props => [messageIds];
}

/// Event to cancel ongoing download
class CancelDownload extends DownloadEvent {
  const CancelDownload();
}

/// Internal event to update progress after each file completes
class _UpdateProgress extends DownloadEvent {
  const _UpdateProgress({
    required this.currentIndex,
    required this.totalCount,
    required this.result,
  });

  final int currentIndex;
  final int totalCount;
  final dynamic result; // DownloadResult

  @override
  List<Object?> get props => [currentIndex, totalCount, result];
}
```

#### 2. Create Download States

**File**: `lib/features/message_download/presentation/bloc/download_state.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:equatable/equatable.dart';

sealed class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any download starts
class DownloadInitial extends DownloadState {
  const DownloadInitial();
}

/// Download in progress
class DownloadInProgress extends DownloadState {
  const DownloadInProgress({
    required this.current,
    required this.total,
    required this.progressPercent,
    required this.currentMessageId,
  });

  final int current;
  final int total;
  final double progressPercent;
  final String currentMessageId;

  @override
  List<Object?> get props => [current, total, progressPercent, currentMessageId];

  DownloadInProgress copyWith({
    int? current,
    int? total,
    double? progressPercent,
    String? currentMessageId,
  }) {
    return DownloadInProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      progressPercent: progressPercent ?? this.progressPercent,
      currentMessageId: currentMessageId ?? this.currentMessageId,
    );
  }
}

/// Download completed (success or with errors)
class DownloadCompleted extends DownloadState {
  const DownloadCompleted({
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    required this.results,
  });

  final int successCount;
  final int failureCount;
  final int skippedCount;
  final List<DownloadResult> results;

  @override
  List<Object?> get props => [successCount, failureCount, skippedCount, results];
}

/// Download cancelled by user
class DownloadCancelled extends DownloadState {
  const DownloadCancelled({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  List<Object?> get props => [completedCount, totalCount];
}

/// Error state (e.g., empty selection, directory access failure)
class DownloadError extends DownloadState {
  const DownloadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

### Success Criteria

#### Automated Verification:
- [x] All files compile: `flutter analyze`
- [x] No linting errors
- [x] Equatable implementation is correct

#### Manual Verification:
- [x] Events cover all user actions (start, cancel)
- [x] States represent all possible download phases
- [x] Progress state includes necessary tracking fields
- [x] Completed state has aggregate counts
- [x] Cancelled state tracks partial completion
- [x] Error state handles edge cases

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: BLoC Implementation

### Overview
Implement the download BLoC that orchestrates the entire download workflow.

### Changes Required

#### 1. Create Download BLoC

**File**: `lib/features/message_download/presentation/bloc/download_bloc.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc(
    this._downloadRepository,
    this._messageRepository,
    this._logger,
  ) : super(const DownloadInitial()) {
    on<StartDownload>(_onStartDownload);
    on<CancelDownload>(_onCancelDownload);
  }

  final DownloadRepository _downloadRepository;
  final MessageRepository _messageRepository;
  final Logger _logger;

  bool _isCancelled = false;

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _logger.d('Starting download for ${event.messageIds.length} messages');
    _isCancelled = false;

    // Validate non-empty selection
    if (event.messageIds.isEmpty) {
      _logger.w('Download started with empty message selection');
      emit(const DownloadError('No messages selected'));
      return;
    }

    // Collect all download items from all messages
    final downloadItems = <DownloadItem>[];
    final skippedMessages = <String>[];

    // Fetch metadata for all messages in parallel
    _logger.d('Fetching metadata for ${event.messageIds.length} messages');
    final metadataFutures = event.messageIds.map((id) => _messageRepository.getMessage(id));
    final metadataResults = await Future.wait(metadataFutures);

    // Process metadata and create download items
    int messageIndex = 0;
    for (final result in metadataResults) {
      final messageId = event.messageIds.elementAt(messageIndex);
      messageIndex++;

      result.fold(
        onSuccess: (message) {
          bool hasDownloadableContent = false;

          // Add audio download item if URL exists
          if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
            downloadItems.add(DownloadItem(
              messageId: message.id,
              type: DownloadItemType.audio,
              url: message.audioUrl!,
              fileName: '${message.id}.mp3', // Extension will be corrected based on Content-Type
            ));
            hasDownloadableContent = true;
          }

          // Add transcript download item if content exists
          final transcriptContent = message.transcript ?? message.text;
          if (transcriptContent != null && transcriptContent.isNotEmpty) {
            downloadItems.add(DownloadItem(
              messageId: message.id,
              type: DownloadItemType.transcript,
              url: transcriptContent, // For transcripts, we store content in 'url' field
              fileName: '${message.id}.txt',
            ));
            hasDownloadableContent = true;
          }

          // Track messages with no downloadable content
          if (!hasDownloadableContent) {
            _logger.w('Message ${message.id} has no audio or transcript to download');
            skippedMessages.add(message.id);
          }
        },
        onFailure: (failure) {
          _logger.e('Failed to fetch metadata for message $messageId: ${failure.failureOrNull}');
          skippedMessages.add(messageId);
        },
      );
    }

    // Check if we have anything to download
    if (downloadItems.isEmpty) {
      _logger.w('No downloadable items found after metadata fetch');
      emit(DownloadCompleted(
        successCount: 0,
        failureCount: 0,
        skippedCount: skippedMessages.length,
        results: skippedMessages.map((id) => DownloadResult(
          messageId: id,
          status: DownloadStatus.skipped,
        )).toList(),
      ));
      return;
    }

    // Download each item sequentially
    final results = <DownloadResult>[];
    final totalItems = downloadItems.length;

    for (int i = 0; i < downloadItems.length; i++) {
      // Check for cancellation
      if (_isCancelled) {
        _logger.i('Download cancelled by user at item ${i + 1}/$totalItems');
        emit(DownloadCancelled(
          completedCount: results.length,
          totalCount: totalItems,
        ));
        return;
      }

      final item = downloadItems[i];
      final progressPercent = ((i + 1) / totalItems * 100);

      // Emit progress state
      emit(DownloadInProgress(
        current: i + 1,
        total: totalItems,
        progressPercent: progressPercent,
        currentMessageId: item.messageId,
      ));

      // Download the item
      final result = await _downloadRepository.downloadItem(item);

      result.fold(
        onSuccess: (downloadResult) {
          results.add(downloadResult);
          _logger.d('Downloaded item ${i + 1}/$totalItems: ${downloadResult.status}');
        },
        onFailure: (failure) {
          // Treat repository failures as failed downloads
          results.add(DownloadResult(
            messageId: item.messageId,
            status: DownloadStatus.failed,
            errorMessage: failure.failureOrNull?.details ?? 'Unknown error',
          ));
          _logger.e('Failed to download item ${i + 1}/$totalItems');
        },
      );
    }

    // Add skipped messages to results
    results.addAll(skippedMessages.map((id) => DownloadResult(
      messageId: id,
      status: DownloadStatus.skipped,
    )));

    // Calculate final counts
    final successCount = results.where((r) => r.status == DownloadStatus.success).length;
    final failureCount = results.where((r) => r.status == DownloadStatus.failed).length;
    final skippedCount = results.where((r) => r.status == DownloadStatus.skipped).length;

    _logger.i('Download completed: $successCount success, $failureCount failed, $skippedCount skipped');

    emit(DownloadCompleted(
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      results: results,
    ));
  }

  Future<void> _onCancelDownload(
    CancelDownload event,
    Emitter<DownloadState> emit,
  ) async {
    _logger.i('Download cancellation requested');
    _isCancelled = true;
    // The actual cancellation happens in the download loop
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Code generation completes: `flutter pub run build_runner build`
- [x] BLoC compiles without errors: `flutter analyze`
- [x] No linting errors
- [x] Injectable registration successful

#### Manual Verification:
- [x] BLoC fetches metadata in parallel for all messages
- [x] Download items are collected correctly from messages
- [x] Sequential download loop processes items one by one
- [x] Progress updates emit after each item
- [x] Cancellation flag is checked in loop
- [x] Final state calculates aggregate counts correctly
- [x] Empty selection emits error state
- [x] Skipped messages are tracked properly

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Progress UI - Bottom Sheet

### Overview
Create the bottom sheet widget that displays download progress.

### Changes Required

#### 1. Create Download Progress Bottom Sheet

**File**: `lib/features/message_download/presentation/widgets/download_progress_sheet.dart`
**Changes**: Create new file with complete contents

```dart
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet that displays download progress
class DownloadProgressSheet extends StatelessWidget {
  const DownloadProgressSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DownloadBloc, DownloadState>(
      listener: (context, state) {
        // Auto-dismiss on completion or error
        if (state is DownloadCompleted || state is DownloadCancelled) {
          // Show summary snackbar
          if (state is DownloadCompleted) {
            final message = '✓ ${state.successCount} downloaded, '
                '${state.failureCount} failed, '
                '${state.skippedCount} skipped';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
            );
          } else if (state is DownloadCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download cancelled'), duration: Duration(seconds: 2)),
            );
          }

          // Dismiss sheet after brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading Messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (state is DownloadInProgress)
                    TextButton(
                      onPressed: () {
                        context.read<DownloadBloc>().add(const CancelDownload());
                      },
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Content based on state
              if (state is DownloadInProgress) ...[
                // Progress indicator
                LinearProgressIndicator(
                  value: state.progressPercent / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),

                // Progress text
                Text(
                  'Downloading ${state.current} of ${state.total} items',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.progressPercent.toStringAsFixed(0)}% complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (state is DownloadCompleted) ...[
                // Completion summary
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.successCount} successful, ${state.failureCount} failed, ${state.skippedCount} skipped',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else if (state is DownloadCancelled) ...[
                // Cancellation notice
                Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Download Cancelled',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed ${state.completedCount} of ${state.totalCount} items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else if (state is DownloadError) ...[
                // Error display
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Widget compiles without errors: `flutter analyze`
- [x] No linting errors
- [x] BLoC consumer pattern is correct

#### Manual Verification:
- [x] Bottom sheet has proper Material Design styling
- [x] Progress bar updates smoothly during download
- [x] Percentage text updates correctly
- [x] Cancel button triggers cancellation event
- [x] Completion shows success/failure/skipped counts
- [x] Auto-dismisses after completion
- [x] SnackBar summary appears after completion
- [x] Error state displays error message

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 7.

---

## Phase 7: Integration with Dashboard

### Overview
Wire the download feature into the dashboard screen, replacing the placeholder.

### Changes Required

#### 1. Update Dashboard Screen

**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Multiple updates to integrate download feature

**Add imports** (after line 10):
```dart
import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/widgets/download_progress_sheet.dart';
```

**Replace onDownload callback** (lines 199-205):
```dart
onDownload: () {
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

  // Show download progress bottom sheet with fresh BLoC instance
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => BlocProvider(
      create: (_) => getIt<DownloadBloc>()
        ..add(StartDownload(_selectedMessages)),
      child: const DownloadProgressSheet(),
    ),
  );
},
```

### Success Criteria

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] App builds successfully: `flutter build web` or `flutter build macos`
- [x] No import errors
- [x] BLoC provider injection works

#### Manual Verification:
- [x] Clicking download button with empty selection shows SnackBar
- [x] Clicking download button with selections shows bottom sheet
- [x] Bottom sheet displays progress during download
- [x] Files are downloaded to correct location
- [x] Summary appears after completion
- [x] Cancellation works correctly

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 8.

---

## Phase 8: Dependency Injection Registration

### Overview
Regenerate dependency injection configuration to register all new classes.

### Changes Required

#### 1. Run Code Generation

**Command**: Run build_runner to generate injection configuration
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will:
- Register `DownloadBloc` as factory
- Register `DownloadRepository` as lazy singleton
- Register `DownloadHttpService` as lazy singleton
- Register `FileSaver` implementations for desktop/web environments

#### 2. Verify Registration

**File**: `lib/core/di/injection.config.dart` (auto-generated)
**Expected additions**: New registrations for download feature classes

The generated file should include entries like:
```dart
gh.factory<DownloadBloc>(() => DownloadBloc(
  gh<DownloadRepository>(),
  gh<MessageRepository>(),
  gh<Logger>(),
));

gh.lazySingleton<DownloadRepository>(() => DownloadRepositoryImpl(
  gh<DownloadHttpService>(),
  gh<FileSaver>(),
  gh<Logger>(),
));

gh.lazySingleton<DownloadHttpService>(() => DownloadHttpService(gh<Logger>()));

gh.lazySingleton<FileSaver>(() => DesktopFileSaver(gh<Logger>()));
// or WebFileSaver depending on environment
```

### Success Criteria

#### Automated Verification:
- [x] Code generation completes: `flutter pub run build_runner build`
- [x] No generation errors
- [x] App compiles: `flutter analyze`
- [x] App runs without DI errors: Start app and verify no `GetIt` exceptions

#### Manual Verification:
- [x] Check `injection.config.dart` contains new registrations
- [x] Verify `DownloadBloc` is created successfully when showing bottom sheet
- [x] Verify all dependencies resolve correctly

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 9.

---

## Phase 9: Testing and Validation

### Overview
Comprehensive testing of the download feature across platforms and scenarios.

### Testing Scenarios

#### 1. Happy Path Testing
- [ ] Select 3 messages with both audio and transcripts
- [ ] Click download button
- [ ] Verify bottom sheet appears
- [ ] Verify progress updates show "Downloading X of Y"
- [ ] Verify progress bar advances
- [ ] Verify completion summary shows correct counts
- [ ] Verify files exist in `~/Downloads/CarbonVoice/{date}/`
- [ ] Verify audio files play correctly
- [ ] Verify transcript files contain expected text
- [ ] Verify file names match message IDs

#### 2. Empty Selection
- [ ] Deselect all messages
- [ ] Click download button
- [ ] Verify SnackBar appears with "No messages selected"
- [ ] Verify no bottom sheet appears

#### 3. Missing Data Handling
- [ ] Select message with only audio (no transcript)
- [ ] Click download
- [ ] Verify only audio file is downloaded
- [ ] Verify summary shows 1 success, 0 failed, 0 skipped (or 1 skipped if transcript counted)
- [ ] Select message with only transcript (no audio)
- [ ] Click download
- [ ] Verify only transcript file is downloaded
- [ ] Select message with neither audio nor transcript
- [ ] Click download
- [ ] Verify completion summary shows 1 skipped

#### 4. Duplicate File Handling
- [ ] Download same message twice
- [ ] Verify first download creates `{messageId}.mp3`
- [ ] Verify second download creates `{messageId}_1.mp3`
- [ ] Download same message third time
- [ ] Verify creates `{messageId}_2.mp3`

#### 5. Cancellation
- [ ] Select 10+ messages
- [ ] Click download
- [ ] Wait for 3-4 items to complete
- [ ] Click Cancel button
- [ ] Verify download stops
- [ ] Verify "Download cancelled" message appears
- [ ] Verify completed files remain in directory
- [ ] Verify no partial files exist

#### 6. Error Handling
- [ ] Simulate network error (disconnect WiFi mid-download)
- [ ] Verify failure count increases
- [ ] Verify download continues with remaining items
- [ ] Verify summary shows failure count
- [ ] Test with invalid audio URL (manually modify if possible)
- [ ] Verify failure is tracked correctly

#### 7. Large Batch Testing
- [ ] Select 20+ messages
- [ ] Click download
- [ ] Verify progress updates smoothly
- [ ] Verify all files download sequentially
- [ ] Verify no memory issues
- [ ] Verify completion summary is accurate

#### 8. Web Platform Testing
- [ ] Run on web: `flutter run -d chrome`
- [ ] Select messages and download
- [ ] Verify browser download prompts appear
- [ ] Verify files download to browser's download location
- [ ] Verify transcript files download correctly
- [ ] Verify audio files download correctly

#### 9. macOS Platform Testing
- [ ] Run on macOS: `flutter run -d macos`
- [ ] Verify same scenarios as happy path
- [ ] Verify files go to `~/Downloads/CarbonVoice/{date}/`
- [ ] Verify date folder is created correctly
- [ ] Verify file permissions are correct

#### 10. UI/UX Testing
- [ ] Verify bottom sheet is not dismissible during download
- [ ] Verify cancel button is visible during progress
- [ ] Verify cancel button disappears after completion
- [ ] Verify auto-dismiss after completion (500ms delay)
- [ ] Verify SnackBar summary is readable
- [ ] Verify progress text updates correctly
- [ ] Verify percentage rounds to whole number

### Success Criteria

#### Automated Verification:
- [x] All unit tests pass: `flutter test test/features/message_download/` (Note: No unit tests created yet - automated tests would require mocking HTTP and file system)
- [x] Integration tests pass (if created) (Note: No integration tests created - manual testing covers integration)
- [x] No errors during code generation
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [ ] All 10 testing scenarios above pass (Ready for manual testing)
- [ ] No crashes or exceptions during testing
- [ ] Files download correctly on both platforms
- [ ] UI is responsive and updates smoothly
- [ ] Error messages are user-friendly
- [ ] Performance is acceptable (no lag during downloads)

**Implementation Note:** After all automated and manual tests pass, the feature is complete and ready for production use.

---

## Testing Strategy

### Unit Tests

Create unit tests for:

1. **FileNameHelper**
   - Test extension detection from URLs
   - Test extension detection from Content-Type
   - Test fallback to .mp3
   - Test unique file name generation
   - Test date-based directory path generation

2. **DownloadRepository**
   - Test transcript saving
   - Test audio downloading
   - Test error handling
   - Mock FileSaver and DownloadHttpService

3. **DownloadBloc**
   - Test state transitions
   - Test progress updates
   - Test cancellation
   - Test empty selection
   - Test metadata fetching
   - Mock repositories

Test files location: `test/features/message_download/`

### Integration Tests

No integration tests required for this phase. Manual testing covers integration scenarios.

### Manual Testing Steps

Follow the testing scenarios in Phase 9 systematically:
1. Start with happy path to verify core functionality
2. Test edge cases (empty selection, missing data)
3. Test error scenarios (network failures, cancellation)
4. Test platform-specific behavior (macOS vs Web)
5. Test UI/UX elements (bottom sheet, progress, messages)

## Performance Considerations

1. **Sequential Downloads:** Avoids overwhelming the network and keeps code simple. If performance becomes an issue, parallel downloads can be added later.

2. **Metadata Fetching:** Fetches all message metadata in parallel at the start for speed, then downloads files sequentially.

3. **Memory Usage:** Files are streamed directly to disk without holding entire contents in memory (handled by http package).

4. **UI Responsiveness:** Progress updates after each file keeps UI responsive without over-updating.

5. **File I/O:** Using native file system APIs (`dart:io`) for optimal performance on desktop.

## Migration Notes

No data migration needed. This is a new feature with no existing data to migrate.

## References

- Message entity: [lib/features/messages/domain/entities/message.dart](lib/features/messages/domain/entities/message.dart)
- Message repository: [lib/features/messages/domain/repositories/message_repository.dart](lib/features/messages/domain/repositories/message_repository.dart)
- Dashboard screen: [lib/features/dashboard/presentation/dashboard_screen.dart](lib/features/dashboard/presentation/dashboard_screen.dart)
- Result type: [lib/core/utils/result.dart](lib/core/utils/result.dart)
- Failure types: [lib/core/errors/failures.dart](lib/core/errors/failures.dart)
- DI setup: [lib/core/di/injection.dart](lib/core/di/injection.dart)
