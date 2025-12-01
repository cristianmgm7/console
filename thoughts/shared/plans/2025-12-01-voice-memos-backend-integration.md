# Voice Memos Backend Integration Implementation Plan

## Overview

Implement complete backend integration for the Voice Memos feature following clean architecture principles. This includes creating the data layer (DTO, data source, repository), domain layer (entity, repository interface), and presentation layer (BLoC, UI model, updated widgets) to fetch and display voice memos from the `/v4/messages/voicememo` API endpoint.

## Current State Analysis

**What Exists:**
- Voice Memos screen with static dummy data ([voice_memos_screen.dart:23-208](lib/features/voice_memos/presentation/voice_memos_screen.dart#L23-L208))
- Custom table header and MessageCard widgets (deprecated pattern)
- Selection functionality (local state only)
- UI-only implementation (no data/domain layers)

**What's Missing:**
- Complete clean architecture layers (domain, data)
- API integration with voice memos endpoint
- BLoC for state management
- DTO and entity models specific to voice memos
- Repository pattern implementation
- AppTable integration (currently using deprecated custom table)

**Key Discoveries:**
- API endpoint: `GET /v4/messages/voicememo`
- Response structure is similar to messages but with voice memo-specific fields
- Voice memos are user-specific (no user enrichment needed)
- Should use existing `AppTable` component ([app_table.dart:26-237](lib/core/widgets/data/app_table.dart#L26-L237))
- Follow Messages feature pattern ([messages/data/repositories/message_repository_impl.dart](lib/features/messages/data/repositories/message_repository_impl.dart))

## Desired End State

A fully functional Voice Memos feature that:
- Fetches voice memos from the backend API
- Displays them in a table using `AppTable` component
- Supports selection and bulk actions
- Handles loading, error, and empty states
- Follows clean architecture principles
- Supports pagination and filtering (workspace, folder)
- Caches data for performance

### Verification:
- Voice memos load from API when screen is opened
- Table displays with proper columns and data
- Selection works for individual and bulk actions
- Loading states show during API calls
- Error states show with retry capability
- Empty state shows when no voice memos exist
- Code follows clean architecture pattern used in Messages feature

## What We're NOT Doing

- User enrichment (voice memos belong to the user, no creator info needed)
- Audio playback (will be added in future phase)
- Editing/deleting voice memos (API actions not in scope)
- Filtering UI controls (will use default parameters for now)
- Pagination UI (will fetch all with default limit)
- Use cases layer (direct repository access from BLoC is sufficient for simple fetch)

## Implementation Approach

Follow the exact pattern used in the Messages feature:

1. **Domain Layer**: Define VoiceMemo entity and repository interface
2. **Data Layer**: Create DTO, mapper, data source, and repository implementation
3. **Presentation Layer**: Create BLoC, UI model, mapper, and update widgets
4. **DI Registration**: Register all new classes with Injectable
5. **UI Update**: Replace custom table with AppTable component

This ensures consistency with the existing codebase architecture.

### Code Reuse Strategy

To avoid duplication, we'll reuse existing components from the Messages feature:
- **Domain Entities**: `AudioModel`, `TextModel`, `Timecode` from [messages/domain/entities/](lib/features/messages/domain/entities/)
- **DTOs**: `AudioModelDto`, `TextModelDto`, `TimecodeDto` from [messages/data/models/api/](lib/features/messages/data/models/api/)
- **Mappers**: `AudioModelDtoMapper`, `TextModelDtoMapper`, `TimecodeDtoMapper` from [message_dto_mapper.dart](lib/features/messages/data/mappers/message_dto_mapper.dart)

This reduces code duplication and ensures consistency across the codebase.

---

## Phase 1: Domain Layer - Entities and Repository Interface

### Overview
Create the pure business logic layer with domain entities and repository contracts.

### Changes Required:

#### 1. Create Voice Memo Entity
**File**: `lib/features/voice_memos/domain/entities/voice_memo.dart`
**Changes**: Create new file with VoiceMemo entity (reuses existing AudioModel and TextModel)

```dart
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for Voice Memo
class VoiceMemo extends Equatable {
  const VoiceMemo({
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
    required this.isTextMessage,
    required this.notes,
    this.deletedAt,
    this.lastUpdatedAt,
    this.parentMessageId,
    this.heardMs,
    this.name,
    this.folderId,
    this.lastHeardAt,
    this.totalHeardMs,
  });

  final String id;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime? lastUpdatedAt;
  final List<String> workspaceIds;
  final List<String> channelIds;
  final String? parentMessageId;
  final int? heardMs;
  final String notes;
  final String? name;
  final bool isTextMessage;
  final String status;
  final String type;
  final List<AudioModel> audioModels; // Reuses existing AudioModel from messages
  final List<TextModel> textModels; // Reuses existing TextModel from messages
  final String? folderId;
  final DateTime? lastHeardAt;
  final int? totalHeardMs;
  final Duration duration;

  @override
  List<Object?> get props => [
        id,
        creatorId,
        createdAt,
        deletedAt,
        lastUpdatedAt,
        workspaceIds,
        channelIds,
        parentMessageId,
        heardMs,
        notes,
        name,
        isTextMessage,
        status,
        type,
        audioModels,
        textModels,
        folderId,
        lastHeardAt,
        totalHeardMs,
        duration,
      ];
}
```

**Note**: We're reusing the existing `AudioModel` and `TextModel` from the messages feature to avoid duplication.

#### 2. Create Repository Interface
**File**: `lib/features/voice_memos/domain/repositories/voice_memo_repository.dart`
**Changes**: Create new file with repository interface

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';

/// Repository interface for voice memo operations
abstract class VoiceMemoRepository {
  /// Fetches voice memos from the API
  ///
  /// Parameters:
  /// - [workspaceId]: Optional workspace filter
  /// - [folderId]: Optional folder filter
  /// - [limit]: Number of voice memos to fetch (default: 200)
  /// - [date]: Reference date for pagination
  /// - [direction]: Pagination direction ('older' or 'newer')
  /// - [sortDirection]: Sort order ('ASC' or 'DESC')
  /// - [includeDeleted]: Whether to include deleted memos (default: true)
  Future<Result<List<VoiceMemo>>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  });

  /// Clears the voice memo cache
  void clearCache();
}
```

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/domain/ --set-exit-if-changed`

#### Manual Verification:
- [x] Entity structure matches API response fields
- [x] Repository interface follows existing patterns (like MessageRepository)
- [x] Entity uses Equatable for value equality
- [x] Computed properties (like `duration`) are implemented correctly

---

## Phase 2: Data Layer - DTOs, Mappers, and Data Source

### Overview
Create the data layer with API response DTOs, JSON mappers, and remote data source.

### Changes Required:

#### 1. Create Voice Memo DTO
**File**: `lib/features/voice_memos/data/models/voice_memo_dto.dart`
**Changes**: Create new file with JSON-serializable DTO (reuses existing AudioModelDto and TextModelDto)

```dart
import 'package:carbon_voice_console/features/messages/data/models/api/audio_model_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/text_model_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_memo_dto.g.dart';

/// DTO that mirrors the exact JSON structure from the voice memo API
@JsonSerializable()
class VoiceMemoDto {
  const VoiceMemoDto({
    this.messageId,
    this.creatorId,
    this.createdAt,
    this.deletedAt,
    this.lastUpdatedAt,
    this.workspaceIds,
    this.channelIds,
    this.parentMessageId,
    this.heardMs,
    this.notes,
    this.name,
    this.isTextMessage,
    this.status,
    this.type,
    this.audioModels,
    this.textModels,
    this.folderId,
    this.lastHeardAt,
    this.totalHeardMs,
    this.durationMs,
  });

  factory VoiceMemoDto.fromJson(Map<String, dynamic> json) =>
      _$VoiceMemoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMemoDtoToJson(this);

  @JsonKey(name: 'message_id')
  final String? messageId;

  @JsonKey(name: 'creator_id')
  final String? creatorId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  @JsonKey(name: 'last_updated_at')
  final String? lastUpdatedAt;

  @JsonKey(name: 'workspace_ids')
  final List<String>? workspaceIds;

  @JsonKey(name: 'channel_ids')
  final List<String>? channelIds;

  @JsonKey(name: 'parent_message_id')
  final String? parentMessageId;

  @JsonKey(name: 'heard_ms')
  final int? heardMs;

  final String? notes;
  final String? name;

  @JsonKey(name: 'is_text_message')
  final bool? isTextMessage;

  final String? status;
  final String? type;

  @JsonKey(name: 'audio_models')
  final List<AudioModelDto>? audioModels; // Reuses existing AudioModelDto from messages

  @JsonKey(name: 'text_models')
  final List<TextModelDto>? textModels; // Reuses existing TextModelDto from messages

  @JsonKey(name: 'folder_id')
  final String? folderId;

  @JsonKey(name: 'last_heard_at')
  final String? lastHeardAt;

  @JsonKey(name: 'total_heard_ms')
  final int? totalHeardMs;

  @JsonKey(name: 'duration_ms')
  final int? durationMs;
}
```

**Note**: We're reusing the existing `AudioModelDto` and `TextModelDto` from the messages feature to avoid duplication.

#### 2. Create DTO Mapper
**File**: `lib/features/voice_memos/data/mappers/voice_memo_dto_mapper.dart`
**Changes**: Create new file with mapper extension (reuses existing DTO mappers)

```dart
import 'package:carbon_voice_console/features/messages/data/mappers/message_dto_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/audio_model.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/text_model.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';

/// Extension methods to convert DTOs to domain entities
extension VoiceMemoDtoMapper on VoiceMemoDto {
  VoiceMemo toDomain() {
    if (messageId == null || creatorId == null || createdAt == null) {
      throw FormatException(
        'Required voice memo fields are missing: id=${messageId == null}, '
        'creator=${creatorId == null}, created=${createdAt == null}',
      );
    }

    return VoiceMemo(
      id: messageId!,
      creatorId: creatorId!,
      createdAt: DateTime.parse(createdAt!),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
      lastUpdatedAt: lastUpdatedAt != null ? DateTime.parse(lastUpdatedAt!) : null,
      workspaceIds: workspaceIds ?? [],
      channelIds: channelIds ?? [],
      parentMessageId: parentMessageId,
      heardMs: heardMs,
      notes: notes ?? '',
      name: name,
      isTextMessage: isTextMessage ?? false,
      status: status ?? 'unknown',
      type: type ?? 'voicememo',
      // Reuses existing mappers from messages feature (AudioModelDtoMapper, TextModelDtoMapper)
      audioModels: audioModels?.map((dto) {
        try {
          return dto.toDomain(); // Uses AudioModelDtoMapper from message_dto_mapper.dart
        } catch (e) {
          return null; // Skip invalid audio models
        }
      }).whereType<AudioModel>().toList() ?? [],
      textModels: textModels?.map((dto) {
        try {
          return dto.toDomain(); // Uses TextModelDtoMapper from message_dto_mapper.dart
        } catch (e) {
          return null; // Skip invalid text models
        }
      }).whereType<TextModel>().toList() ?? [],
      folderId: folderId,
      lastHeardAt: lastHeardAt != null ? DateTime.parse(lastHeardAt!) : null,
      totalHeardMs: totalHeardMs,
      duration: Duration(milliseconds: durationMs ?? 0),
    );
  }
}
```

**Note**: We're reusing the existing `AudioModelDtoMapper` and `TextModelDtoMapper` from [message_dto_mapper.dart:50-87](lib/features/messages/data/mappers/message_dto_mapper.dart#L50-L87).

#### 3. Create Remote Data Source Interface
**File**: `lib/features/voice_memos/data/datasources/voice_memo_remote_datasource.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';

/// Abstract interface for voice memo remote data operations
abstract class VoiceMemoRemoteDataSource {
  /// Fetches voice memos from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<VoiceMemoDto>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  });
}
```

#### 4. Create Remote Data Source Implementation
**File**: `lib/features/voice_memos/data/datasources/voice_memo_remote_datasource_impl.dart`
**Changes**: Create new file with Dio-based implementation

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/voice_memos/data/datasources/voice_memo_remote_datasource.dart';
import 'package:carbon_voice_console/features/voice_memos/data/models/voice_memo_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: VoiceMemoRemoteDataSource)
class VoiceMemoRemoteDataSourceImpl implements VoiceMemoRemoteDataSource {
  VoiceMemoRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<VoiceMemoDto>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'limit': limit,
        'direction': direction,
        'sort_direction': sortDirection,
        'include_deleted': includeDeleted,
      };

      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (folderId != null) queryParams['folder_id'] = folderId;
      if (date != null) queryParams['date'] = date.toIso8601String();

      // Build URL with query params
      final uri = Uri.parse('${OAuthConfig.apiBaseUrl}/v4/messages/voicememo')
          .replace(queryParameters: queryParams);

      _logger.d('Fetching voice memos from: $uri');

      final response = await _httpService.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API returns array of voice memos
        if (data is! List) {
          throw FormatException(
            'Expected List but got ${data.runtimeType} for voice memos endpoint',
          );
        }

        final voiceMemosJson = data;

        // Convert each voice memo JSON to DTO with error handling
        try {
          final voiceMemos = voiceMemosJson
              .map((json) => VoiceMemoDto.fromJson(json as Map<String, dynamic>))
              .toList();

          _logger.d('Fetched ${voiceMemos.length} voice memos');
          return voiceMemos;
        } on Exception catch (e, stack) {
          _logger.e('Failed to parse voice memos: $e', error: e, stackTrace: stack);
          throw ServerException(
            statusCode: 422,
            message: 'Failed to parse voice memos: $e',
          );
        }
      } else {
        _logger.e('Failed to fetch voice memos: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch voice memos',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching voice memos', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch voice memos: $e');
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] Generated files created: `voice_memo_dto.g.dart`
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/data/`

#### Manual Verification:
- [x] DTO fields match API response structure exactly
- [x] Mapper handles null values properly
- [x] Data source constructs query parameters correctly
- [x] Error handling follows repository pattern (ServerException, NetworkException)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the code generation was successful before proceeding to the next phase.

---

## Phase 3: Data Layer - Repository Implementation

### Overview
Implement the repository with caching and error handling.

### Changes Required:

#### 1. Create Repository Implementation
**File**: `lib/features/voice_memos/data/repositories/voice_memo_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/voice_memos/data/datasources/voice_memo_remote_datasource.dart';
import 'package:carbon_voice_console/features/voice_memos/data/mappers/voice_memo_dto_mapper.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/repositories/voice_memo_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: VoiceMemoRepository)
class VoiceMemoRepositoryImpl implements VoiceMemoRepository {
  VoiceMemoRepositoryImpl(this._remoteDataSource, this._logger);

  final VoiceMemoRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: workspace_folder key -> voice memos (sorted)
  final Map<String, List<VoiceMemo>> _cachedVoiceMemos = {};

  String _buildCacheKey({String? workspaceId, String? folderId}) {
    return '${workspaceId ?? 'all'}_${folderId ?? 'all'}';
  }

  @override
  Future<Result<List<VoiceMemo>>> getVoiceMemos({
    String? workspaceId,
    String? folderId,
    int limit = 200,
    DateTime? date,
    String direction = 'older',
    String sortDirection = 'DESC',
    bool includeDeleted = true,
  }) async {
    try {
      final cacheKey = _buildCacheKey(workspaceId: workspaceId, folderId: folderId);

      // Return cached voice memos if available
      if (_cachedVoiceMemos.containsKey(cacheKey)) {
        _logger.d('Returning cached voice memos for key: $cacheKey');
        return success(_cachedVoiceMemos[cacheKey]!);
      }

      final voiceMemoDtos = await _remoteDataSource.getVoiceMemos(
        workspaceId: workspaceId,
        folderId: folderId,
        limit: limit,
        date: date,
        direction: direction,
        sortDirection: sortDirection,
        includeDeleted: includeDeleted,
      );

      final voiceMemos = voiceMemoDtos.map((dto) => dto.toDomain()).toList();

      // Sort by date (newest first) if DESC, oldest first if ASC
      if (sortDirection == 'DESC') {
        voiceMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        voiceMemos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      // Cache the result
      _cachedVoiceMemos[cacheKey] = voiceMemos;

      _logger.d('Fetched and cached ${voiceMemos.length} voice memos');
      return success(voiceMemos);
    } on ServerException catch (e) {
      _logger.e('Server error fetching voice memos', error: e);
      return failure(
        ServerFailure(statusCode: e.statusCode, details: e.message),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error fetching voice memos', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching voice memos', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  void clearCache() {
    _cachedVoiceMemos.clear();
    _logger.d('Voice memo cache cleared');
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/data/repositories/`

#### Manual Verification:
- [x] Repository implements interface correctly
- [x] Caching logic uses workspace/folder as composite key
- [x] Error handling covers all exception types
- [x] Logging provides useful debugging information

---

## Phase 4: Presentation Layer - BLoC (Events, States, BLoC)

### Overview
Create BLoC for state management following the pattern used in other features.

### Changes Required:

#### 1. Create BLoC Events
**File**: `lib/features/voice_memos/presentation/bloc/voice_memo_event.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

sealed class VoiceMemoEvent extends Equatable {
  const VoiceMemoEvent();

  @override
  List<Object?> get props => [];
}

/// Load voice memos from repository
class LoadVoiceMemos extends VoiceMemoEvent {
  const LoadVoiceMemos({
    this.workspaceId,
    this.folderId,
    this.forceRefresh = false,
  });

  final String? workspaceId;
  final String? folderId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [workspaceId, folderId, forceRefresh];
}
```

#### 2. Create BLoC States
**File**: `lib/features/voice_memos/presentation/bloc/voice_memo_state.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';
import 'package:equatable/equatable.dart';

sealed class VoiceMemoState extends Equatable {
  const VoiceMemoState();

  @override
  List<Object?> get props => [];
}

class VoiceMemoInitial extends VoiceMemoState {
  const VoiceMemoInitial();
}

class VoiceMemoLoading extends VoiceMemoState {
  const VoiceMemoLoading();
}

class VoiceMemoLoaded extends VoiceMemoState {
  const VoiceMemoLoaded(this.voiceMemos);

  final List<VoiceMemoUiModel> voiceMemos;

  @override
  List<Object?> get props => [voiceMemos];
}

class VoiceMemoError extends VoiceMemoState {
  const VoiceMemoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

#### 3. Create BLoC Implementation
**File**: `lib/features/voice_memos/presentation/bloc/voice_memo_bloc.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/voice_memos/domain/repositories/voice_memo_repository.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_event.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_state.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/mappers/voice_memo_ui_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class VoiceMemoBloc extends Bloc<VoiceMemoEvent, VoiceMemoState> {
  VoiceMemoBloc(
    this._voiceMemoRepository,
    this._logger,
  ) : super(const VoiceMemoInitial()) {
    on<LoadVoiceMemos>(_onLoadVoiceMemos);
  }

  final VoiceMemoRepository _voiceMemoRepository;
  final Logger _logger;

  Future<void> _onLoadVoiceMemos(
    LoadVoiceMemos event,
    Emitter<VoiceMemoState> emit,
  ) async {
    _logger.d(
      'Loading voice memos (workspace: ${event.workspaceId}, folder: ${event.folderId})',
    );

    emit(const VoiceMemoLoading());

    // Clear cache if force refresh
    if (event.forceRefresh) {
      _voiceMemoRepository.clearCache();
    }

    final result = await _voiceMemoRepository.getVoiceMemos(
      workspaceId: event.workspaceId,
      folderId: event.folderId,
    );

    result.fold(
      onSuccess: (voiceMemos) {
        _logger.d('Loaded ${voiceMemos.length} voice memos');

        // Convert domain entities to UI models
        final uiModels = voiceMemos.map((vm) => vm.toUiModel()).toList();

        emit(VoiceMemoLoaded(uiModels));
      },
      onFailure: (failure) {
        final errorMessage = FailureMapper.mapToMessage(failure.failure);
        _logger.e('Failed to load voice memos: $errorMessage');
        emit(VoiceMemoError(errorMessage));
      },
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/presentation/bloc/`

#### Manual Verification:
- [x] BLoC follows pattern from other features (MessageBloc, WorkspaceBloc)
- [x] Events are properly handled with async operations
- [x] States cover all scenarios (initial, loading, loaded, error)
- [x] Error messages use FailureMapper

---

## Phase 5: Presentation Layer - UI Model and Mapper

### Overview
Create presentation-layer UI model with computed properties and mapper from domain entity.

### Changes Required:

#### 1. Create UI Model
**File**: `lib/features/voice_memos/presentation/models/voice_memo_ui_model.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';
import 'package:equatable/equatable.dart';

/// UI model for voice memo presentation
/// Contains computed properties optimized for UI rendering
class VoiceMemoUiModel extends Equatable {
  const VoiceMemoUiModel({
    required this.id,
    required this.creatorId,
    required this.createdAt,
    required this.duration,
    required this.notes,
    required this.status,
    required this.type,
    required this.audioModels,
    required this.textModels,
    this.deletedAt,
    this.name,
    this.folderId,
    this.summary,
    this.transcript,
    this.audioUrl,
  });

  final String id;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final Duration duration;
  final String notes;
  final String? name;
  final String status;
  final String type;
  final List<AudioModel> audioModels;
  final List<TextModel> textModels;
  final String? folderId;

  // Computed UI properties
  final String? summary;
  final String? transcript;
  final String? audioUrl;

  // Computed getters
  bool get hasPlayableAudio => audioModels.any((audio) => audio.extension == 'mp3');

  AudioModel? get playableAudioModel {
    if (audioModels.isEmpty) return null;
    try {
      return audioModels.firstWhere(
        (audio) => audio.extension == 'mp3',
      );
    } catch (e) {
      return audioModels.first;
    }
  }

  String get displayText => summary ?? transcript ?? notes;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        creatorId,
        createdAt,
        deletedAt,
        duration,
        notes,
        name,
        status,
        type,
        audioModels,
        textModels,
        folderId,
        summary,
        transcript,
        audioUrl,
      ];
}
```

#### 2. Create UI Mapper
**File**: `lib/features/voice_memos/presentation/mappers/voice_memo_ui_mapper.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/voice_memos/domain/entities/voice_memo.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';

/// Extension methods to convert domain entities to UI models
extension VoiceMemoUiMapper on VoiceMemo {
  /// Gets the URL of the MP3 audio if available
  static String? _getPlayableAudioUrl(List<AudioModel> audioModels) {
    if (audioModels.isEmpty) return null;

    try {
      final mp3Audio = audioModels.firstWhere(
        (audio) => audio.extension == 'mp3',
      );
      return mp3Audio.url;
    } catch (e) {
      return audioModels.first.url;
    }
  }

  /// Gets the summary text if available
  static String? _getSummary(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    try {
      final summary = textModels.firstWhere(
        (model) => model.type.toLowerCase() == 'summary',
      );
      return summary.value.isNotEmpty ? summary.value : null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the transcript text if available
  static String? _getTranscript(List<TextModel> textModels) {
    if (textModels.isEmpty) return null;

    try {
      final transcript = textModels.firstWhere(
        (model) => model.type.toLowerCase() == 'transcript',
      );
      return transcript.value.isNotEmpty ? transcript.value : null;
    } catch (e) {
      return textModels.first.value.isNotEmpty ? textModels.first.value : null;
    }
  }

  /// Converts domain entity to UI model
  VoiceMemoUiModel toUiModel() {
    return VoiceMemoUiModel(
      id: id,
      creatorId: creatorId,
      createdAt: createdAt,
      deletedAt: deletedAt,
      duration: duration,
      notes: notes,
      name: name,
      status: status,
      type: type,
      audioModels: audioModels,
      textModels: textModels,
      folderId: folderId,
      summary: _getSummary(textModels),
      transcript: _getTranscript(textModels),
      audioUrl: _getPlayableAudioUrl(audioModels),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/presentation/`

#### Manual Verification:
- [x] UI model has computed properties for common UI needs
- [x] Mapper prioritizes summary over transcript
- [x] Audio URL extraction handles MP3 format preference
- [x] Model extends Equatable for proper value equality

---

## Phase 6: Dependency Injection Registration

### Overview
Register all new classes with Injectable for dependency injection.

### Changes Required:

#### 1. Run Code Generation
**Command**: Run build_runner to generate DI code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will:
- Generate `voice_memo_dto.g.dart` from `@JsonSerializable` annotations
- Update `injection.config.dart` with new `@injectable` and `@LazySingleton` registrations

### Success Criteria:

#### Automated Verification:
- [x] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] Generated files created: `voice_memo_dto.g.dart`, updated `injection.config.dart`
- [x] No build errors: `flutter analyze`
- [x] App builds successfully: `flutter build web` (or target platform)

#### Manual Verification:
- [ ] All new classes registered in DI container
- [ ] VoiceMemoBloc can be resolved: `getIt<VoiceMemoBloc>()`
- [ ] VoiceMemoRepository can be resolved: `getIt<VoiceMemoRepository>()`
- [ ] VoiceMemoRemoteDataSource can be resolved

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that dependency injection is working before proceeding to the next phase.

---

## Phase 7: Update BLoC Providers

### Overview
Add VoiceMemoBloc to the app's BLoC provider list.

### Changes Required:

#### 1. Update BLoC Providers
**File**: `lib/core/providers/bloc_providers.dart`
**Changes**: Add VoiceMemoBloc provider

```dart
// Add import
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_bloc.dart';

// In getBlocProviders() method, add:
BlocProvider<VoiceMemoBloc>(
  create: (context) => getIt<VoiceMemoBloc>(),
),
```

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] App builds successfully: `flutter run -d chrome`

#### Manual Verification:
- [ ] VoiceMemoBloc is accessible via `context.read<VoiceMemoBloc>()`
- [ ] No runtime errors when accessing the BLoC

---

## Phase 8: Update Voice Memos Screen with AppTable

### Overview
Replace the custom table implementation with `AppTable` component and integrate BLoC.

### Changes Required:

#### 1. Update Voice Memos Screen
**File**: `lib/features/voice_memos/presentation/voice_memos_screen.dart`
**Changes**: Complete rewrite to use AppTable and BLoC

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_bloc.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_event.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_state.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceMemosScreen extends StatefulWidget {
  const VoiceMemosScreen({super.key});

  @override
  State<VoiceMemosScreen> createState() => _VoiceMemosScreenState();
}

class _VoiceMemosScreenState extends State<VoiceMemosScreen> {
  final Set<String> _selectedVoiceMemos = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Load voice memos when screen initializes
    context.read<VoiceMemoBloc>().add(const LoadVoiceMemos());
  }

  void _toggleSelectAll(bool? value, int totalCount) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Get all voice memo IDs from current state
        final state = context.read<VoiceMemoBloc>().state;
        if (state is VoiceMemoLoaded) {
          _selectedVoiceMemos.addAll(state.voiceMemos.map((vm) => vm.id));
        }
      } else {
        _selectedVoiceMemos.clear();
      }
    });
  }

  void _toggleVoiceMemoSelection(String voiceMemoId, bool? value, int totalCount) {
    setState(() {
      if (value ?? false) {
        _selectedVoiceMemos.add(voiceMemoId);
      } else {
        _selectedVoiceMemos.remove(voiceMemoId);
      }
      _selectAll = _selectedVoiceMemos.length == totalCount;
    });
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      backgroundColor: AppColors.surface,
      child: Stack(
        children: [
          BlocBuilder<VoiceMemoBloc, VoiceMemoState>(
            builder: (context, state) {
              return _buildContent(context, state);
            },
          ),

          // Floating Action Panel
          if (_selectedVoiceMemos.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: MessagesActionPanel(
                  selectedCount: _selectedVoiceMemos.length,
                  onDownloadAudio: () {
                    // TODO: Implement download audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Downloading audio for ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
                  },
                  onDownloadTranscript: () {
                    // TODO: Implement download transcript
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Downloading transcripts for ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
                  },
                  onSummarize: () {
                    // TODO: Implement summarize
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Summarizing ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
                  },
                  onAIChat: () {
                    // TODO: Implement AI chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Opening AI chat for ${_selectedVoiceMemos.length} voice memos...',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, VoiceMemoState state) {
    // Loading state
    if (state is VoiceMemoLoading) {
      return const Center(child: AppProgressIndicator());
    }

    // Error state
    if (state is VoiceMemoError) {
      return AppEmptyState.error(
        message: state.message,
        onRetry: () {
          context.read<VoiceMemoBloc>().add(const LoadVoiceMemos(forceRefresh: true));
        },
      );
    }

    // Loaded state
    if (state is VoiceMemoLoaded) {
      if (state.voiceMemos.isEmpty) {
        return AppEmptyState.noMessages(
          onRetry: () {
            context.read<VoiceMemoBloc>().add(const LoadVoiceMemos(forceRefresh: true));
          },
        );
      }

      return AppTable(
        selectAll: _selectAll,
        onSelectAllChanged: (value) =>
            _toggleSelectAll(value, state.voiceMemos.length),
        columns: const [
          AppTableColumn(
            title: 'Date',
            width: FixedColumnWidth(120),
          ),
          AppTableColumn(
            title: 'Duration',
            width: FixedColumnWidth(80),
          ),
          AppTableColumn(
            title: 'Name',
            width: FixedColumnWidth(150),
          ),
          AppTableColumn(
            title: 'Summary',
            width: FlexColumnWidth(),
          ),
          AppTableColumn(
            title: 'Status',
            width: FixedColumnWidth(100),
          ),
          AppTableColumn(
            title: 'Actions',
            width: FixedColumnWidth(120),
          ),
        ],
        rows: state.voiceMemos.map((voiceMemo) {
          return AppTableRow(
            selected: _selectedVoiceMemos.contains(voiceMemo.id),
            onSelectChanged: (selected) => _toggleVoiceMemoSelection(
              voiceMemo.id,
              selected,
              state.voiceMemos.length,
            ),
            cells: [
              // Date
              Text(
                _formatDate(voiceMemo.createdAt),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Duration
              Text(
                _formatDuration(voiceMemo.duration),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Name
              Text(
                voiceMemo.name ?? 'Untitled',
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Summary
              Text(
                voiceMemo.displayText,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Status
              Text(
                voiceMemo.status,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (voiceMemo.hasPlayableAudio)
                    AppIconButton(
                      icon: AppIcons.play,
                      tooltip: 'Play audio',
                      onPressed: () {
                        // TODO: Implement audio playback
                      },
                      size: AppIconButtonSize.small,
                    ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () {
                      // TODO: Implement download
                    },
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      );
    }

    // Initial state
    return AppEmptyState.loading();
  }
}
```

#### 2. Delete Deprecated Files
**Files to delete**:
- `lib/features/voice_memos/presentation/message_card.dart` (no longer needed)

### Success Criteria:

#### Automated Verification:
- [x] Files compile without errors: `flutter analyze`
- [x] No linting errors: `dart format lib/features/voice_memos/presentation/`
- [x] App builds successfully: `flutter run -d chrome`

#### Manual Verification:
- [ ] Voice Memos screen displays AppTable with proper columns
- [ ] Loading state shows spinner
- [ ] Error state shows error message with retry button
- [ ] Empty state shows "no messages" placeholder
- [ ] Selection checkboxes work for individual voice memos
- [ ] Select all checkbox works
- [ ] Action panel appears when voice memos are selected
- [ ] Date and duration formatting is correct
- [ ] Table is scrollable and responsive

---

## Testing Strategy

### Unit Tests:
- **Mapper Tests**: Verify DTO to Entity mapping handles all fields correctly
- **UI Mapper Tests**: Verify Entity to UI Model mapping with computed properties
- **Repository Tests**: Verify caching, error handling, and data transformation
- **BLoC Tests**: Verify state transitions for LoadVoiceMemos event

### Integration Tests:
- **API Integration**: Verify data source can parse real API responses
- **End-to-End BLoC Flow**: Verify complete flow from event → repository → state

### Manual Testing Steps:
1. Open Voice Memos screen
2. Verify voice memos load from API
3. Test selection (individual and select all)
4. Verify action panel appears with selection
5. Test error scenario (disconnect network, verify error state)
6. Test empty scenario (no voice memos, verify empty state)
7. Verify table scrolling and layout
8. Verify date/duration formatting
9. Test retry button on error state

## Performance Considerations

- **Caching**: In-memory cache reduces redundant API calls
- **Lazy Loading**: Voice memos loaded only when screen is opened
- **Pagination**: API supports pagination (limit parameter), can be enhanced later
- **UI Optimization**: AppTable uses Flutter's Table widget (efficient rendering)

## Migration Notes

**Breaking Changes:**
- Removes static dummy data
- Replaces custom table with AppTable
- Removes MessageCard widget (deprecated)

**Backward Compatibility:**
- Voice Memos route remains the same (`/dashboard/voice_memos`)
- UI structure remains similar (table with selection)
- Action panel behavior unchanged

## References

- Voice Memos API: `GET /v4/messages/voicememo`
- AppTable component: [app_table.dart:26-237](lib/core/widgets/data/app_table.dart#L26-L237)
- Messages feature (reference implementation): [messages/data/repositories/message_repository_impl.dart](lib/features/messages/data/repositories/message_repository_impl.dart)
- Repository pattern: [workspaces/data/repositories/workspace_repository_impl.dart](lib/features/workspaces/data/repositories/workspace_repository_impl.dart)
- BLoC pattern: [workspaces/presentation/bloc/workspace_bloc.dart](lib/features/workspaces/presentation/bloc/workspace_bloc.dart)
- DTO pattern: [dtos/user_profile_dto.dart](lib/dtos/user_profile_dto.dart)
- CLAUDE.md architecture guide: [CLAUDE.md](CLAUDE.md)
