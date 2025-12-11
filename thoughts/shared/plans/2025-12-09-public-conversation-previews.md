# Public Conversation Preview Feature - Implementation Plan

## Overview

This plan implements a podcast-style public preview feature for async conversations. Users can select 3-5 messages from a conversation, compose preview metadata (title, description, cover art), publish the preview to the Carbon Voice API, and receive a shareable public URL. The preview page will show conversation details, participant info, and audio previews with a call-to-action button deep-linking to the full conversation in the app.

## Current State Analysis

### What Exists Now:
- **Message Display**: Full inbox-style message list with async conversation support ([dashboard_screen.dart](lib/features/messages/presentation_messages_dashboard/screens/dashboard_screen.dart))
- **Message Selection**: `MessageSelectionCubit` manages multi-select state for bulk operations ([message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart))
- **Audio Player**: Centralized BLoC-based player with pre-signed URL fetching, waveform visualization, and preview playback capability ([audio_player_bloc.dart](lib/features/audio_player/presentation/bloc/audio_player_bloc.dart))
- **OAuth 2.0**: Authenticated HTTP service with automatic token refresh ([authenticated_http_service.dart](lib/core/network/authenticated_http_service.dart))
- **Clean Architecture**: Well-established patterns for domain/data/presentation layers with BLoC state management
- **Conversation Metadata**: Entities include title, description, imageUrl, collaborators, avatars ([conversation_entity.dart](lib/features/conversations/domain/entities/conversation_entity.dart))

### What's Missing:
- **File Upload**: No multipart/form-data or image upload patterns exist (app is read-only for media)
- **Preview Domain Model**: No entity/DTO for public previews
- **Preview API Endpoints**: No datasource or repository for preview publishing
- **Preview UI Flow**: No screens for metadata composition, confirmation, or sharing
- **Local Draft Storage**: No mechanism to cache preview selections before publishing
- **Image Selection**: No image picker dependency or UI

### Key Discoveries:
- **HTTP Service**: Only supports JSON POST/PUT with `Content-Type: application/json` ([authenticated_http_service.dart:60-68](lib/core/network/authenticated_http_service.dart#L60-L68))
- **Image Handling**: All images displayed via URL strings, no local file handling ([conversation_cover_art.dart:50-66](lib/features/conversations/presentation/widgets/conversation_cover_art.dart#L50-L66))
- **Message Selection Pattern**: `MessageSelectionCubit` provides `getSelectedMessageIds()` for bulk operations ([message_selection_cubit.dart:53-55](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart#L53-L55))
- **BLoC Communication**: Cubits trigger BLoC events directly for data operations ([message_detail_cubit.dart:16-23](lib/features/messages/presentation_messages_detail/cubit/message_detail_cubit.dart#L16-L23))
- **Routing**: `go_router` with `ShellRoute` for authenticated routes, `NoTransitionPage` for instant navigation ([app_router.dart:60-92](lib/core/routing/app_router.dart#L60-L92))
- **Audio Preview**: Can be implemented using existing audio player with duration limits ([audio_player_bloc.dart:67-77](lib/features/audio_player/presentation/bloc/audio_player_bloc.dart#L67-L77))

## Desired End State

### Specification:
1. **Message Selection Mode**: Users can select 3-5 messages from the current conversation for preview inclusion
2. **Preview Composer UI**: Modal/screen to enter title (required), short description (required, 200 char max), and optional cover image URL
3. **Publish Operation**: POST to Carbon Voice API with preview metadata and selected message IDs
4. **Confirmation Screen**: Display generated preview URL with copy and share buttons
5. **Preview Management**: Ability to view/edit/delete published previews (future phase)
6. **Local Draft**: Preview selections and metadata cached locally before publish (optional, can be volatile)

### Verification Criteria:

#### Automated Verification:
- [ ] Build compiles without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] All unit tests pass: `flutter test`
- [ ] No lint errors: `flutter analyze`
- [ ] Type checking passes: `dart analyze`
- [ ] Preview DTOs serialize/deserialize correctly (unit tests)
- [ ] Repository methods return `Result<T>` types correctly (unit tests)
- [ ] BLoC state transitions work as expected (BLoC tests)

#### Manual Verification:
- [ ] User can select exactly 3-5 messages for preview
- [ ] Attempting to select <3 or >5 messages shows validation error
- [ ] Preview composer modal appears with pre-filled conversation title
- [ ] Required fields (title, description) validated on submit
- [ ] Cover image URL field accepts valid URLs
- [ ] Publish button triggers loading state and API call
- [ ] Success confirmation screen shows shareable URL
- [ ] Copy button copies URL to clipboard
- [ ] Share button triggers native share sheet (mobile/web)
- [ ] Preview URL opens in browser and displays correctly
- [ ] Published preview shows selected messages as audio previews (not full playback)
- [ ] CTA button on preview page deep-links to app
- [ ] Error states display user-friendly messages

**Implementation Note**: After completing Phase 1 automated verification, pause for manual confirmation that the domain/data layers work correctly before proceeding to Phase 2 UI implementation.

## What We're NOT Doing

- **Image Upload from Device**: No file picker or camera integration (use URL input only)
- **Image Editing**: No cropping, resizing, or filters
- **Preview Analytics**: No view counts, listen metrics, or engagement tracking
- **Preview Templates**: No pre-made designs or themes
- **RSS Feed Generation**: No podcast feed creation
- **Automatic Artwork Generation**: No AI-generated cover images (user must provide URL or use default)
- **Collaborative Editing**: No multi-user preview editing
- **Scheduled Publishing**: Previews publish immediately
- **Preview Versioning**: No edit history or rollback
- **Audio Trimming**: Messages play as full previews, no custom clip selection
- **Custom Branding**: No white-labeling or custom domains

## Implementation Approach

### Strategy:
1. **Bottom-Up Implementation**: Start with domain layer (entities, repositories), then data layer (DTOs, datasources), then presentation layer (BLoCs, UI)
2. **Reuse Existing Patterns**: Follow established conventions from message/conversation features
3. **Incremental Testing**: Verify each layer before proceeding to next
4. **API-First Design**: Define API contract early, implement against mock data if needed
5. **State Management**: Use Cubit for local UI state (selections, form), BLoC for async operations (publish, fetch)

### Architecture:
```
lib/features/preview/
  ├── domain/
  │   ├── entities/
  │   │   ├── conversation_preview.dart          # Domain model
  │   │   └── preview_metadata.dart              # Title, description, cover
  │   ├── repositories/
  │   │   └── preview_repository.dart            # Abstract interface
  │   └── usecases/
  │       ├── publish_preview_usecase.dart       # Publish to API
  │       └── get_preview_usecase.dart           # Fetch published preview
  ├── data/
  │   ├── datasources/
  │   │   ├── preview_remote_datasource.dart     # Interface
  │   │   └── preview_remote_datasource_impl.dart # Implementation
  │   ├── models/
  │   │   ├── conversation_preview_dto.dart      # API response DTO
  │   │   └── publish_preview_request_dto.dart   # API request DTO
  │   ├── mappers/
  │   │   └── preview_dto_mapper.dart            # DTO ↔ Entity
  │   └── repositories/
  │       └── preview_repository_impl.dart       # Repository impl
  └── presentation/
      ├── bloc/
      │   ├── publish_preview_bloc.dart          # Publish operation
      │   ├── publish_preview_event.dart
      │   └── publish_preview_state.dart
      ├── cubit/
      │   ├── preview_composer_cubit.dart        # Form state
      │   └── preview_composer_state.dart
      ├── screens/
      │   ├── preview_composer_screen.dart       # Metadata entry
      │   └── preview_confirmation_screen.dart   # Success/sharing
      └── widgets/
          ├── message_selection_counter.dart     # "3/5 selected"
          ├── preview_metadata_form.dart         # Title/desc inputs
          └── preview_share_panel.dart           # URL copy/share
```

---

## Phase 1: Domain & Data Layers

### Overview
Establish domain models, repository interfaces, DTOs, and API integration. This phase has no UI - only data structures and business logic.

### Changes Required:

#### 1. Domain Entities

**File**: `lib/features/preview/domain/entities/preview_metadata.dart`
**Changes**: Create new file with metadata model

```dart
import 'package:equatable/equatable.dart';

/// Metadata for a public conversation preview
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

**File**: `lib/features/preview/domain/entities/conversation_preview.dart`
**Changes**: Create new file with preview entity

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing a published conversation preview
class ConversationPreview extends Equatable {
  const ConversationPreview({
    required this.id,
    required this.conversationId,
    required this.metadata,
    required this.messageIds,
    required this.publicUrl,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final PreviewMetadata metadata;
  final List<String> messageIds;
  final String publicUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        metadata,
        messageIds,
        publicUrl,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
```

#### 2. Repository Interface

**File**: `lib/features/preview/domain/repositories/preview_repository.dart`
**Changes**: Create new file with repository contract

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';

/// Repository for managing conversation previews
abstract class PreviewRepository {
  /// Publishes a new conversation preview
  Future<Result<ConversationPreview>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  });

  /// Fetches a published preview by ID
  Future<Result<ConversationPreview>> getPreview(String previewId);

  /// Fetches all previews for a conversation
  Future<Result<List<ConversationPreview>>> getPreviewsForConversation(
    String conversationId,
  );

  /// Clears preview cache for a specific conversation
  void clearCacheForConversation(String conversationId);

  /// Clears all preview cache
  void clearCache();
}
```

#### 3. Use Cases

**File**: `lib/features/preview/domain/usecases/publish_preview_usecase.dart`
**Changes**: Create new file with publish use case

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PublishPreviewUsecase {
  PublishPreviewUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  Future<Result<ConversationPreview>> call({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    _logger.i('Publishing preview for conversation: $conversationId');
    _logger.d('Message IDs: ${messageIds.join(", ")}');

    // Validate message count (3-5 messages)
    if (messageIds.length < 3 || messageIds.length > 5) {
      _logger.w('Invalid message count: ${messageIds.length}');
      return failure(const UnknownFailure(
        details: 'Please select between 3 and 5 messages for the preview',
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

**File**: `lib/features/preview/domain/usecases/get_preview_usecase.dart`
**Changes**: Create new file with fetch use case

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class GetPreviewUsecase {
  GetPreviewUsecase(this._repository, this._logger);

  final PreviewRepository _repository;
  final Logger _logger;

  Future<Result<ConversationPreview>> call(String previewId) async {
    _logger.i('Fetching preview: $previewId');
    return _repository.getPreview(previewId);
  }
}
```

#### 4. Data Transfer Objects (DTOs)

**File**: `lib/features/preview/data/models/publish_preview_request_dto.dart`
**Changes**: Create new file with request DTO

```dart
import 'package:json_annotation/json_annotation.dart';

part 'publish_preview_request_dto.g.dart';

/// Request DTO for publishing a conversation preview
@JsonSerializable()
class PublishPreviewRequestDto {
  const PublishPreviewRequestDto({
    required this.conversationId,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.messageIds,
  });

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  final String title;

  final String description;

  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;

  @JsonKey(name: 'message_ids')
  final List<String> messageIds;

  Map<String, dynamic> toJson() => _$PublishPreviewRequestDtoToJson(this);
}
```

**File**: `lib/features/preview/data/models/conversation_preview_dto.dart`
**Changes**: Create new file with response DTO

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_preview_dto.g.dart';

/// DTO for conversation preview API response
@JsonSerializable()
class ConversationPreviewDto {
  const ConversationPreviewDto({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.messageIds,
    required this.publicUrl,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ConversationPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationPreviewDtoFromJson(json);

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  final String title;

  final String description;

  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;

  @JsonKey(name: 'message_ids')
  final List<String> messageIds;

  @JsonKey(name: 'public_url')
  final String publicUrl;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  Map<String, dynamic> toJson() => _$ConversationPreviewDtoToJson(this);
}

/// Mapper extension for DTO to domain conversion
extension ConversationPreviewDtoMapper on ConversationPreviewDto {
  ConversationPreview toDomain() {
    return ConversationPreview(
      id: id,
      conversationId: conversationId,
      metadata: PreviewMetadata(
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
      ),
      messageIds: messageIds,
      publicUrl: publicUrl,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
```

#### 5. Remote Datasource

**File**: `lib/features/preview/data/datasources/preview_remote_datasource.dart`
**Changes**: Create new file with datasource interface

```dart
import 'package:carbon_voice_console/features/preview/data/models/conversation_preview_dto.dart';
import 'package:carbon_voice_console/features/preview/data/models/publish_preview_request_dto.dart';

/// Remote datasource for preview API operations
abstract class PreviewRemoteDataSource {
  /// Publishes a new preview to the API
  Future<ConversationPreviewDto> publishPreview(
    PublishPreviewRequestDto request,
  );

  /// Fetches a preview by ID from the API
  Future<ConversationPreviewDto> getPreview(String previewId);

  /// Fetches all previews for a conversation from the API
  Future<List<ConversationPreviewDto>> getPreviewsForConversation(
    String conversationId,
  );
}
```

**File**: `lib/features/preview/data/datasources/preview_remote_datasource_impl.dart`
**Changes**: Create new file with datasource implementation

```dart
import 'dart:convert';

import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/preview/data/datasources/preview_remote_datasource.dart';
import 'package:carbon_voice_console/features/preview/data/models/conversation_preview_dto.dart';
import 'package:carbon_voice_console/features/preview/data/models/publish_preview_request_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: PreviewRemoteDataSource)
class PreviewRemoteDataSourceImpl implements PreviewRemoteDataSource {
  PreviewRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<ConversationPreviewDto> publishPreview(
    PublishPreviewRequestDto request,
  ) async {
    try {
      final requestBody = request.toJson();

      _logger.d('Publishing preview: ${jsonEncode(requestBody)}');

      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v1/previews',
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Handle both wrapped and direct responses
        final Map<String, dynamic> previewData;
        if (data.containsKey('preview') &&
            data['preview'] is Map<String, dynamic>) {
          previewData = data['preview'] as Map<String, dynamic>;
        } else {
          previewData = data;
        }

        try {
          final previewDto = ConversationPreviewDto.fromJson(previewData);
          _logger.i('Preview published successfully: ${previewDto.id}');
          return previewDto;
        } on Exception catch (e, stack) {
          _logger.e(
            'Failed to parse publish preview response: $e',
            error: e,
            stackTrace: stack,
          );
          throw ServerException(
            statusCode: 422,
            message: 'Failed to parse preview response: $e',
          );
        }
      } else {
        _logger.e('Failed to publish preview: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to publish preview: ${response.body}',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error publishing preview', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to publish preview: $e');
    }
  }

  @override
  Future<ConversationPreviewDto> getPreview(String previewId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v1/previews/$previewId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Handle both wrapped and direct responses
        final Map<String, dynamic> previewData;
        if (data.containsKey('preview') &&
            data['preview'] is Map<String, dynamic>) {
          previewData = data['preview'] as Map<String, dynamic>;
        } else {
          previewData = data;
        }

        try {
          return ConversationPreviewDto.fromJson(previewData);
        } catch (e, stack) {
          _logger.e(
            'Failed to parse preview JSON: $e',
            error: e,
            stackTrace: stack,
          );
          throw ServerException(
            statusCode: 422,
            message: 'Invalid preview JSON structure: $e',
          );
        }
      } else {
        _logger.e('Failed to fetch preview: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch preview',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching preview', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch preview: $e');
    }
  }

  @override
  Future<List<ConversationPreviewDto>> getPreviewsForConversation(
    String conversationId,
  ) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v1/previews?conversation_id=$conversationId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle array response variations
        List<dynamic> previewsList;
        if (data is List) {
          previewsList = data;
        } else if (data is Map<String, dynamic> && data.containsKey('previews')) {
          previewsList = data['previews'] as List<dynamic>;
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          previewsList = data['data'] as List<dynamic>;
        } else {
          _logger.w('Unexpected response format, treating as empty list');
          previewsList = [];
        }

        try {
          return previewsList
              .map((json) =>
                  ConversationPreviewDto.fromJson(json as Map<String, dynamic>))
              .toList();
        } on Exception catch (e, stack) {
          _logger.e(
            'Failed to parse previews list: $e',
            error: e,
            stackTrace: stack,
          );
          throw ServerException(
            statusCode: 422,
            message: 'Failed to parse previews: $e',
          );
        }
      } else {
        _logger.e('Failed to fetch previews: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch previews',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e(
        'Network error fetching previews',
        error: e,
        stackTrace: stack,
      );
      throw NetworkException(message: 'Failed to fetch previews: $e');
    }
  }
}
```

#### 6. Repository Implementation

**File**: `lib/features/preview/data/repositories/preview_repository_impl.dart`
**Changes**: Create new file with repository implementation

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/preview/data/datasources/preview_remote_datasource.dart';
import 'package:carbon_voice_console/features/preview/data/models/conversation_preview_dto.dart';
import 'package:carbon_voice_console/features/preview/data/models/publish_preview_request_dto.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/domain/repositories/preview_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: PreviewRepository)
class PreviewRepositoryImpl implements PreviewRepository {
  PreviewRepositoryImpl(this._remoteDataSource, this._logger);

  final PreviewRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: conversationId -> list of previews
  final Map<String, List<ConversationPreview>> _cachedPreviews = {};

  @override
  Future<Result<ConversationPreview>> publishPreview({
    required String conversationId,
    required PreviewMetadata metadata,
    required List<String> messageIds,
  }) async {
    try {
      final requestDto = PublishPreviewRequestDto(
        conversationId: conversationId,
        title: metadata.title,
        description: metadata.description,
        coverImageUrl: metadata.coverImageUrl,
        messageIds: messageIds,
      );

      final previewDto = await _remoteDataSource.publishPreview(requestDto);
      final preview = previewDto.toDomain();

      // Clear cache for this conversation (new preview added)
      clearCacheForConversation(conversationId);

      return success(preview);
    } on ServerException catch (e) {
      _logger.e('Server error publishing preview', error: e);
      return failure(
        ServerFailure(statusCode: e.statusCode, details: e.message),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error publishing preview', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e(
        'Unknown error publishing preview',
        error: e,
        stackTrace: stack,
      );
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<ConversationPreview>> getPreview(String previewId) async {
    try {
      final previewDto = await _remoteDataSource.getPreview(previewId);
      final preview = previewDto.toDomain();

      return success(preview);
    } on ServerException catch (e) {
      _logger.e('Server error fetching preview', error: e);
      return failure(
        ServerFailure(statusCode: e.statusCode, details: e.message),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error fetching preview', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching preview', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<ConversationPreview>>> getPreviewsForConversation(
    String conversationId,
  ) async {
    try {
      // Check cache
      if (_cachedPreviews.containsKey(conversationId)) {
        _logger.d('Returning cached previews for conversation: $conversationId');
        return success(_cachedPreviews[conversationId]!);
      }

      final previewDtos =
          await _remoteDataSource.getPreviewsForConversation(conversationId);
      final previews = previewDtos.map((dto) => dto.toDomain()).toList();

      // Cache results
      _cachedPreviews[conversationId] = previews;

      return success(previews);
    } on ServerException catch (e) {
      _logger.e('Server error fetching previews', error: e);
      return failure(
        ServerFailure(statusCode: e.statusCode, details: e.message),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error fetching previews', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e(
        'Unknown error fetching previews',
        error: e,
        stackTrace: stack,
      );
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  void clearCacheForConversation(String conversationId) {
    _cachedPreviews.remove(conversationId);
    _logger.d('Cleared preview cache for conversation: $conversationId');
  }

  @override
  void clearCache() {
    _cachedPreviews.clear();
    _logger.d('Cleared all preview cache');
  }
}
```

#### 7. Code Generation

**File**: Terminal
**Changes**: Run build_runner to generate JSON serialization code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/features/preview/data/models/publish_preview_request_dto.g.dart`
- `lib/features/preview/data/models/conversation_preview_dto.g.dart`

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] JSON serialization generated successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Dependency injection configured (classes marked with `@injectable`, `@lazySingleton`)
- [ ] Unit tests pass for DTOs (serialization/deserialization)
- [ ] Unit tests pass for mappers (DTO to domain conversion)
- [ ] Repository unit tests pass (mock datasource)

#### Manual Verification:
- [ ] Domain entities are immutable (all fields final)
- [ ] Repository interface matches domain needs
- [ ] DTOs handle snake_case ↔ camelCase conversion correctly
- [ ] Datasource handles wrapped and direct API responses
- [ ] Cache invalidation works correctly in repository

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual code review before proceeding to Phase 2.

---

## Phase 2: Presentation Layer - BLoC & Cubit

### Overview
Implement state management for preview publishing. Create BLoC for async publish operation and Cubit for local form state. No UI components yet.

### Changes Required:

#### 1. Publish Preview BLoC

**File**: `lib/features/preview/presentation/bloc/publish_preview_event.dart`
**Changes**: Create new file with events

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:equatable/equatable.dart';

sealed class PublishPreviewEvent extends Equatable {
  const PublishPreviewEvent();

  @override
  List<Object?> get props => [];
}

/// Event to publish a new preview
class PublishPreview extends PublishPreviewEvent {
  const PublishPreview({
    required this.conversationId,
    required this.metadata,
    required this.messageIds,
  });

  final String conversationId;
  final PreviewMetadata metadata;
  final List<String> messageIds;

  @override
  List<Object?> get props => [conversationId, metadata, messageIds];
}

/// Event to reset the publish state
class ResetPublishPreview extends PublishPreviewEvent {
  const ResetPublishPreview();
}
```

**File**: `lib/features/preview/presentation/bloc/publish_preview_state.dart`
**Changes**: Create new file with states

```dart
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:equatable/equatable.dart';

sealed class PublishPreviewState extends Equatable {
  const PublishPreviewState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PublishPreviewInitial extends PublishPreviewState {
  const PublishPreviewInitial();
}

/// Publishing in progress
class PublishPreviewInProgress extends PublishPreviewState {
  const PublishPreviewInProgress();
}

/// Publish successful
class PublishPreviewSuccess extends PublishPreviewState {
  const PublishPreviewSuccess({
    required this.preview,
  });

  final ConversationPreview preview;

  @override
  List<Object?> get props => [preview];
}

/// Publish failed
class PublishPreviewError extends PublishPreviewState {
  const PublishPreviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

**File**: `lib/features/preview/presentation/bloc/publish_preview_bloc.dart`
**Changes**: Create new file with BLoC implementation

```dart
import 'package:carbon_voice_console/features/preview/domain/usecases/publish_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PublishPreviewBloc
    extends Bloc<PublishPreviewEvent, PublishPreviewState> {
  PublishPreviewBloc(
    this._publishPreviewUsecase,
    this._logger,
  ) : super(const PublishPreviewInitial()) {
    on<PublishPreview>(_onPublishPreview);
    on<ResetPublishPreview>(_onResetPublishPreview);
  }

  final PublishPreviewUsecase _publishPreviewUsecase;
  final Logger _logger;

  Future<void> _onPublishPreview(
    PublishPreview event,
    Emitter<PublishPreviewState> emit,
  ) async {
    emit(const PublishPreviewInProgress());

    final result = await _publishPreviewUsecase(
      conversationId: event.conversationId,
      metadata: event.metadata,
      messageIds: event.messageIds,
    );

    result.fold(
      onSuccess: (preview) {
        _logger.i('Preview published successfully: ${preview.id}');
        emit(PublishPreviewSuccess(preview: preview));
      },
      onFailure: (failure) {
        _logger.e('Failed to publish preview: ${failure.failure.code}');
        emit(PublishPreviewError(
          failure.failure.details ?? 'Failed to publish preview',
        ));
      },
    );
  }

  void _onResetPublishPreview(
    ResetPublishPreview event,
    Emitter<PublishPreviewState> emit,
  ) {
    emit(const PublishPreviewInitial());
  }
}
```

#### 2. Preview Composer Cubit

**File**: `lib/features/preview/presentation/cubit/preview_composer_state.dart`
**Changes**: Create new file with Cubit state

```dart
import 'package:equatable/equatable.dart';

/// State for the preview composer form
class PreviewComposerState extends Equatable {
  const PreviewComposerState({
    this.title = '',
    this.description = '',
    this.coverImageUrl,
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
  });

  final String title;
  final String description;
  final String? coverImageUrl;
  final String? titleError;
  final String? descriptionError;
  final String? coverImageUrlError;

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      coverImageUrlError == null;

  bool get hasErrors =>
      titleError != null || descriptionError != null || coverImageUrlError != null;

  PreviewComposerState copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
  }) {
    return PreviewComposerState(
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      titleError: titleError,
      descriptionError: descriptionError,
      coverImageUrlError: coverImageUrlError,
    );
  }

  PreviewComposerState clearErrors() {
    return PreviewComposerState(
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        coverImageUrl,
        titleError,
        descriptionError,
        coverImageUrlError,
      ];
}
```

**File**: `lib/features/preview/presentation/cubit/preview_composer_cubit.dart`
**Changes**: Create new file with Cubit implementation

```dart
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerCubit extends Cubit<PreviewComposerState> {
  PreviewComposerCubit(this._logger) : super(const PreviewComposerState());

  final Logger _logger;

  static const int maxDescriptionLength = 200;

  /// Initialize form with conversation data
  void initialize({
    required String conversationTitle,
    String? conversationDescription,
    String? conversationImageUrl,
  }) {
    _logger.d('Initializing preview composer');
    emit(PreviewComposerState(
      title: conversationTitle,
      description: conversationDescription ?? '',
      coverImageUrl: conversationImageUrl,
    ));
  }

  /// Update title field
  void updateTitle(String title) {
    String? error;

    if (title.trim().isEmpty) {
      error = 'Title is required';
    } else if (title.trim().length > 100) {
      error = 'Title must be 100 characters or less';
    }

    emit(state.copyWith(
      title: title,
      titleError: error,
    ));
  }

  /// Update description field
  void updateDescription(String description) {
    String? error;

    if (description.trim().isEmpty) {
      error = 'Description is required';
    } else if (description.trim().length > maxDescriptionLength) {
      error = 'Description must be $maxDescriptionLength characters or less';
    }

    emit(state.copyWith(
      description: description,
      descriptionError: error,
    ));
  }

  /// Update cover image URL field
  void updateCoverImageUrl(String? url) {
    String? error;

    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Invalid URL format';
      }
    }

    emit(state.copyWith(
      coverImageUrl: url?.trim(),
      coverImageUrlError: error,
    ));
  }

  /// Validate all fields
  bool validate() {
    String? titleError;
    String? descriptionError;

    if (state.title.trim().isEmpty) {
      titleError = 'Title is required';
    } else if (state.title.trim().length > 100) {
      titleError = 'Title must be 100 characters or less';
    }

    if (state.description.trim().isEmpty) {
      descriptionError = 'Description is required';
    } else if (state.description.trim().length > maxDescriptionLength) {
      descriptionError =
          'Description must be $maxDescriptionLength characters or less';
    }

    if (titleError != null || descriptionError != null) {
      emit(state.copyWith(
        titleError: titleError,
        descriptionError: descriptionError,
      ));
      return false;
    }

    return true;
  }

  /// Reset form state
  void reset() {
    _logger.d('Resetting preview composer');
    emit(const PreviewComposerState());
  }
}
```

#### 3. BLoC Provider Configuration

**File**: `lib/core/providers/bloc_providers.dart`
**Changes**: Add new providers for preview feature

```dart
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';

// Add to blocProvidersDashboard() method:
static Widget blocProvidersDashboard() {
  return MultiBlocProvider(
    providers: [
      // Existing providers...
      BlocProvider<MessageSelectionCubit>(
        create: (_) => getIt<MessageSelectionCubit>(),
      ),

      // NEW: Preview feature providers
      BlocProvider<PublishPreviewBloc>(
        create: (_) => getIt<PublishPreviewBloc>(),
      ),
      BlocProvider<PreviewComposerCubit>(
        create: (_) => getIt<PreviewComposerCubit>(),
      ),
    ],
    child: const DashboardScreen(),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All BLoC files compile: `flutter analyze`
- [ ] Dependency injection works (run app and check GetIt registration)
- [ ] BLoC tests pass (state transitions for publish success/error)
- [ ] Cubit tests pass (form validation logic)
- [ ] Events are equatable and comparable
- [ ] States are immutable

#### Manual Verification:
- [ ] BLoC emits `PublishPreviewInProgress` when `PublishPreview` event dispatched
- [ ] BLoC emits `PublishPreviewSuccess` with preview on successful publish
- [ ] BLoC emits `PublishPreviewError` with message on failure
- [ ] Cubit validates title (required, max 100 chars)
- [ ] Cubit validates description (required, max 200 chars)
- [ ] Cubit validates cover image URL format
- [ ] Cubit `isValid` property returns correct boolean
- [ ] Reset events clear state correctly

**Implementation Note**: After Phase 2 completion and all tests pass, proceed to Phase 3 for UI implementation.

---

## Phase 3: UI - Preview Composer & Confirmation Screens

### Overview
Build user-facing screens for composing preview metadata and displaying success confirmation. Integrate with existing message selection flow.

### Changes Required:

#### 1. Route Definitions

**File**: `lib/core/routing/app_routes.dart`
**Changes**: Add preview route constants

```dart
class AppRoutes {
  AppRoutes._();

  // Existing routes...
  static const String settings = '/dashboard/settings';

  // NEW: Preview routes
  static const String previewComposer = '/dashboard/preview/composer';
  static const String previewConfirmation = '/dashboard/preview/confirmation';
}
```

**File**: `lib/core/routing/route_guard.dart`
**Changes**: Add routes to validation list

```dart
static const List<String> validRoutes = [
  AppRoutes.login,
  AppRoutes.oauthCallback,
  AppRoutes.dashboard,
  AppRoutes.users,
  AppRoutes.voiceMemos,
  AppRoutes.settings,
  AppRoutes.previewComposer,        // ADD
  AppRoutes.previewConfirmation,    // ADD
];
```

**File**: `lib/core/routing/app_router.dart`
**Changes**: Register preview routes in ShellRoute

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    // Existing routes...
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SettingsScreen(),
      ),
    ),

    // NEW: Preview Composer route
    GoRoute(
      path: AppRoutes.previewComposer,
      name: 'previewComposer',
      pageBuilder: (context, state) {
        final conversationId = state.uri.queryParameters['conversationId'];

        return NoTransitionPage(
          child: PreviewComposerScreen(
            conversationId: conversationId ?? '',
          ),
        );
      },
    ),

    // NEW: Preview Confirmation route
    GoRoute(
      path: AppRoutes.previewConfirmation,
      name: 'previewConfirmation',
      pageBuilder: (context, state) {
        final previewId = state.uri.queryParameters['previewId'];

        return NoTransitionPage(
          child: PreviewConfirmationScreen(
            previewId: previewId ?? '',
          ),
        );
      },
    ),
  ],
)
```

#### 2. Message Selection Counter Widget

**File**: `lib/features/preview/presentation/widgets/message_selection_counter.dart`
**Changes**: Create new widget to display selection count

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays message selection count with validation indicator
class MessageSelectionCounter extends StatelessWidget {
  const MessageSelectionCounter({
    required this.selectedCount,
    required this.minCount,
    required this.maxCount,
    super.key,
  });

  final int selectedCount;
  final int minCount;
  final int maxCount;

  bool get isValid => selectedCount >= minCount && selectedCount <= maxCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isValid ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.info,
            size: 16,
            color: isValid ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '$selectedCount / $maxCount selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Preview Metadata Form Widget

**File**: `lib/features/preview/presentation/widgets/preview_metadata_form.dart`
**Changes**: Create form for title/description/coverImageUrl input

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
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

    // Initialize with state values
    final state = context.read<PreviewComposerCubit>().state;
    _titleController.text = state.title;
    _descriptionController.text = state.description;
    _coverImageUrlController.text = state.coverImageUrl ?? '';
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
    return BlocBuilder<PreviewComposerCubit, PreviewComposerState>(
      builder: (context, state) {
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
              maxLength: 100,
              onChanged: (value) {
                context.read<PreviewComposerCubit>().updateTitle(value);
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Short Description *',
                hintText: 'Brief description to entice listeners (max 200 characters)',
                errorText: state.descriptionError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLines: 3,
              maxLength: PreviewComposerCubit.maxDescriptionLength,
              onChanged: (value) {
                context.read<PreviewComposerCubit>().updateDescription(value);
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
                context.read<PreviewComposerCubit>().updateCoverImageUrl(value);
              },
            ),
          ],
        );
      },
    );
  }
}
```

#### 4. Preview Share Panel Widget

**File**: `lib/features/preview/presentation/widgets/preview_share_panel.dart`
**Changes**: Create widget for URL display and sharing

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Panel for displaying and sharing preview URL
class PreviewSharePanel extends StatelessWidget {
  const PreviewSharePanel({
    required this.publicUrl,
    super.key,
  });

  final String publicUrl;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: publicUrl));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview URL copied to clipboard!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your preview is live!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this URL to promote your conversation:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // URL display box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              publicUrl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Copy URL',
                  icon: Icons.copy,
                  onPressed: () => _copyToClipboard(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Open Preview',
                  icon: Icons.open_in_new,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    // Open URL in browser
                    // TODO: Implement url_launcher integration
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### 5. Preview Composer Screen

**File**: `lib/features/preview/presentation/screens/preview_composer_screen.dart`
**Changes**: Create full screen for composing preview

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/preview_metadata.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/publish_preview_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview
class PreviewComposerScreen extends StatefulWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  State<PreviewComposerScreen> createState() => _PreviewComposerScreenState();
}

class _PreviewComposerScreenState extends State<PreviewComposerScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize composer with conversation data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conversationState = context.read<ConversationBloc>().state;

      if (conversationState is ConversationLoaded) {
        final conversation = conversationState.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => conversationState.conversations.first,
        );

        context.read<PreviewComposerCubit>().initialize(
              conversationTitle: conversation.name,
              conversationDescription: conversation.description,
              conversationImageUrl: conversation.imageUrl,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen for publish success
        BlocListener<PublishPreviewBloc, PublishPreviewState>(
          listener: (context, state) {
            if (state is PublishPreviewSuccess) {
              // Navigate to confirmation screen
              context.go(
                '${AppRoutes.previewConfirmation}?previewId=${state.preview.id}',
              );

              // Reset state
              context.read<PublishPreviewBloc>().add(const ResetPublishPreview());
              context.read<PreviewComposerCubit>().reset();
              context.read<MessageSelectionCubit>().clearSelection();
            } else if (state is PublishPreviewError) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
            builder: (context, selectionState) {
              final selectedCount = selectionState.selectedCount;
              final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection counter
                    MessageSelectionCounter(
                      selectedCount: selectedCount,
                      minCount: 3,
                      maxCount: 5,
                    ),

                    if (!isValidSelection) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Please select between 3 and 5 messages to include in your preview.',
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
                    BlocBuilder<PreviewComposerCubit, PreviewComposerState>(
                      builder: (context, composerState) {
                        return BlocBuilder<PublishPreviewBloc, PublishPreviewState>(
                          builder: (context, publishState) {
                            final isPublishing = publishState is PublishPreviewInProgress;
                            final canPublish = isValidSelection &&
                                               composerState.isValid &&
                                               !isPublishing;

                            return SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: isPublishing ? 'Publishing...' : 'Publish Preview',
                                icon: Icons.publish,
                                onPressed: canPublish ? () => _handlePublish(context) : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePublish(BuildContext context) {
    // Validate form
    final isValid = context.read<PreviewComposerCubit>().validate();
    if (!isValid) return;

    // Get state
    final composerState = context.read<PreviewComposerCubit>().state;
    final selectedMessageIds = context.read<MessageSelectionCubit>().getSelectedMessageIds();

    // Create metadata
    final metadata = PreviewMetadata(
      title: composerState.title.trim(),
      description: composerState.description.trim(),
      coverImageUrl: composerState.coverImageUrl?.trim(),
    );

    // Dispatch publish event
    context.read<PublishPreviewBloc>().add(
          PublishPreview(
            conversationId: widget.conversationId,
            metadata: metadata,
            messageIds: selectedMessageIds.toList(),
          ),
        );
  }
}
```

#### 6. Preview Confirmation Screen

**File**: `lib/features/preview/presentation/screens/preview_confirmation_screen.dart`
**Changes**: Create success screen with sharing options

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/features/preview/domain/entities/conversation_preview.dart';
import 'package:carbon_voice_console/features/preview/domain/usecases/get_preview_usecase.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_share_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen showing successful preview publication
class PreviewConfirmationScreen extends StatefulWidget {
  const PreviewConfirmationScreen({
    required this.previewId,
    super.key,
  });

  final String previewId;

  @override
  State<PreviewConfirmationScreen> createState() =>
      _PreviewConfirmationScreenState();
}

class _PreviewConfirmationScreenState extends State<PreviewConfirmationScreen> {
  ConversationPreview? _preview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    // Get use case from DI
    final getPreviewUsecase = getIt<GetPreviewUsecase>();

    final result = await getPreviewUsecase(widget.previewId);

    result.fold(
      onSuccess: (preview) {
        setState(() {
          _preview = preview;
          _isLoading = false;
        });
      },
      onFailure: (failure) {
        setState(() {
          _error = failure.failure.details ?? 'Failed to load preview';
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Published'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Dashboard',
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ],
        ),
      );
    }

    if (_preview == null) {
      return const Center(
        child: Text('Preview not found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Success message
        Center(
          child: Text(
            'Preview Published Successfully!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Your conversation preview is now live and ready to share.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),

        // Share panel
        PreviewSharePanel(publicUrl: _preview!.publicUrl),
        const SizedBox(height: 32),

        // Back to dashboard button
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Back to Dashboard',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
      ],
    );
  }
}
```

#### 7. Dashboard Integration - Publish Button

**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_action_panel_wrapper.dart`
**Changes**: Add "Publish Preview" button to action panel

```dart
// Add to existing action panel buttons:

MessagesActionPanel(
  // Existing callbacks...
  onDownloadAudio: () { /* existing code */ },
  onDownloadTranscript: () { /* existing code */ },

  // NEW: Add publish preview callback
  onPublishPreview: () {
    final messageIds = context.read<MessageSelectionCubit>().getSelectedMessageIds();

    // Validate selection count
    if (messageIds.length < 3 || messageIds.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select between 3 and 5 messages for preview'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Navigate to composer
    final conversationState = context.read<ConversationBloc>().state;
    if (conversationState is ConversationLoaded &&
        conversationState.selectedConversationIds.isNotEmpty) {
      final conversationId = conversationState.selectedConversationIds.first;
      context.go('${AppRoutes.previewComposer}?conversationId=$conversationId');
    }
  },
)
```

**File**: `lib/features/messages/presentation_messages_dashboard/components/messages_action_panel.dart`
**Changes**: Add publish preview button UI

```dart
class MessagesActionPanel extends StatelessWidget {
  const MessagesActionPanel({
    this.onDownloadAudio,
    this.onDownloadTranscript,
    this.onPublishPreview,  // NEW parameter
    super.key,
  });

  final VoidCallback? onDownloadAudio;
  final VoidCallback? onDownloadTranscript;
  final VoidCallback? onPublishPreview;  // NEW parameter

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Existing buttons...
        AppButton(
          label: 'Download Audio',
          icon: AppIcons.download,
          onPressed: onDownloadAudio,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Download Transcript',
          icon: AppIcons.download,
          onPressed: onDownloadTranscript,
        ),

        // NEW: Publish preview button
        const SizedBox(width: 8),
        AppButton(
          label: 'Publish Preview',
          icon: Icons.publish,
          variant: AppButtonVariant.primary,
          onPressed: onPublishPreview,
        ),
      ],
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All screens compile without errors: `flutter analyze`
- [ ] Routes registered correctly (app launches without routing errors)
- [ ] Widget tests pass for form validation UI
- [ ] Widget tests pass for selection counter display
- [ ] No lint warnings: `flutter analyze`

#### Manual Verification:
- [ ] "Publish Preview" button appears in dashboard when messages selected
- [ ] Clicking button navigates to preview composer screen
- [ ] Composer screen pre-fills with conversation title/description/image
- [ ] Title field validates on input (required, max 100 chars)
- [ ] Description field validates on input (required, max 200 chars)
- [ ] Cover image URL field validates URL format
- [ ] Selection counter displays correctly (3/5, colors change)
- [ ] Publish button disabled when form invalid or selection invalid
- [ ] Publish button shows loading state during publish
- [ ] Success: navigates to confirmation screen with preview URL
- [ ] Error: shows snackbar with error message
- [ ] Confirmation screen displays public URL correctly
- [ ] Copy button copies URL to clipboard
- [ ] Back button returns to dashboard
- [ ] Message selection clears after successful publish

**Implementation Note**: After Phase 3 completion, perform full end-to-end manual testing before declaring feature complete.

---

## Testing Strategy

### Unit Tests

#### Domain Layer Tests:
- **Entities**: Test equality, copyWith, props
  - `preview_metadata_test.dart`: Test metadata creation, equality, copyWith
  - `conversation_preview_test.dart`: Test preview entity, isDeleted computed property

- **Use Cases**: Test business logic
  - `publish_preview_usecase_test.dart`: Test message count validation (3-5), repository calls
  - `get_preview_usecase_test.dart`: Test preview fetching

#### Data Layer Tests:
- **DTOs**: Test JSON serialization/deserialization
  - `publish_preview_request_dto_test.dart`: Test toJson(), field mapping
  - `conversation_preview_dto_test.dart`: Test fromJson(), toJson(), toDomain()

- **Repositories**: Test cache management and API error handling
  - `preview_repository_impl_test.dart`: Mock datasource, test cache invalidation

#### Presentation Layer Tests:
- **BLoCs**: Test state transitions
  - `publish_preview_bloc_test.dart`: Test publish success/error states

- **Cubits**: Test form validation
  - `preview_composer_cubit_test.dart`: Test validation logic, field updates

### Widget Tests

- **Forms**: Test input validation UI
  - `preview_metadata_form_test.dart`: Test error display, character counters

- **Counters**: Test selection counter display
  - `message_selection_counter_test.dart`: Test color changes, valid/invalid states

- **Screens**: Test navigation and BLoC integration
  - `preview_composer_screen_test.dart`: Test form submission, navigation
  - `preview_confirmation_screen_test.dart`: Test URL display, buttons

### Integration Tests

- **End-to-End Flow**: Full preview creation workflow
  - Select messages → open composer → fill form → publish → confirmation
  - Test with mock API responses
  - Verify state persistence across screens

### Manual Testing Steps

1. **Happy Path**:
   - [ ] Select exactly 3 messages from conversation
   - [ ] Click "Publish Preview" button
   - [ ] Verify composer opens with pre-filled data
   - [ ] Edit title and description
   - [ ] Click "Publish Preview"
   - [ ] Verify confirmation screen shows URL
   - [ ] Click "Copy URL"
   - [ ] Paste URL in browser
   - [ ] Verify preview page renders correctly

2. **Validation Errors**:
   - [ ] Try selecting 2 messages (should show error)
   - [ ] Try selecting 6 messages (should show error)
   - [ ] Try publishing with empty title (should show error)
   - [ ] Try publishing with empty description (should show error)
   - [ ] Try invalid URL in cover image field (should show error)

3. **Edge Cases**:
   - [ ] Test with conversation that has no description
   - [ ] Test with conversation that has no cover image
   - [ ] Test network error during publish (should show error snackbar)
   - [ ] Test rapid button clicks (should prevent duplicate publishes)
   - [ ] Test back button during publish (should cancel gracefully)

4. **Error Handling**:
   - [ ] Simulate 401 error (auth failure)
   - [ ] Simulate 500 error (server error)
   - [ ] Simulate timeout (network timeout)
   - [ ] Verify user-friendly error messages displayed

## Performance Considerations

### Optimizations:
- **In-Memory Cache**: Repository caches previews by conversation ID to avoid redundant API calls
- **Debounced Validation**: Form validation only runs on input change, not every keystroke
- **Lazy Loading**: Confirmation screen fetches preview on-demand (not passed through navigation)
- **State Management**: Cubit for form (lightweight), BLoC for async operations (heavy)

### Potential Bottlenecks:
- **Large Message Lists**: Selecting from thousands of messages may be slow (not addressed in this phase)
- **Image URL Validation**: Synchronous URL parsing could block UI (acceptable for MVP)
- **API Latency**: Publish operation may take several seconds (loading state handles UX)

## Migration Notes

### API Endpoint Assumptions

**Note**: These endpoints are hypothetical - they must be confirmed with the backend team before implementation.

#### Publish Preview
```
POST /v1/previews
Content-Type: application/json
Authorization: Bearer {token}

Request Body:
{
  "conversation_id": "conv_123",
  "title": "Episode 1: Introduction",
  "description": "Join us as we discuss...",
  "cover_image_url": "https://example.com/cover.jpg",  // optional
  "message_ids": ["msg_1", "msg_2", "msg_3"]
}

Response (201 Created):
{
  "_id": "preview_abc",
  "conversation_id": "conv_123",
  "title": "Episode 1: Introduction",
  "description": "Join us as we discuss...",
  "cover_image_url": "https://example.com/cover.jpg",
  "message_ids": ["msg_1", "msg_2", "msg_3"],
  "public_url": "https://carbonvoice.app/preview/preview_abc",
  "created_at": "2025-12-09T12:00:00Z",
  "updated_at": null,
  "deleted_at": null
}
```

#### Get Preview
```
GET /v1/previews/{previewId}
Authorization: Bearer {token}

Response (200 OK):
{
  "_id": "preview_abc",
  "conversation_id": "conv_123",
  "title": "Episode 1: Introduction",
  "description": "Join us as we discuss...",
  "cover_image_url": "https://example.com/cover.jpg",
  "message_ids": ["msg_1", "msg_2", "msg_3"],
  "public_url": "https://carbonvoice.app/preview/preview_abc",
  "created_at": "2025-12-09T12:00:00Z",
  "updated_at": null,
  "deleted_at": null
}
```

#### List Previews for Conversation
```
GET /v1/previews?conversation_id={conversationId}
Authorization: Bearer {token}

Response (200 OK):
[
  {
    "_id": "preview_abc",
    "conversation_id": "conv_123",
    "title": "Episode 1: Introduction",
    // ... full preview object
  },
  {
    "_id": "preview_xyz",
    "conversation_id": "conv_123",
    "title": "Episode 2: Deep Dive",
    // ... full preview object
  }
]
```

### Backend Requirements:
- **Preview Storage**: Database table/collection for storing previews
- **Public Preview Page**: Server-rendered or static page at `{public_url}`
- **Preview Audio**: API must serve audio files for selected messages (pre-signed URLs)
- **Deep Linking**: Preview page CTA must support deep linking to app (e.g., `carbonvoice://conversation/{id}`)
- **Metadata Limits**: Enforce title (max 100 chars), description (max 200 chars) on backend
- **Message Count Validation**: Enforce 3-5 messages on backend

### No Data Migration Needed:
This feature adds new functionality without modifying existing data structures. Existing conversations, messages, and users remain unchanged.

## References

- **Original Requirements**: User-provided prompt above
- **Clean Architecture Docs**: [CLAUDE.md](CLAUDE.md)
- **API Documentation**: [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md)
- **OAuth Flow**: [docs/OAUTH2_EXPLAINED.md](docs/OAUTH2_EXPLAINED.md)
- **Message Selection Pattern**: [message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart)
- **BLoC Communication Pattern**: [dashboard_screen.dart:50-73](lib/features/messages/presentation_messages_dashboard/screens/dashboard_screen.dart#L50-L73)
- **Repository Pattern**: [message_repository_impl.dart](lib/features/messages/data/repositories/message_repository_impl.dart)
- **Routing Pattern**: [app_router.dart](lib/core/routing/app_router.dart)
