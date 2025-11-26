# Dashboard Data Layer Implementation Plan

## Overview

Implement a complete clean architecture data layer for the Carbon Voice Console dashboard, integrating with the CarbonVoice API to display real workspaces, conversations, messages, and users. This replaces the current dummy data implementation with a production-ready, paginated data fetching system.

## Current State Analysis

### What Exists Now:
- **Authentication**: OAuth2 flow working with token management via `lib/features/auth/`
- **Authenticated HTTP Service**: `lib/core/network/authenticated_http_service.dart:8` ready for API calls
- **Dashboard UI**: `lib/features/dashboard/presentation/dashboard_screen.dart:14` with hardcoded dummy data
- **Dummy Model**: `lib/features/dashboard/models/audio_message.dart:1` (simple, no JSON serialization)
- **Clean Architecture Pattern**: Established in auth feature (domain/data/presentation layers)
- **BLoC Pattern**: Auth feature shows the pattern to follow
- **Result Type**: `lib/core/utils/result.dart` for type-safe error handling
- **Dependency Injection**: get_it + injectable configured

### What's Missing:
- No data layer for workspaces, conversations, messages, users
- No repositories or data sources for dashboard features
- No BLoC for dashboard state management
- No API integration (using hardcoded data)
- No pagination logic
- No proper models with JSON serialization

### Key Constraints Discovered:
- API base URL: `https://api.carbonvoice.app` (`lib/core/config/oauth_config.dart:34`)
- Must use `AuthenticatedHttpService` for all API calls
- Must follow existing clean architecture pattern from auth feature
- Must use Result type for error handling
- Must use BLoC pattern for state management

## Desired End State

After this plan is complete:

1. **Four new feature modules** in `lib/features/`:
   - `workspaces/` - Workspace listing and selection
   - `conversations/` - Conversation (channel) listing and selection
   - `messages/` - Message listing with pagination
   - `users/` - User profile fetching

2. **Dashboard screen** will:
   - Auto-load user workspaces on mount
   - Auto-select first workspace
   - Auto-load conversations for selected workspace
   - Auto-select first conversation
   - Display real paginated messages from CarbonVoice API
   - Allow manual workspace/conversation switching

3. **Data flows correctly**:
   - Workspaces → Conversations → Messages → Users
   - Pagination works using sequential endpoint
   - User profiles hydrate message owner information
   - All API errors handled gracefully with Result type

### Verification:
- Dashboard loads real data from CarbonVoice API
- Workspace dropdown shows actual user workspaces
- Message list shows real messages from selected conversation
- Pagination controls work (load more messages)
- No hardcoded dummy data remains

## What We're NOT Doing

To prevent scope creep, we explicitly exclude:
- ❌ Translation/transcript fetching
- ❌ AI actions (summarize, chat, export)
- ❌ Stream key fetching for audio playback
- ❌ Complex audio player implementation
- ❌ Message search functionality
- ❌ Real-time message updates (WebSocket/polling)
- ❌ Folder/tag organization
- ❌ Message creation/editing
- ❌ Conversation creation/editing
- ❌ Workspace creation/editing

**Focus**: Read-only dashboard displaying existing data with pagination.

## Implementation Approach

### Strategy:
1. **Bottom-up implementation**: Build data layer first (models → data sources → repositories), then presentation layer (BLoC → UI)
2. **Feature-by-feature**: Complete each feature module (workspaces, conversations, messages, users) before moving to integration
3. **Incremental testing**: Each phase has clear success criteria before moving forward
4. **Pattern replication**: Follow auth feature patterns for consistency

### Architecture:
- **Clean Architecture**: domain (repositories) → data (datasources, models, repository implementations) → presentation (BLoC, UI)
- **Dependency flow**: Presentation depends on domain, data implements domain interfaces
- **Error handling**: All repository methods return `Result<T>`, all data sources throw exceptions
- **State management**: BLoC pattern with sealed events/states

---

## Phase 1: Workspace Feature Implementation

### Overview
Create the workspace feature module with complete clean architecture layers. This includes domain repository interface, data layer with remote data source and models, and repository implementation. This is the foundation for loading user workspaces.

### Changes Required:

#### 1. Domain Layer - Repository Interface
**File**: `lib/features/workspaces/domain/repositories/workspace_repository.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Repository interface for workspace operations
abstract class WorkspaceRepository {
  /// Fetches all workspaces for the current authenticated user
  Future<Result<List<Workspace>>> getWorkspaces();

  /// Fetches a single workspace by ID
  Future<Result<Workspace>> getWorkspace(String workspaceId);
}
```

#### 2. Domain Layer - Entity
**File**: `lib/features/workspaces/domain/entities/workspace.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing a workspace
class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    this.guid,
    this.description,
  });

  final String id;
  final String name;
  final String? guid;
  final String? description;

  @override
  List<Object?> get props => [id, name, guid, description];
}
```

#### 3. Data Layer - Model
**File**: `lib/features/workspaces/data/models/workspace_model.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Data model for workspace with JSON serialization
class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    super.guid,
    super.description,
  });

  /// Creates a WorkspaceModel from JSON
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String? ?? json['_id'] as String,
      name: json['name'] as String,
      guid: json['guid'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Converts WorkspaceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (guid != null) 'guid': guid,
      if (description != null) 'description': description,
    };
  }

  /// Converts to domain entity
  Workspace toEntity() {
    return Workspace(
      id: id,
      name: name,
      guid: guid,
      description: description,
    );
  }
}
```

#### 4. Data Layer - Remote Data Source Interface
**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/workspace_model.dart';

/// Abstract interface for workspace remote data operations
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<WorkspaceModel>> getWorkspaces();

  /// Fetches a single workspace by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<WorkspaceModel> getWorkspace(String workspaceId);
}
```

#### 5. Data Layer - Remote Data Source Implementation
**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart`
**Changes**: Create new file

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/workspace_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRemoteDataSource)
class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  WorkspaceRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<WorkspaceModel>> getWorkspaces() async {
    try {
      _logger.d('Fetching workspaces from API');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/admin/workspaces',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {workspaces: [...]} or just [...]
        final List<dynamic> workspacesJson = data is List
            ? data
            : (data['workspaces'] as List<dynamic>? ?? data['data'] as List<dynamic>);

        final workspaces = workspacesJson
            .map((json) => WorkspaceModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${workspaces.length} workspaces');
        return workspaces;
      } else {
        _logger.e('Failed to fetch workspaces: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspaces',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspaces', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspaces: ${e.toString()}');
    }
  }

  @override
  Future<WorkspaceModel> getWorkspace(String workspaceId) async {
    try {
      _logger.d('Fetching workspace: $workspaceId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/admin/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final workspace = WorkspaceModel.fromJson(data as Map<String, dynamic>);
        _logger.i('Fetched workspace: ${workspace.name}');
        return workspace;
      } else {
        _logger.e('Failed to fetch workspace: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspace',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspace', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspace: ${e.toString()}');
    }
  }
}
```

#### 6. Data Layer - Repository Implementation
**File**: `lib/features/workspaces/data/repositories/workspace_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRepository)
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._remoteDataSource, this._logger);

  final WorkspaceRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache for workspaces
  List<Workspace>? _cachedWorkspaces;

  @override
  Future<Result<List<Workspace>>> getWorkspaces() async {
    try {
      // Return cached workspaces if available
      if (_cachedWorkspaces != null) {
        _logger.d('Returning cached workspaces');
        return success(_cachedWorkspaces!);
      }

      final workspaceModels = await _remoteDataSource.getWorkspaces();
      final workspaces = workspaceModels.map((model) => model.toEntity()).toList();

      // Cache the result
      _cachedWorkspaces = workspaces;

      return success(workspaces);
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspaces', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspaces', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspaces', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Workspace>> getWorkspace(String workspaceId) async {
    try {
      // Check cache first
      if (_cachedWorkspaces != null) {
        final cached = _cachedWorkspaces!.where((w) => w.id == workspaceId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached workspace: $workspaceId');
          return success(cached);
        }
      }

      final workspaceModel = await _remoteDataSource.getWorkspace(workspaceId);
      return success(workspaceModel.toEntity());
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspace', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspace', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspace', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the workspace cache (useful for refresh)
  void clearCache() {
    _cachedWorkspaces = null;
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/workspaces/`
- [ ] Dependency injection generates without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Repository can be injected: verify `getIt<WorkspaceRepository>()` works

#### Manual Verification:
- [ ] Cannot test API calls yet (will verify in Phase 5 dashboard integration)
- [ ] Code structure follows auth feature pattern
- [ ] Models have proper JSON serialization methods

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the structure is correct before proceeding to Phase 2.

---

## Phase 2: Conversation Feature Implementation

### Overview
Create the conversation (channel) feature module with complete clean architecture layers. Conversations belong to workspaces and contain messages. This enables loading conversation lists for a selected workspace.

### Changes Required:

#### 1. Domain Layer - Repository Interface
**File**: `lib/features/conversations/domain/repositories/conversation_repository.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches all conversations for a workspace
  Future<Result<List<Conversation>>> getConversations(String workspaceId);

  /// Fetches a single conversation by ID
  Future<Result<Conversation>> getConversation(String conversationId);
}
```

#### 2. Domain Layer - Entity
**File**: `lib/features/conversations/domain/entities/conversation.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing a conversation (channel)
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.guid,
    this.description,
    this.createdAt,
    this.messageCount,
  });

  final String id;
  final String name;
  final String workspaceId;
  final String? guid;
  final String? description;
  final DateTime? createdAt;
  final int? messageCount;

  @override
  List<Object?> get props => [id, name, workspaceId, guid, description, createdAt, messageCount];
}
```

#### 3. Data Layer - Model
**File**: `lib/features/conversations/data/models/conversation_model.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';

/// Data model for conversation with JSON serialization
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.name,
    required super.workspaceId,
    super.guid,
    super.description,
    super.createdAt,
    super.messageCount,
  });

  /// Creates a ConversationModel from JSON
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? json['_id'] as String,
      name: json['name'] as String,
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String,
      guid: json['guid'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      messageCount: json['messageCount'] as int? ?? json['message_count'] as int?,
    );
  }

  /// Converts ConversationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspaceId': workspaceId,
      if (guid != null) 'guid': guid,
      if (description != null) 'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (messageCount != null) 'messageCount': messageCount,
    };
  }

  /// Converts to domain entity
  Conversation toEntity() {
    return Conversation(
      id: id,
      name: name,
      workspaceId: workspaceId,
      guid: guid,
      description: description,
      createdAt: createdAt,
      messageCount: messageCount,
    );
  }
}
```

#### 4. Data Layer - Remote Data Source Interface
**File**: `lib/features/conversations/data/datasources/conversation_remote_datasource.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/conversations/data/models/conversation_model.dart';

/// Abstract interface for conversation remote data operations
abstract class ConversationRemoteDataSource {
  /// Fetches all conversations for a workspace from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationModel>> getConversations(String workspaceId);

  /// Fetches a single conversation by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<ConversationModel> getConversation(String conversationId);
}
```

#### 5. Data Layer - Remote Data Source Implementation
**File**: `lib/features/conversations/data/datasources/conversation_remote_datasource_impl.dart`
**Changes**: Create new file

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/data/models/conversation_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: ConversationRemoteDataSource)
class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  ConversationRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<ConversationModel>> getConversations(String workspaceId) async {
    try {
      _logger.d('Fetching conversations for workspace: $workspaceId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/channels/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {channels: [...]} or just [...]
        final List<dynamic> conversationsJson = data is List
            ? data
            : (data['channels'] as List<dynamic>? ?? data['data'] as List<dynamic>);

        final conversations = conversationsJson
            .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${conversations.length} conversations');
        return conversations;
      } else {
        _logger.e('Failed to fetch conversations: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch conversations',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching conversations', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch conversations: ${e.toString()}');
    }
  }

  @override
  Future<ConversationModel> getConversation(String conversationId) async {
    try {
      _logger.d('Fetching conversation: $conversationId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/channel/$conversationId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversation = ConversationModel.fromJson(data as Map<String, dynamic>);
        _logger.i('Fetched conversation: ${conversation.name}');
        return conversation;
      } else {
        _logger.e('Failed to fetch conversation: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch conversation',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching conversation', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch conversation: ${e.toString()}');
    }
  }
}
```

#### 6. Data Layer - Repository Implementation
**File**: `lib/features/conversations/data/repositories/conversation_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/conversations/data/datasources/conversation_remote_datasource.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: ConversationRepository)
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource, this._logger);

  final ConversationRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: workspaceId -> conversations
  final Map<String, List<Conversation>> _cachedConversations = {};

  @override
  Future<Result<List<Conversation>>> getConversations(String workspaceId) async {
    try {
      // Return cached conversations if available
      if (_cachedConversations.containsKey(workspaceId)) {
        _logger.d('Returning cached conversations for workspace: $workspaceId');
        return success(_cachedConversations[workspaceId]!);
      }

      final conversationModels = await _remoteDataSource.getConversations(workspaceId);
      final conversations = conversationModels.map((model) => model.toEntity()).toList();

      // Cache the result
      _cachedConversations[workspaceId] = conversations;

      return success(conversations);
    } on ServerException catch (e) {
      _logger.e('Server error fetching conversations', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching conversations', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching conversations', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async {
    try {
      // Check cache across all workspaces
      for (final conversations in _cachedConversations.values) {
        final cached = conversations.where((c) => c.id == conversationId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached conversation: $conversationId');
          return success(cached);
        }
      }

      final conversationModel = await _remoteDataSource.getConversation(conversationId);
      return success(conversationModel.toEntity());
    } on ServerException catch (e) {
      _logger.e('Server error fetching conversation', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching conversation', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching conversation', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the conversation cache for a specific workspace
  void clearCacheForWorkspace(String workspaceId) {
    _cachedConversations.remove(workspaceId);
  }

  /// Clears all conversation cache
  void clearCache() {
    _cachedConversations.clear();
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/conversations/`
- [ ] Dependency injection generates without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Repository can be injected: verify `getIt<ConversationRepository>()` works

#### Manual Verification:
- [ ] Cannot test API calls yet (will verify in Phase 5 dashboard integration)
- [ ] Code structure follows workspace feature pattern
- [ ] Models have proper JSON serialization methods

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: User Feature Implementation

### Overview
Create the user feature module with complete clean architecture layers. Users are referenced by messages (owner/sender), so this enables hydrating user profile information for message display.

### Changes Required:

#### 1. Domain Layer - Repository Interface
**File**: `lib/features/users/domain/repositories/user_repository.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Fetches a single user by ID
  Future<Result<User>> getUser(String userId);

  /// Fetches multiple users by their IDs (batch operation)
  Future<Result<List<User>>> getUsers(List<String> userIds);

  /// Fetches all users in a workspace
  Future<Result<List<User>>> getWorkspaceUsers(String workspaceId);
}
```

#### 2. Domain Layer - Entity
**File**: `lib/features/users/domain/entities/user.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing a user
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.workspaceId,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? workspaceId;

  @override
  List<Object?> get props => [id, name, email, avatarUrl, workspaceId];
}
```

#### 3. Data Layer - Model
**File**: `lib/features/users/data/models/user_model.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';

/// Data model for user with JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.email,
    super.avatarUrl,
    super.workspaceId,
  });

  /// Creates a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? json['userId'] as String,
      name: json['name'] as String? ?? json['username'] as String? ?? 'Unknown User',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String?,
    );
  }

  /// Converts UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (workspaceId != null) 'workspaceId': workspaceId,
    };
  }

  /// Converts to domain entity
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      workspaceId: workspaceId,
    );
  }
}
```

#### 4. Data Layer - Remote Data Source Interface
**File**: `lib/features/users/data/datasources/user_remote_datasource.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/users/data/models/user_model.dart';

/// Abstract interface for user remote data operations
abstract class UserRemoteDataSource {
  /// Fetches a single user by ID from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<UserModel> getUser(String userId);

  /// Fetches multiple users by their IDs (batch operation)
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<UserModel>> getUsers(List<String> userIds);

  /// Fetches all users in a workspace
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<UserModel>> getWorkspaceUsers(String workspaceId);
}
```

#### 5. Data Layer - Remote Data Source Implementation
**File**: `lib/features/users/data/datasources/user_remote_datasource_impl.dart`
**Changes**: Create new file

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/users/data/datasources/user_remote_datasource.dart';
import 'package:carbon_voice_console/features/users/data/models/user_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<UserModel> getUser(String userId) async {
    try {
      _logger.d('Fetching user: $userId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/users/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data as Map<String, dynamic>);
        _logger.i('Fetched user: ${user.name}');
        return user;
      } else {
        _logger.e('Failed to fetch user: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch user',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching user', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch user: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getUsers(List<String> userIds) async {
    try {
      _logger.d('Fetching ${userIds.length} users');

      // If API supports batch fetching, use it
      // For now, fetch individually (can be optimized later)
      final users = <UserModel>[];
      for (final userId in userIds) {
        try {
          final user = await getUser(userId);
          users.add(user);
        } on Exception catch (e) {
          _logger.w('Failed to fetch user $userId: $e');
          // Continue with other users
        }
      }

      _logger.i('Fetched ${users.length}/${userIds.length} users');
      return users;
    } on Exception catch (e, stack) {
      _logger.e('Error fetching users', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch users: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getWorkspaceUsers(String workspaceId) async {
    try {
      _logger.d('Fetching users for workspace: $workspaceId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/admin/workspace/$workspaceId/users',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {users: [...]} or just [...]
        final List<dynamic> usersJson = data is List
            ? data
            : (data['users'] as List<dynamic>? ?? data['data'] as List<dynamic>);

        final users = usersJson
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${users.length} workspace users');
        return users;
      } else {
        _logger.e('Failed to fetch workspace users: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspace users',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspace users', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspace users: ${e.toString()}');
    }
  }
}
```

#### 6. Data Layer - Repository Implementation
**File**: `lib/features/users/data/repositories/user_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/users/data/datasources/user_remote_datasource.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource, this._logger);

  final UserRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: userId -> user
  final Map<String, User> _cachedUsers = {};

  @override
  Future<Result<User>> getUser(String userId) async {
    try {
      // Return cached user if available
      if (_cachedUsers.containsKey(userId)) {
        _logger.d('Returning cached user: $userId');
        return success(_cachedUsers[userId]!);
      }

      final userModel = await _remoteDataSource.getUser(userId);
      final user = userModel.toEntity();

      // Cache the result
      _cachedUsers[userId] = user;

      return success(user);
    } on ServerException catch (e) {
      _logger.e('Server error fetching user', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching user', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching user', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getUsers(List<String> userIds) async {
    try {
      // Separate cached and uncached user IDs
      final cachedUsers = <User>[];
      final uncachedIds = <String>[];

      for (final userId in userIds) {
        if (_cachedUsers.containsKey(userId)) {
          cachedUsers.add(_cachedUsers[userId]!);
        } else {
          uncachedIds.add(userId);
        }
      }

      // Fetch uncached users
      if (uncachedIds.isNotEmpty) {
        _logger.d('Fetching ${uncachedIds.length} uncached users');
        final userModels = await _remoteDataSource.getUsers(uncachedIds);
        final users = userModels.map((model) => model.toEntity()).toList();

        // Cache the results
        for (final user in users) {
          _cachedUsers[user.id] = user;
        }

        cachedUsers.addAll(users);
      }

      return success(cachedUsers);
    } on ServerException catch (e) {
      _logger.e('Server error fetching users', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching users', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching users', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<User>>> getWorkspaceUsers(String workspaceId) async {
    try {
      final userModels = await _remoteDataSource.getWorkspaceUsers(workspaceId);
      final users = userModels.map((model) => model.toEntity()).toList();

      // Cache all workspace users
      for (final user in users) {
        _cachedUsers[user.id] = user;
      }

      return success(users);
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspace users', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspace users', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspace users', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the user cache
  void clearCache() {
    _cachedUsers.clear();
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/users/`
- [ ] Dependency injection generates without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Repository can be injected: verify `getIt<UserRepository>()` works

#### Manual Verification:
- [ ] Cannot test API calls yet (will verify in Phase 5 dashboard integration)
- [ ] Code structure follows workspace/conversation feature patterns
- [ ] User cache strategy prevents redundant API calls

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: Message Feature Implementation

### Overview
Create the message feature module with complete clean architecture layers. This is the most complex feature, including pagination logic using the sequential endpoint. Messages reference users (owners) and belong to conversations.

### Changes Required:

#### 1. Domain Layer - Repository Interface
**File**: `lib/features/messages/domain/repositories/message_repository.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';

/// Repository interface for message operations
abstract class MessageRepository {
  /// Fetches messages for a conversation using sequential pagination
  /// [conversationId] - The conversation/channel ID
  /// [start] - Starting sequence number (0-based)
  /// [count] - Number of messages to fetch
  Future<Result<List<Message>>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  });

  /// Fetches a single message by ID
  Future<Result<Message>> getMessage(String messageId);

  /// Fetches recent messages for a conversation
  /// [conversationId] - The conversation/channel ID
  /// [count] - Number of recent messages to fetch (default: 50)
  Future<Result<List<Message>>> getRecentMessages({
    required String conversationId,
    int count = 50,
  });
}
```

#### 2. Domain Layer - Entity
**File**: `lib/features/messages/domain/entities/message.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

/// Domain entity representing a message
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.createdAt,
    this.text,
    this.transcript,
    this.audioUrl,
    this.duration,
    this.status,
    this.metadata,
  });

  final String id;
  final String conversationId;
  final String userId;
  final DateTime createdAt;
  final String? text;
  final String? transcript;
  final String? audioUrl;
  final Duration? duration;
  final String? status;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userId,
        createdAt,
        text,
        transcript,
        audioUrl,
        duration,
        status,
        metadata,
      ];
}
```

#### 3. Data Layer - Model
**File**: `lib/features/messages/data/models/message_model.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';

/// Data model for message with JSON serialization
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.userId,
    required super.createdAt,
    super.text,
    super.transcript,
    super.audioUrl,
    super.duration,
    super.status,
    super.metadata,
  });

  /// Creates a MessageModel from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? json['messageId'] as String,
      conversationId: json['conversationId'] as String? ??
                      json['conversation_id'] as String? ??
                      json['channelId'] as String? ??
                      json['channel_id'] as String,
      userId: json['userId'] as String? ??
              json['user_id'] as String? ??
              json['ownerId'] as String? ??
              json['owner_id'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : json['date'] != null
                  ? DateTime.parse(json['date'] as String)
                  : DateTime.now(),
      text: json['text'] as String? ?? json['message'] as String?,
      transcript: json['transcript'] as String?,
      audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : json['durationSeconds'] != null
              ? Duration(seconds: json['durationSeconds'] as int)
              : null,
      status: json['status'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts MessageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (text != null) 'text': text,
      if (transcript != null) 'transcript': transcript,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (duration != null) 'duration': duration!.inSeconds,
      if (status != null) 'status': status,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Converts to domain entity
  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      userId: userId,
      createdAt: createdAt,
      text: text,
      transcript: transcript,
      audioUrl: audioUrl,
      duration: duration,
      status: status,
      metadata: metadata,
    );
  }
}
```

#### 4. Data Layer - Remote Data Source Interface
**File**: `lib/features/messages/data/datasources/message_remote_datasource.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/messages/data/models/message_model.dart';

/// Abstract interface for message remote data operations
abstract class MessageRemoteDataSource {
  /// Fetches messages using sequential pagination from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  });

  /// Fetches a single message by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<MessageModel> getMessage(String messageId);

  /// Fetches recent messages from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<MessageModel>> getRecentMessages({
    required String conversationId,
    int count = 50,
  });
}
```

#### 5. Data Layer - Remote Data Source Implementation
**File**: `lib/features/messages/data/datasources/message_remote_datasource_impl.dart`
**Changes**: Create new file

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/data/models/message_model.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRemoteDataSource)
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<MessageModel>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  }) async {
    try {
      final stop = start + count;
      _logger.d('Fetching messages [$start-$stop] for conversation: $conversationId');

      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/messages/$conversationId/sequential/$start/$stop',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {messages: [...]} or just [...]
        final List<dynamic> messagesJson = data is List
            ? data
            : (data['messages'] as List<dynamic>? ?? data['data'] as List<dynamic>);

        final messages = messagesJson
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${messages.length} messages');
        return messages;
      } else {
        _logger.e('Failed to fetch messages: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch messages',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching messages', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch messages: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> getMessage(String messageId) async {
    try {
      _logger.d('Fetching message: $messageId');

      // Try v5 endpoint first, fallback to v4
      var response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v5/messages/$messageId',
      );

      if (response.statusCode == 404) {
        _logger.d('Message not found in v5, trying v4');
        response = await _httpService.get(
          '${OAuthConfig.apiBaseUrl}/v4/messages/$messageId',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromJson(data as Map<String, dynamic>);
        _logger.i('Fetched message: ${message.id}');
        return message;
      } else {
        _logger.e('Failed to fetch message: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch message',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching message', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch message: ${e.toString()}');
    }
  }

  @override
  Future<List<MessageModel>> getRecentMessages({
    required String conversationId,
    int count = 50,
  }) async {
    try {
      _logger.d('Fetching $count recent messages for conversation: $conversationId');

      final response = await _httpService.post(
        '${OAuthConfig.apiBaseUrl}/v3/messages/recent',
        body: {
          'channelId': conversationId,
          'count': count,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API might return {messages: [...]} or just [...]
        final List<dynamic> messagesJson = data is List
            ? data
            : (data['messages'] as List<dynamic>? ?? data['data'] as List<dynamic>);

        final messages = messagesJson
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();

        _logger.i('Fetched ${messages.length} recent messages');
        return messages;
      } else {
        _logger.e('Failed to fetch recent messages: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch recent messages',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching recent messages', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch recent messages: ${e.toString()}');
    }
  }
}
```

#### 6. Data Layer - Repository Implementation
**File**: `lib/features/messages/data/repositories/message_repository_impl.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: MessageRepository)
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remoteDataSource, this._logger);

  final MessageRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache: conversationId -> messages (ordered)
  final Map<String, List<Message>> _cachedMessages = {};

  // Track loaded ranges per conversation: conversationId -> Set<(start, stop)>
  final Map<String, Set<String>> _loadedRanges = {};

  @override
  Future<Result<List<Message>>> getMessages({
    required String conversationId,
    required int start,
    required int count,
  }) async {
    try {
      final stop = start + count;
      final rangeKey = '$start-$stop';

      // Check if we already loaded this range
      if (_loadedRanges[conversationId]?.contains(rangeKey) ?? false) {
        _logger.d('Returning cached messages for range $rangeKey');
        final cached = _cachedMessages[conversationId] ?? [];
        return success(cached.where((m) {
          // Filter messages in the requested range
          // This is a simple filter; you may need sequence numbers from API
          return true; // For now, return all cached
        }).toList());
      }

      final messageModels = await _remoteDataSource.getMessages(
        conversationId: conversationId,
        start: start,
        count: count,
      );

      final messages = messageModels.map((model) => model.toEntity()).toList();

      // Merge with cache, removing duplicates
      final existingMessages = _cachedMessages[conversationId] ?? [];
      final allMessages = <Message>[...existingMessages];

      for (final message in messages) {
        if (!allMessages.any((m) => m.id == message.id)) {
          allMessages.add(message);
        }
      }

      // Sort by date (newest first)
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the result
      _cachedMessages[conversationId] = allMessages;
      _loadedRanges.putIfAbsent(conversationId, () => {}).add(rangeKey);

      return success(messages);
    } on ServerException catch (e) {
      _logger.e('Server error fetching messages', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching messages', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching messages', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Message>> getMessage(String messageId) async {
    try {
      // Check cache across all conversations
      for (final messages in _cachedMessages.values) {
        final cached = messages.where((m) => m.id == messageId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached message: $messageId');
          return success(cached);
        }
      }

      final messageModel = await _remoteDataSource.getMessage(messageId);
      final message = messageModel.toEntity();

      // Add to cache for the conversation
      final existingMessages = _cachedMessages[message.conversationId] ?? [];
      if (!existingMessages.any((m) => m.id == message.id)) {
        existingMessages.add(message);
        existingMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cachedMessages[message.conversationId] = existingMessages;
      }

      return success(message);
    } on ServerException catch (e) {
      _logger.e('Server error fetching message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching message', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching message', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<List<Message>>> getRecentMessages({
    required String conversationId,
    int count = 50,
  }) async {
    try {
      final messageModels = await _remoteDataSource.getRecentMessages(
        conversationId: conversationId,
        count: count,
      );

      final messages = messageModels.map((model) => model.toEntity()).toList();

      // Replace cache with recent messages
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cachedMessages[conversationId] = messages;
      _loadedRanges.remove(conversationId); // Clear range tracking

      return success(messages);
    } on ServerException catch (e) {
      _logger.e('Server error fetching recent messages', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching recent messages', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching recent messages', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears message cache for a specific conversation
  void clearCacheForConversation(String conversationId) {
    _cachedMessages.remove(conversationId);
    _loadedRanges.remove(conversationId);
  }

  /// Clears all message cache
  void clearCache() {
    _cachedMessages.clear();
    _loadedRanges.clear();
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/messages/`
- [ ] Dependency injection generates without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Repository can be injected: verify `getIt<MessageRepository>()` works

#### Manual Verification:
- [ ] Cannot test API calls yet (will verify in Phase 5 dashboard integration)
- [ ] Code structure follows other feature patterns
- [ ] Pagination logic correctly handles sequential ranges

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Dashboard BLoC Implementation

### Overview
Create the dashboard BLoC that orchestrates data fetching from all four repositories (workspaces, conversations, messages, users). This implements the auto-load flow: workspaces → auto-select first → conversations → auto-select first → messages.

### Changes Required:

#### 1. BLoC - Events
**File**: `lib/features/dashboard/presentation/bloc/dashboard_event.dart`
**Changes**: Create new file

```dart
import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when dashboard screen is loaded
class DashboardLoaded extends DashboardEvent {
  const DashboardLoaded();
}

/// Triggered when user selects a different workspace
class WorkspaceSelected extends DashboardEvent {
  const WorkspaceSelected(this.workspaceId);

  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}

/// Triggered when user selects a different conversation
class ConversationSelected extends DashboardEvent {
  const ConversationSelected(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Triggered when user wants to load more messages (pagination)
class LoadMoreMessages extends DashboardEvent {
  const LoadMoreMessages();
}

/// Triggered when user wants to refresh data
class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}
```

#### 2. BLoC - States
**File**: `lib/features/dashboard/presentation/bloc/dashboard_state.dart`
**Changes**: Create new file

```dart
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:equatable/equatable.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Loading initial dashboard data
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard data loaded successfully
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.workspaces,
    required this.selectedWorkspace,
    required this.conversations,
    required this.selectedConversation,
    required this.messages,
    required this.users,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  });

  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final List<Conversation> conversations;
  final Conversation? selectedConversation;
  final List<Message> messages;
  final Map<String, User> users; // userId -> User
  final bool isLoadingMore;
  final bool hasMoreMessages;

  @override
  List<Object?> get props => [
        workspaces,
        selectedWorkspace,
        conversations,
        selectedConversation,
        messages,
        users,
        isLoadingMore,
        hasMoreMessages,
      ];

  DashboardLoaded copyWith({
    List<Workspace>? workspaces,
    Workspace? selectedWorkspace,
    List<Conversation>? conversations,
    Conversation? selectedConversation,
    List<Message>? messages,
    Map<String, User>? users,
    bool? isLoadingMore,
    bool? hasMoreMessages,
  }) {
    return DashboardLoaded(
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspace: selectedWorkspace ?? this.selectedWorkspace,
      conversations: conversations ?? this.conversations,
      selectedConversation: selectedConversation ?? this.selectedConversation,
      messages: messages ?? this.messages,
      users: users ?? this.users,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
    );
  }
}

/// Error occurred while loading dashboard data
class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

#### 3. BLoC - Implementation
**File**: `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`
**Changes**: Create new file

```dart
import 'package:bloc/bloc.dart';
import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(
    this._workspaceRepository,
    this._conversationRepository,
    this._messageRepository,
    this._userRepository,
    this._logger,
  ) : super(const DashboardInitial()) {
    on<DashboardLoaded>(_onDashboardLoaded);
    on<WorkspaceSelected>(_onWorkspaceSelected);
    on<ConversationSelected>(_onConversationSelected);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<DashboardRefreshed>(_onDashboardRefreshed);
  }

  final WorkspaceRepository _workspaceRepository;
  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final Logger _logger;

  static const int _messagesPerPage = 50;
  int _currentMessageStart = 0;

  Future<void> _onDashboardLoaded(
    DashboardLoaded event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      // Step 1: Load workspaces
      final workspacesResult = await _workspaceRepository.getWorkspaces();

      await workspacesResult.fold(
        onSuccess: (workspaces) async {
          if (workspaces.isEmpty) {
            emit(const DashboardError('No workspaces found'));
            return;
          }

          // Step 2: Auto-select first workspace
          final selectedWorkspace = workspaces.first;
          _logger.i('Auto-selected workspace: ${selectedWorkspace.name}');

          // Step 3: Load conversations for selected workspace
          final conversationsResult = await _conversationRepository.getConversations(
            selectedWorkspace.id,
          );

          await conversationsResult.fold(
            onSuccess: (conversations) async {
              if (conversations.isEmpty) {
                emit(DashboardLoaded(
                  workspaces: workspaces,
                  selectedWorkspace: selectedWorkspace,
                  conversations: [],
                  selectedConversation: null,
                  messages: [],
                  users: {},
                ));
                return;
              }

              // Step 4: Auto-select first conversation
              final selectedConversation = conversations.first;
              _logger.i('Auto-selected conversation: ${selectedConversation.name}');

              // Step 5: Load recent messages
              _currentMessageStart = 0;
              final messagesResult = await _messageRepository.getRecentMessages(
                conversationId: selectedConversation.id,
                count: _messagesPerPage,
              );

              await messagesResult.fold(
                onSuccess: (messages) async {
                  // Step 6: Load users for messages
                  final userIds = messages.map((m) => m.userId).toSet().toList();
                  final usersResult = await _userRepository.getUsers(userIds);

                  usersResult.fold(
                    onSuccess: (users) {
                      final userMap = {for (var u in users) u.id: u};

                      emit(DashboardLoaded(
                        workspaces: workspaces,
                        selectedWorkspace: selectedWorkspace,
                        conversations: conversations,
                        selectedConversation: selectedConversation,
                        messages: messages,
                        users: userMap,
                      ));
                    },
                    onFailure: (failure) {
                      // Still show messages even if user loading fails
                      _logger.w('Failed to load users: ${failure.failure}');
                      emit(DashboardLoaded(
                        workspaces: workspaces,
                        selectedWorkspace: selectedWorkspace,
                        conversations: conversations,
                        selectedConversation: selectedConversation,
                        messages: messages,
                        users: {},
                      ));
                    },
                  );
                },
                onFailure: (failure) {
                  emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
                },
              );
            },
            onFailure: (failure) {
              emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
            },
          );
        },
        onFailure: (failure) {
          emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
        },
      );
    } on Exception catch (e, stack) {
      _logger.e('Error loading dashboard', error: e, stackTrace: stack);
      emit(DashboardError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onWorkspaceSelected(
    WorkspaceSelected event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final selectedWorkspace = currentState.workspaces
        .where((w) => w.id == event.workspaceId)
        .firstOrNull;

    if (selectedWorkspace == null) return;

    emit(currentState.copyWith(
      selectedWorkspace: selectedWorkspace,
      conversations: [],
      selectedConversation: null,
      messages: [],
      users: {},
    ));

    // Load conversations for new workspace
    final conversationsResult = await _conversationRepository.getConversations(
      selectedWorkspace.id,
    );

    conversationsResult.fold(
      onSuccess: (conversations) async {
        if (conversations.isEmpty) {
          emit(currentState.copyWith(
            selectedWorkspace: selectedWorkspace,
            conversations: [],
            selectedConversation: null,
            messages: [],
            users: {},
          ));
          return;
        }

        final selectedConversation = conversations.first;
        _currentMessageStart = 0;

        // Load messages for first conversation
        final messagesResult = await _messageRepository.getRecentMessages(
          conversationId: selectedConversation.id,
          count: _messagesPerPage,
        );

        messagesResult.fold(
          onSuccess: (messages) async {
            // Load users
            final userIds = messages.map((m) => m.userId).toSet().toList();
            final usersResult = await _userRepository.getUsers(userIds);

            usersResult.fold(
              onSuccess: (users) {
                final userMap = {for (var u in users) u.id: u};
                emit(currentState.copyWith(
                  selectedWorkspace: selectedWorkspace,
                  conversations: conversations,
                  selectedConversation: selectedConversation,
                  messages: messages,
                  users: userMap,
                ));
              },
              onFailure: (_) {
                emit(currentState.copyWith(
                  selectedWorkspace: selectedWorkspace,
                  conversations: conversations,
                  selectedConversation: selectedConversation,
                  messages: messages,
                  users: {},
                ));
              },
            );
          },
          onFailure: (failure) {
            emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
          },
        );
      },
      onFailure: (failure) {
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onConversationSelected(
    ConversationSelected event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final selectedConversation = currentState.conversations
        .where((c) => c.id == event.conversationId)
        .firstOrNull;

    if (selectedConversation == null) return;

    _currentMessageStart = 0;

    // Load messages for selected conversation
    final messagesResult = await _messageRepository.getRecentMessages(
      conversationId: selectedConversation.id,
      count: _messagesPerPage,
    );

    messagesResult.fold(
      onSuccess: (messages) async {
        // Load users
        final userIds = messages.map((m) => m.userId).toSet().toList();
        final usersResult = await _userRepository.getUsers(userIds);

        usersResult.fold(
          onSuccess: (users) {
            final userMap = {for (var u in users) u.id: u};
            emit(currentState.copyWith(
              selectedConversation: selectedConversation,
              messages: messages,
              users: userMap,
            ));
          },
          onFailure: (_) {
            emit(currentState.copyWith(
              selectedConversation: selectedConversation,
              messages: messages,
              users: {},
            ));
          },
        );
      },
      onFailure: (failure) {
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;
    if (currentState.selectedConversation == null) return;
    if (currentState.isLoadingMore || !currentState.hasMoreMessages) return;

    emit(currentState.copyWith(isLoadingMore: true));

    _currentMessageStart += _messagesPerPage;

    final messagesResult = await _messageRepository.getMessages(
      conversationId: currentState.selectedConversation!.id,
      start: _currentMessageStart,
      count: _messagesPerPage,
    );

    messagesResult.fold(
      onSuccess: (newMessages) async {
        if (newMessages.isEmpty) {
          emit(currentState.copyWith(
            isLoadingMore: false,
            hasMoreMessages: false,
          ));
          return;
        }

        // Merge with existing messages
        final allMessages = [...currentState.messages, ...newMessages];

        // Load new users
        final newUserIds = newMessages.map((m) => m.userId).toSet().toList();
        final usersResult = await _userRepository.getUsers(newUserIds);

        usersResult.fold(
          onSuccess: (newUsers) {
            final userMap = Map<String, User>.from(currentState.users);
            for (final user in newUsers) {
              userMap[user.id] = user;
            }

            emit(currentState.copyWith(
              messages: allMessages,
              users: userMap,
              isLoadingMore: false,
              hasMoreMessages: newMessages.length == _messagesPerPage,
            ));
          },
          onFailure: (_) {
            emit(currentState.copyWith(
              messages: allMessages,
              isLoadingMore: false,
              hasMoreMessages: newMessages.length == _messagesPerPage,
            ));
          },
        );
      },
      onFailure: (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(DashboardError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onDashboardRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    // Clear all caches and reload
    _currentMessageStart = 0;
    add(const DashboardLoaded());
  }
}
```

#### 4. Remove .gitkeep file
**File**: `lib/features/dashboard/bloc/.gitkeep`
**Changes**: Delete this file (no longer needed)

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/dashboard/presentation/bloc/`
- [ ] Dependency injection generates without errors: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] BLoC can be injected: verify `getIt<DashboardBloc>()` works

#### Manual Verification:
- [ ] Cannot test full flow yet (will verify in Phase 6 UI integration)
- [ ] BLoC follows auth BLoC pattern
- [ ] Event handlers correctly orchestrate repository calls

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Dashboard UI Integration

### Overview
Integrate the dashboard BLoC with the existing dashboard UI, replacing dummy data with real API data. Update UI to use BLoC states and dispatch events for user interactions.

### Changes Required:

#### 1. Update Dashboard Screen
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
**Changes**: Replace entire file content

```dart
import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/message_card.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(const DashboardLoaded()),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatefulWidget {
  const _DashboardScreenContent();

  @override
  State<_DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<_DashboardScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedMessages = {};
  bool _selectAll = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // Near bottom, load more
      context.read<DashboardBloc>().add(const LoadMoreMessages());
    }
  }

  void _toggleSelectAll(bool? value, int messageCount) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        final state = context.read<DashboardBloc>().state;
        if (state is DashboardLoaded) {
          _selectedMessages.addAll(state.messages.map((m) => m.id));
        }
      } else {
        _selectedMessages.clear();
      }
    });
  }

  void _toggleMessageSelection(String messageId, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedMessages.add(messageId);
      } else {
        _selectedMessages.remove(messageId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              Column(
                children: [
                  // App Bar
                  _buildAppBar(context, state),

                  // Table Header
                  if (state is DashboardLoaded && state.messages.isNotEmpty)
                    _buildTableHeader(context, state),

                  // Content
                  Expanded(
                    child: _buildContent(context, state),
                  ),
                ],
              ),

              // Floating Action Panel
              if (_selectedMessages.isNotEmpty)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MessagesActionPanel(
                      selectedCount: _selectedMessages.length,
                      onDownload: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${_selectedMessages.length} messages...'),
                          ),
                        );
                      },
                      onSummarize: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Summarizing ${_selectedMessages.length} messages...'),
                          ),
                        );
                      },
                      onAIChat: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening AI chat for ${_selectedMessages.length} messages...'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, DashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Audio Messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(width: 32),

          // Workspace Dropdown
          if (state is DashboardLoaded && state.workspaces.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: state.selectedWorkspace?.id,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.arrow_drop_down),
                items: state.workspaces.map((workspace) {
                  return DropdownMenuItem<String>(
                    value: workspace.id,
                    child: Text(workspace.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    context.read<DashboardBloc>().add(WorkspaceSelected(newValue));
                    setState(() {
                      _selectedMessages.clear();
                      _selectAll = false;
                    });
                  }
                },
              ),
            ),

          const SizedBox(width: 16),

          // Search Field (Conversation ID search - not implemented yet)
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Conversation ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Conversation Name Display
          if (state is DashboardLoaded && state.selectedConversation != null)
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      state.selectedConversation!.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Refresh button
          if (state is DashboardLoaded)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<DashboardBloc>().add(const DashboardRefreshed());
                setState(() {
                  _selectedMessages.clear();
                  _selectAll = false;
                });
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            // Select All Checkbox
            Checkbox(
              value: _selectAll,
              onChanged: (value) => _toggleSelectAll(value, state.messages.length),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(width: 8),

            // Headers
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(Icons.arrow_upward, size: 16),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 140,
              child: Text(
                'Owner',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                'Message',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 16),
            const SizedBox(width: 60), // AI Action space
            const SizedBox(width: 16),

            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    'Dur',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(Icons.unfold_more, size: 16),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 90,
              child: Text(
                'Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 56), // Menu space
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<DashboardBloc>().add(const DashboardLoaded()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      if (state.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'No messages',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('No messages found in this conversation'),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messages.length) {
              // Loading more indicator
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final message = state.messages[index];
            final user = state.users[message.userId];

            // Convert domain entities to legacy AudioMessage format for MessageCard
            // TODO: Refactor MessageCard to accept domain entities directly
            final legacyMessage = _convertToLegacyMessage(message, user);

            return MessageCard(
              message: legacyMessage,
              isSelected: _selectedMessages.contains(message.id),
              onSelected: (value) => _toggleMessageSelection(message.id, value),
            );
          },
        ),
      );
    }

    return const Center(child: Text('Unknown state'));
  }

  // Temporary converter - should refactor MessageCard to use domain entities
  dynamic _convertToLegacyMessage(dynamic message, dynamic user) {
    // This is a hack to make the existing MessageCard work
    // In a real refactor, MessageCard should accept Message and User entities
    return _LegacyAudioMessage(
      id: message.id,
      date: message.createdAt,
      owner: user?.name ?? 'Unknown User',
      message: message.text ?? message.transcript ?? 'No content',
      duration: message.duration ?? Duration.zero,
      status: message.status ?? 'Unknown',
      project: '', // Not available in Message entity
    );
  }
}

// Temporary class to match existing AudioMessage interface
class _LegacyAudioMessage {
  _LegacyAudioMessage({
    required this.id,
    required this.date,
    required this.owner,
    required this.message,
    required this.duration,
    required this.status,
    required this.project,
  });

  final String id;
  final DateTime date;
  final String owner;
  final String message;
  final Duration duration;
  final String status;
  final String project;
}
```

#### 2. Update Main App to Provide DashboardBloc
**File**: `lib/main.dart`
**Changes**: Add DashboardBloc to BlocProvider if not already present

```dart
// Find the MultiBlocProvider section and add DashboardBloc
// This change assumes there's already a MultiBlocProvider wrapping the app
// If the structure is different, adapt accordingly

// Before:
// MultiBlocProvider(
//   providers: [
//     BlocProvider(create: (_) => getIt<AuthBloc>()..add(const AppStarted())),
//   ],
//   ...
// )

// After:
// MultiBlocProvider(
//   providers: [
//     BlocProvider(create: (_) => getIt<AuthBloc>()..add(const AppStarted())),
//     // Note: DashboardBloc is now created locally in DashboardScreen
//     // No need to provide it here
//   ],
//   ...
// )
```

**Note**: Based on the BLoC pattern in the codebase, DashboardBloc is created locally in DashboardScreen, so no change to `main.dart` is needed.

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No linting issues: `flutter analyze lib/features/dashboard/`
- [ ] App builds successfully: `flutter build web` (or target platform)

#### Manual Verification:
- [ ] Dashboard screen loads without errors
- [ ] Workspace dropdown shows real workspaces from API
- [ ] First workspace is auto-selected
- [ ] Conversation name displays correctly
- [ ] Messages list shows real messages from API
- [ ] User names display correctly (from user repository)
- [ ] Scroll pagination works (loading more messages)
- [ ] Workspace switching works
- [ ] Refresh button reloads all data
- [ ] Error states display correctly
- [ ] Loading states display correctly

**Implementation Note**: This is the final phase. After completing and verifying both automated and manual success criteria, the dashboard data layer implementation is complete. The dashboard now displays real data from the CarbonVoice API with working pagination.

---

## Testing Strategy

### Unit Tests
Not included in this implementation plan. Can be added in a follow-up phase if needed.

### Integration Tests
Not included in this implementation plan. Can be added in a follow-up phase if needed.

### Manual Testing Steps

**After Phase 6 completion:**

1. **Workspace Loading**:
   - Open the dashboard
   - Verify workspaces load from API
   - Verify first workspace is auto-selected
   - Try switching workspaces manually

2. **Conversation Loading**:
   - Verify conversations load for selected workspace
   - Verify first conversation is auto-selected
   - Verify conversation name displays in header

3. **Message Loading**:
   - Verify messages load for selected conversation
   - Verify message content displays correctly
   - Verify user names display correctly
   - Scroll to bottom and verify pagination loads more messages

4. **Error Handling**:
   - Disconnect network and verify error state
   - Reconnect and retry
   - Verify error messages are user-friendly

5. **Performance**:
   - Verify initial load is reasonably fast
   - Verify pagination doesn't cause UI lag
   - Verify workspace/conversation switching is responsive

## Performance Considerations

- **In-memory caching**: All repositories implement in-memory caching to reduce API calls
- **Batch user fetching**: Users are fetched in batches to minimize API requests
- **Pagination**: Messages use sequential pagination to avoid loading all messages at once
- **Lazy loading**: Messages load more as user scrolls (infinite scroll pattern)

## Migration Notes

### Data Migration
No data migration needed (read-only implementation).

### Code Migration
- Existing `AudioMessage` model in `lib/features/dashboard/models/audio_message.dart` is deprecated but kept for backward compatibility
- `DashboardScreen` is completely rewritten but maintains the same UI structure
- No breaking changes to other parts of the application

## References

- API Documentation: https://api.carbonvoice.app/docs
- OAuth Configuration: `lib/core/config/oauth_config.dart:1`
- Clean Architecture Reference (Auth): `lib/features/auth/`
- Result Pattern: `lib/core/utils/result.dart:1`
- Failure Types: `lib/core/errors/failures.dart:1`
- Authenticated HTTP Service: `lib/core/network/authenticated_http_service.dart:8`
