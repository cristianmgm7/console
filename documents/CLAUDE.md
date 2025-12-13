# CLAUDE.md - Context for AI Code Agent Tasks

This document provides comprehensive context about the Carbon Voice Console project to help AI agents understand the codebase structure, patterns, and conventions.

## Project Overview

**Carbon Voice Console** is a Flutter admin console application for managing Carbon Voice services. It's a multi-platform application (macOS, iOS, Android, Web) built with clean architecture principles and modern Flutter best practices.

**Current Version:** 1.0.0+1
**Status:** Phase 1 Complete ✅ | OAuth 2.0 Complete ✅ | Preview Feature Complete ✅ | UI Refactor Complete ✅

## Tech Stack

### Core Technologies
- **Flutter:** 3.35.6 (stable) - Cross-platform UI framework
- **Dart:** 3.9.2 - Programming language
- **SDK:** ^3.8.0

### Key Dependencies

#### State Management & Architecture
- **flutter_bloc:** ^8.1.6 - BLoC pattern for state management
- **equatable:** ^2.0.7 - Value equality for Dart objects
- **meta:** ^1.13.0 - Annotations for static analysis

#### Dependency Injection
- **get_it:** ^8.0.2 - Service locator
- **injectable:** ^2.5.0 - Code generation for dependency injection
- **injectable_generator:** ^2.6.2 (dev) - Code generator

#### Routing
- **go_router:** ^14.6.2 - Declarative routing

#### Networking & HTTP
- **dio:** ^5.7.0 - HTTP client with interceptors
- **http:** ^1.2.0 - Alternative HTTP client

#### OAuth & Authentication
- **oauth2:** ^2.0.2 - OAuth 2.0 implementation
- **crypto:** ^3.0.5 - Cryptographic functions (PKCE)
- **flutter_secure_storage:** ^9.2.4 - Secure token storage
- **url_launcher:** ^6.3.2 - Launch OAuth URLs

#### JSON & Serialization
- **json_annotation:** ^4.9.0 - JSON serialization annotations
- **json_serializable:** ^6.8.0 (dev) - JSON code generation

#### Audio
- **just_audio:** ^0.9.40 - Audio playback

#### UI & Design
- **google_fonts:** ^6.1.0 - DM Sans font family (design system)
- **phosphor_flutter:** ^2.1.0 - Phosphor icon library (67+ icons)

#### Utilities
- **logger:** ^2.6.2 - Logging
- **path_provider:** ^2.1.1 - File system paths
- **path:** ^1.9.0 - Path manipulation
- **universal_html:** ^2.2.4 - Platform-specific implementations
- **uuid:** ^4.5.1 - UUID generation

#### Development Tools
- **build_runner:** ^2.4.13 - Code generation
- **very_good_analysis:** ^10.0.0 - Lint rules
- **flutter_lints:** ^5.0.0 - Flutter linting

## Project Structure

```
lib/
  ├── main.dart                 # App entry point with BLoC providers
  ├── core/                     # Core functionality (shared across features)
  │   ├── config/              # Configuration (OAuth, environment)
  │   ├── di/                  # Dependency injection setup (GetIt + Injectable)
  │   │   ├── injection.dart
  │   │   ├── injection.config.dart  # Generated
  │   │   └── register_module.dart
  │   ├── routing/             # App navigation (go_router)
  │   │   ├── app_router.dart
  │   │   ├── app_routes.dart
  │   │   ├── app_shell.dart
  │   │   └── presentation/
  │   ├── errors/              # Error handling
  │   │   ├── failures.dart
  │   │   └── exceptions.dart
  │   ├── utils/               # Utilities
  │   │   ├── result.dart           # Result<T> type for error handling
  │   │   ├── failure_mapper.dart   # Maps failures to user messages
  │   │   ├── json_normalizer.dart  # API field normalization
  │   │   ├── pkce_generator.dart   # OAuth PKCE
  │   │   └── oauth_desktop_server.dart
  │   ├── network/             # HTTP layer
  │   │   └── authenticated_http_service.dart
  │   ├── providers/           # BLoC providers
  │   │   └── bloc_providers.dart
  │   ├── models/              # Shared models
  │   ├── services/            # Core services
  │   │   └── deep_linking_service.dart  # Deep linking handler
  │   ├── theme/               # Design system (Soft Modernism)
  │   │   ├── app_colors.dart         # Color palette
  │   │   ├── app_text_styles.dart    # DM Sans typography
  │   │   ├── app_icons.dart          # Phosphor icon library
  │   │   ├── app_borders.dart        # Border radius system
  │   │   ├── app_shadows.dart        # Shadow system
  │   │   ├── app_animations.dart     # Animation constants
  │   │   ├── app_gradients.dart      # Mesh gradients
  │   │   └── app_dimensions.dart     # Spacing system
  │   ├── widgets/             # Reusable themed widgets (17 components)
  │   │   ├── buttons/               # AppButton, AppOutlinedButton, etc.
  │   │   ├── cards/                 # AppCard, GlassCard, etc.
  │   │   ├── containers/            # GlassContainer, AppPillContainer
  │   │   ├── interactive/           # AppCheckbox, AppSwitch, AppTextField
  │   │   └── app_table.dart         # Table component
  │   ├── common/              # Legacy shared widgets (being phased out)
  │   └── web/                 # Web-specific code
  │
  ├── dtos/                    # Shared DTOs and mappers
  │   ├── user_profile_dto.dart      # User profile DTO
  │   └── mappers/                   # DTO mappers
  │
  └── features/                # Feature modules (clean architecture)
      ├── auth/                # OAuth 2.0 Authentication
      │   ├── domain/         # Business logic layer
      │   │   ├── entities/
      │   │   ├── repositories/
      │   │   └── usecases/
      │   ├── data/           # Data layer
      │   │   ├── datasources/
      │   │   ├── models/
      │   │   └── repositories/
      │   ├── infrastructure/ # Infrastructure services
      │   │   └── services/
      │   └── presentation/   # UI layer
      │       ├── bloc/
      │       └── pages/
      │
      ├── dashboard/           # Dashboard feature
      ├── users/               # User management
      ├── workspaces/          # Workspace management
      ├── conversations/       # Conversation management
      ├── messages/            # Message management (3 presentation modules)
      │   ├── domain/
      │   ├── data/
      │   ├── presentation_messages_dashboard/  # Main inbox view
      │   ├── presentation_messages_detail/     # Message detail views
      │   └── presentation_send_message/        # Message composition
      ├── message_download/    # Message download feature (audio + transcripts)
      ├── preview/             # Public conversation preview feature ⭐ NEW
      │   ├── domain/         # PreviewComposerData, ConversationPreview
      │   ├── data/           # Repository implementation
      │   ├── presentation/   # Composer & confirmation screens
      │   └── widgets/        # Chat messages, statistics, participants
      ├── audio_player/        # Audio playback
      ├── voice_memos/         # Voice memos
      └── settings/            # Settings

documents/                    # Documentation and guides
  ├── CLAUDE.md              # This file
  ├── DISTRIBUTION_README.md
  ├── GATEKEEPER_FIX_SUMMARY.md
  ├── KEYCHAIN_FIX.md
  ├── OAUTH_DMG_SETUP.md
  ├── QUICK_START_DMG.md
  └── TESTER_INSTRUCTIONS.md

scripts/                      # Build and development scripts
  ├── build_macos_release.sh
  ├── create_dmg.sh
  ├── run_dev.sh
  ├── run_web_with_ngrok.sh
  └── ... (more scripts)

.claude/                      # Claude AI integration
  ├── agents/                # Custom AI agents
  ├── commands/              # Slash commands
  └── skills/                # AI skills (build-desktop-web-ui-components)
```

### Feature Structure (Clean Architecture)

Each feature follows the clean architecture pattern:

```
feature_name/
  ├── domain/                  # Business logic (pure Dart)
  │   ├── entities/           # Domain models
  │   ├── repositories/       # Abstract repository interfaces
  │   └── usecases/           # Business use cases
  │
  ├── data/                   # Data layer
  │   ├── datasources/        # Remote/local data sources
  │   ├── models/             # DTOs (Data Transfer Objects)
  │   ├── mappers/            # DTO ↔ Entity mappers
  │   └── repositories/       # Repository implementations
  │
  ├── infrastructure/         # Infrastructure services (optional)
  │   └── services/
  │
  └── presentation/           # UI layer
      ├── bloc/               # BLoC (Business Logic Component)
      │   ├── feature_bloc.dart
      │   ├── feature_event.dart
      │   └── feature_state.dart
      ├── pages/              # Screen widgets
      └── widgets/            # Feature-specific widgets
```

## Design System

### "Soft Modernism" / "Ethereal Tech" Design Language

The application follows a professional, polished design language with these characteristics:

**Visual Principles:**
- Glassmorphism effects with backdrop blur
- Soft mesh gradients (e.g., "darkAura")
- Geometric typography using DM Sans
- Subtle shadows and borders
- Pill-shaped elements (rounded corners)
- Professional spacing and hierarchy

**Color System** ([app_colors.dart](lib/core/theme/app_colors.dart)):
- Semantic color naming (primary, secondary, accent, etc.)
- Background gradients and surface colors
- Status colors (success, warning, error, info)
- Text colors with opacity variants
- Glass effect colors

**Typography** ([app_text_styles.dart](lib/core/theme/app_text_styles.dart)):
- DM Sans font family (via google_fonts)
- Display, heading, title, body, label, caption variants
- Consistent font weights and sizes
- Line height optimization

**Icon System** ([app_icons.dart](lib/core/theme/app_icons.dart)):
- 67+ Phosphor icons organized by category:
  - Navigation (house, user, gear, etc.)
  - Communication (chat, envelope, phone, etc.)
  - Media (play, pause, microphone, etc.)
  - Actions (plus, minus, trash, etc.)
  - Status (check, warning, info, etc.)
- Consistent sizing and visual weight

### Widget Library (17 Components)

Comprehensive themed widget library in [lib/core/widgets/](lib/core/widgets/). See [docs/WIDGET_LIBRARY.md](docs/WIDGET_LIBRARY.md) for complete documentation.

**Buttons** (5 components):
- `AppButton` - Primary filled button
- `AppOutlinedButton` - Secondary outlined button
- `AppTextButton` - Minimal text button
- `AppIconButton` - Circular icon button
- `MessagePlayButton` - Specialized audio play button

**Cards** (4 components):
- `AppCard` - Standard card with shadow
- `AppOutlinedCard` - Bordered card
- `AppInteractiveCard` - Clickable card with hover effects
- `GlassCard` - Glassmorphism card with backdrop blur

**Containers** (3 components):
- `AppContainer` - Basic themed container
- `GlassContainer` - Glassmorphism with backdrop blur
- `AppPillContainer` - Pill-shaped tags/chips

**Interactive** (4 components):
- `AppCheckbox` - Themed checkbox
- `AppSwitch` - Themed toggle switch
- `AppDropdown` - Themed dropdown selector
- `AppTextField` - Themed text input

**Others**:
- `AppProgressIndicator` - Circular/linear progress
- `AppTable` - Data table component
- `AppEmptyState` - Empty state display

**Benefits:**
- ~40% code reduction in refactored files
- Consistent design across all screens
- DRY principle applied
- Type-safe APIs
- Easy to maintain and extend

## Architecture Patterns

### 1. Clean Architecture

The project follows clean architecture with clear separation:
- **Domain Layer**: Pure business logic (entities, repositories, use cases)
- **Data Layer**: Data sources, DTOs, repository implementations
- **Presentation Layer**: UI, BLoC, widgets

**Dependencies flow inward**: Presentation → Data → Domain

### 2. BLoC Pattern

State management uses the BLoC pattern:
- **Events**: User actions or external triggers
- **States**: UI states (loading, loaded, error, etc.)
- **BLoC**: Business logic that transforms events into states

Example BLoC structure:
```dart
@LazySingleton()
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  FeatureBloc(this._repository) : super(const FeatureInitial()) {
    on<EventName>(_onEventName);
  }

  final Repository _repository;

  Future<void> _onEventName(
    EventName event,
    Emitter<FeatureState> emit,
  ) async {
    emit(const FeatureLoading());

    final result = await _repository.method();
    result.fold(
      onSuccess: (data) => emit(FeatureLoaded(data)),
      onFailure: (failure) => emit(FeatureError(failure.message)),
    );
  }
}
```

### 3. Dependency Injection

Uses **GetIt** with **Injectable** for automatic DI:
- Mark classes with `@injectable`, `@lazySingleton`, `@singleton`
- Run `flutter pub run build_runner build` to generate DI code
- Access via `getIt<Type>()`

Example:
```dart
@LazySingleton(as: Repository)
class RepositoryImpl implements Repository {
  RepositoryImpl(this._dataSource, this._logger);

  final DataSource _dataSource;
  final Logger _logger;
  // ...
}
```

### 4. Result Type

Type-safe error handling using sealed `Result<T>` type:

```dart
sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure<T> failure) onFailure,
  });
}

final class Success<T> extends Result<T> { /* ... */ }
final class Failure<T> extends Result<T> { /* ... */ }
```

Usage:
```dart
Future<Result<User>> getUser(String id) async {
  try {
    final user = await _dataSource.getUser(id);
    return success(user);
  } on ServerException catch (e) {
    return failure(ServerFailure(statusCode: e.statusCode));
  }
}

// In BLoC
final result = await _repository.getUser(id);
result.fold(
  onSuccess: (user) => emit(UserLoaded(user)),
  onFailure: (failure) => emit(UserError(failure.message)),
);
```

### 5. Error Handling

Three-layer error handling:

**1. Exceptions (Data Layer):**
```dart
class ServerException implements Exception {
  ServerException({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

class NetworkException implements Exception { /* ... */ }
```

**2. Failures (Domain Layer):**
```dart
sealed class AppFailure extends Equatable {
  const AppFailure({this.details});
  final String? details;
}

class ServerFailure extends AppFailure { /* ... */ }
class NetworkFailure extends AppFailure { /* ... */ }
class UnknownFailure extends AppFailure { /* ... */ }
```

**3. User Messages (Presentation Layer):**
```dart
// FailureMapper converts failures to user-friendly messages
class FailureMapper {
  static String mapToMessage(AppFailure failure) {
    return switch (failure) {
      ServerFailure() => 'Server error occurred',
      NetworkFailure() => 'No internet connection',
      UnknownFailure() => 'An unexpected error occurred',
    };
  }
}
```

## Coding Conventions

### Dart/Flutter Style

1. **Analysis Options**: Uses `very_good_analysis` with custom rules
   - Strict casts, inference, and raw types enabled
   - 100 character line width (not 80)
   - Trailing commas preserved for formatting
   - Package imports required (no relative imports)

2. **Naming Conventions**:
   - Classes: `PascalCase`
   - Files: `snake_case.dart`
   - Variables/functions: `camelCase`
   - Constants: `camelCase` or `SCREAMING_SNAKE_CASE`
   - Private members: `_leadingUnderscore`

3. **File Naming**:
   - BLoCs: `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart`
   - Repositories: `feature_repository.dart`, `feature_repository_impl.dart`
   - DTOs: `feature_dto.dart`
   - Entities: `feature.dart` (singular)

4. **Import Order**:
   ```dart
   // Dart imports
   import 'dart:async';

   // Flutter imports
   import 'package:flutter/material.dart';

   // Package imports
   import 'package:dio/dio.dart';

   // Project imports (always use package imports)
   import 'package:carbon_voice_console/core/utils/result.dart';
   ```

### Repository Pattern

All repositories follow this pattern:

```dart
@LazySingleton(as: FeatureRepository)
class FeatureRepositoryImpl implements FeatureRepository {
  FeatureRepositoryImpl(this._remoteDataSource, this._logger);

  final FeatureRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache
  final Map<String, Feature> _cache = {};

  @override
  Future<Result<Feature>> getFeature(String id) async {
    try {
      // Check cache
      if (_cache.containsKey(id)) {
        return success(_cache[id]!);
      }

      // Fetch from remote
      final dto = await _remoteDataSource.getFeature(id);
      final entity = dto.toDomain();

      // Cache
      _cache[id] = entity;

      return success(entity);
    } on ServerException catch (e) {
      _logger.e('Server error', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  void clearCache() => _cache.clear();
}
```

**Key patterns:**
- In-memory caching with `Map<String, T>`
- Logger for error tracking
- Try-catch with specific exception types
- Return `Result<T>` for type safety
- Cache clearing methods

### DTO Mapping

DTOs map API responses to domain entities:

```dart
@JsonSerializable()
class FeatureDto {
  const FeatureDto({
    required this.id,
    required this.name,
  });

  factory FeatureDto.fromJson(Map<String, dynamic> json) =>
      _$FeatureDtoFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _$FeatureDtoToJson(this);
}

// Mapper extension
extension FeatureDtoMapper on FeatureDto {
  Feature toDomain() {
    return Feature(
      id: id,
      name: name,
    );
  }
}
```

### Logging

Use `Logger` for consistent logging:

```dart
_logger.d('Debug message');         // Debug
_logger.i('Info message');          // Info
_logger.w('Warning message');       // Warning
_logger.e('Error', error: e);       // Error
_logger.e('Error', error: e, stackTrace: stack);  // Error with stack trace
```

## API Integration

### Base URL & Authentication

- **Base URL**: Configured in OAuth config
- **Authentication**: OAuth 2.0 with PKCE
- **Token Storage**: Secure storage (flutter_secure_storage)
- **Auto-refresh**: Tokens refreshed 60s before expiry
- **Interceptors**: Dio interceptor handles 401 responses

### API Conventions

The API uses **snake_case** with prefixes:
```json
{
  "workspace_guid": "...",
  "workspace_name": "...",
  "channel_guid": "...",
  "message_id": "..."
}
```

Our domain uses **camelCase**:
```dart
class Workspace {
  final String id;
  final String name;
}
```

**JsonNormalizer** handles automatic field mapping.

### Response Format Variations

API may return:
- Direct array: `[{...}, {...}]`
- Wrapped: `{messages: [...]}`
- Wrapped: `{data: [...]}`

All datasources handle these variations.

### Key Endpoints

See [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md) for complete documentation.

**Messages:**
- `POST /v3/messages/recent` - Recent messages
- `GET /v3/messages/{conversationId}/sequential/{start}/{stop}` - Sequential messages
- `GET /v5/messages/{messageId}` - Single message

**Workspaces:**
- `GET /workspaces` - List workspaces
- `GET /workspaces/{id}` - Single workspace

**Conversations:**
- `GET /channels/{workspaceId}` - List conversations
- `GET /channel/{conversationId}` - Single conversation

## OAuth 2.0 Flow

### Web Flow
1. User clicks "Login"
2. Redirect to OAuth provider
3. User authorizes
4. Redirect to `/auth/callback` with code
5. Exchange code for token
6. Store token securely
7. Navigate to dashboard

### Desktop Flow
1. User clicks "Login"
2. Start local server (random port)
3. Open browser with OAuth URL
4. User authorizes
5. Redirect to `http://localhost:{port}/callback`
6. Local server captures code
7. Exchange code for token
8. Store token securely
9. Navigate to dashboard

### Token Refresh
- Proactive refresh 60s before expiry
- Automatic retry on 401 responses
- Seamless background operation

## Preview Feature (Public Conversation Previews)

**Purpose:** Create podcast-style public previews of conversations with shareable URLs.

### Feature Overview

The Preview feature allows users to:
1. Select 3-5 messages from a conversation
2. Compose preview metadata (title, description, cover art)
3. Publish to receive a shareable public URL
4. View statistics (participants, duration, message count)

### Architecture

**Domain Layer** ([lib/features/preview/domain/](lib/features/preview/domain/)):
- `PreviewComposerData` - Composer state entity
- `ConversationPreview` - Published preview entity
- `PreviewRepository` - Repository interface
- Use cases:
  - `GetPreviewComposerDataUsecase` - Fetch composer data
  - `PublishPreviewUsecase` - Publish preview to server

**Data Layer** ([lib/features/preview/data/](lib/features/preview/data/)):
- `PreviewRepositoryImpl` - Repository implementation with caching
- `PreviewRemoteDataSource` - API integration

**Presentation Layer** ([lib/features/preview/presentation/](lib/features/preview/presentation/)):
- `PreviewComposerBloc` - State management
- `PreviewComposerScreen` - Main composer UI
- `PreviewConfirmationScreen` - Post-publish confirmation

**Specialized Widgets** ([lib/features/preview/widgets/](lib/features/preview/widgets/)):
- `ChatMessageItem` - Chat-style message display
- `ConversationHeader` - Conversation metadata header
- `ConversationStatistics` - Stats display (duration, messages, etc.)
- `ParticipantsList` - Participant avatars and names
- `AudioControls` - Audio playback controls
- `PreviewVisualization` - Preview mockup display

### User Flow

1. User navigates to `/dashboard/preview/composer`
2. System loads conversation data (messages, participants, metadata)
3. User selects 3-5 messages for preview
4. User composes title, description (optional cover art)
5. System shows preview visualization
6. User publishes
7. System redirects to `/dashboard/preview/confirmation` with shareable URL

### Key Patterns

**Message Selection:**
- Multi-select cubit for message selection state
- Minimum 3, maximum 5 messages
- Visual feedback for selected messages

**State Management:**
- BLoC pattern with events/states
- Optimistic updates with rollback on error
- Loading, loaded, error, publishing, published states

**UI Design:**
- Glassmorphism cards for message display
- Chat-style layout with avatars and timestamps
- Pill-shaped tags for participants
- "darkAura" gradient backgrounds

## Routing

Uses **go_router** with declarative routing:

```dart
AppRoutes:
  /login                           -> LoginScreen
  /auth/callback                   -> OAuthCallbackScreen
  /dashboard                       -> DashboardScreen (with AppShell)
  /dashboard/users                 -> UsersScreen (with AppShell)
  /dashboard/voice-memos           -> VoiceMemosScreen (with AppShell)
  /dashboard/preview/composer      -> PreviewComposerScreen (with AppShell) ⭐ NEW
  /dashboard/preview/confirmation  -> PreviewConfirmationScreen (with AppShell) ⭐ NEW
  /dashboard/settings              -> SettingsScreen (with AppShell)
```

**AppShell** wraps authenticated routes with side navigation.

## Code Generation

### When to Run

After modifying files with:
- `@injectable`, `@singleton`, `@lazySingleton`
- `@module`
- `@JsonSerializable()`

### Commands

```bash
# Generate code (recommended)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing

### Run Tests
```bash
flutter test
flutter test --coverage
```

### Test Patterns
- Unit tests for repositories, use cases
- Widget tests for UI components
- BLoC tests for state management

## Development Workflow

### Quick Start
```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app (recommended: uses run_dev.sh for OAuth config)
./run_dev.sh

# Or run manually
flutter run -d chrome  # Web
flutter run -d macos   # macOS
```

### Hot Reload
- Press `r` for hot reload
- Press `R` for hot restart

### Code Quality
```bash
# Analyze
flutter analyze

# Format
dart format lib/

# Lint
flutter analyze
```

## Common Patterns

### Adding a New Feature

1. **Create feature structure:**
   ```
   lib/features/new_feature/
     ├── domain/
     │   ├── entities/
     │   ├── repositories/
     │   └── usecases/
     ├── data/
     │   ├── datasources/
     │   ├── models/
     │   ├── mappers/
     │   └── repositories/
     └── presentation/
         ├── bloc/
         ├── pages/
         └── widgets/
   ```

2. **Define domain layer** (entities, repository interface, use cases)

3. **Implement data layer** (DTOs, datasources, repository impl)

4. **Add dependency injection** (mark with `@injectable`, `@lazySingleton`)

5. **Create BLoC** (events, states, bloc)

6. **Build UI** (pages, widgets)

7. **Add route** (in `app_router.dart`)

8. **Generate code:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Adding a New BLoC

1. **Create event file:**
   ```dart
   sealed class FeatureEvent extends Equatable {
     const FeatureEvent();
     @override
     List<Object?> get props => [];
   }

   class EventName extends FeatureEvent { /* ... */ }
   ```

2. **Create state file:**
   ```dart
   sealed class FeatureState extends Equatable {
     const FeatureState();
     @override
     List<Object?> get props => [];
   }

   class FeatureInitial extends FeatureState { /* ... */ }
   class FeatureLoading extends FeatureState { /* ... */ }
   class FeatureLoaded extends FeatureState { /* ... */ }
   class FeatureError extends FeatureState { /* ... */ }
   ```

3. **Create BLoC:**
   ```dart
   @LazySingleton()
   class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
     FeatureBloc(this._repository) : super(const FeatureInitial()) {
       on<EventName>(_onEventName);
     }

     final Repository _repository;

     Future<void> _onEventName(
       EventName event,
       Emitter<FeatureState> emit,
     ) async {
       // Implementation
     }
   }
   ```

4. **Register in DI and regenerate code**

### Adding a Repository

1. **Define interface (domain layer):**
   ```dart
   abstract class FeatureRepository {
     Future<Result<Feature>> getFeature(String id);
   }
   ```

2. **Implement (data layer):**
   ```dart
   @LazySingleton(as: FeatureRepository)
   class FeatureRepositoryImpl implements FeatureRepository {
     FeatureRepositoryImpl(this._dataSource, this._logger);

     final FeatureRemoteDataSource _dataSource;
     final Logger _logger;
     final Map<String, Feature> _cache = {};

     @override
     Future<Result<Feature>> getFeature(String id) async {
       // Implementation with caching and error handling
     }
   }
   ```

## Important Notes

### Platform Differences

- **Web**: Uses OAuth redirect flow
- **Desktop**: Uses local server for OAuth callback + deep linking (`carbonvoice://`)
- **Mobile**: Uses deep linking (configured in platform-specific files)

### Storage Solutions

**OAuth Token Storage:**
- **Primary**: `flutter_secure_storage` (encrypted keychain/keystore)
- **Fallback**: File-based storage for macOS (resolves keychain error -34018)
- **Web**: Browser secure storage

See [documents/FILE_STORAGE_SOLUTION.md](documents/FILE_STORAGE_SOLUTION.md) and [documents/KEYCHAIN_FIX.md](documents/KEYCHAIN_FIX.md) for details.

### Environment Variables

OAuth credentials stored in `.env`:
```
OAUTH_CLIENT_ID=your_client_id
OAUTH_CLIENT_SECRET=your_client_secret
OAUTH_REDIRECT_URI=your_redirect_uri
```

(See `.env.example` for template)

### Git Workflow

- Follow conventional commits (see `docs/phase1/GIT_COMMIT_GUIDE.md` if available)
- Write descriptive commit messages
- Test before committing

### Documentation

**Core Documentation** (`docs/`):
- `docs/API_ENDPOINTS.md` - API documentation
- `docs/OAUTH2_EXPLAINED.md` - OAuth flow explanation
- `docs/WIDGET_LIBRARY.md` - Widget library reference
- `docs/REFACTOR_EXAMPLE.md` - Before/after refactoring examples
- `docs/REFACTORING_PROGRESS.md` - UI refactoring progress tracker

**Distribution & Setup** (`documents/`):
- `documents/CLAUDE.md` - This file (AI agent context)
- `documents/DISTRIBUTION_README.md` - Distribution guide
- `documents/OAUTH_DMG_SETUP.md` - OAuth setup for DMG
- `documents/QUICK_START_DMG.md` - Quick start guide
- `documents/TESTER_INSTRUCTIONS.md` - Testing instructions
- `documents/GATEKEEPER_FIX_SUMMARY.md` - macOS Gatekeeper solutions
- `documents/KEYCHAIN_FIX.md` - Keychain error solutions
- `documents/FILE_STORAGE_SOLUTION.md` - File storage documentation

**Implementation Plans** (`thoughts/shared/plans/`):
Detailed plans for 15+ features including:
- Preview feature (composer, BLoC, UI)
- Message download feature
- Dashboard refactors
- Audio player enhancements
- Voice memos backend integration
- Message pagination
- Send message reply feature

## Key Files Reference

### Configuration
- `lib/core/config/oauth_config.dart` - OAuth configuration
- `lib/core/di/injection.dart` - DI setup
- `analysis_options.yaml` - Lint rules
- `pubspec.yaml` - Dependencies

### Core Utilities
- `lib/core/utils/result.dart` - Result type
- `lib/core/utils/failure_mapper.dart` - Error mapping
- `lib/core/utils/json_normalizer.dart` - API field normalization

### Core Services
- `lib/core/services/deep_linking_service.dart` - Deep linking handler

### Design System
- `lib/core/theme/app_colors.dart` - Color palette
- `lib/core/theme/app_text_styles.dart` - Typography system
- `lib/core/theme/app_icons.dart` - Icon library
- `lib/core/theme/app_borders.dart` - Border radius system
- `lib/core/theme/app_shadows.dart` - Shadow system
- `lib/core/theme/app_gradients.dart` - Gradient definitions
- `lib/core/theme/app_dimensions.dart` - Spacing system

### Widget Library
- `lib/core/widgets/buttons/` - Button components
- `lib/core/widgets/cards/` - Card components
- `lib/core/widgets/containers/` - Container components
- `lib/core/widgets/interactive/` - Interactive components
- `lib/core/widgets/app_table.dart` - Table component

### Routing
- `lib/core/routing/app_router.dart` - Router configuration
- `lib/core/routing/app_routes.dart` - Route definitions
- `lib/core/routing/app_shell.dart` - Shell layout

### Error Handling
- `lib/core/errors/failures.dart` - Domain failures
- `lib/core/errors/exceptions.dart` - Data exceptions

### Scripts
- `scripts/run_dev.sh` - Development runner (recommended)
- `scripts/build_macos_release.sh` - macOS release builds
- `scripts/create_dmg.sh` - DMG creation
- `scripts/run_web_with_ngrok.sh` - Web development with ngrok

## Quick Reference Commands

```bash
# Dependencies
flutter pub get

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run (Development)
./scripts/run_dev.sh            # Recommended (with OAuth config)
flutter run -d chrome           # Web
flutter run -d macos            # macOS

# Run (Web with ngrok for OAuth testing)
./scripts/run_web_with_ngrok.sh

# Testing
flutter test
flutter test --coverage

# Code quality
flutter analyze
dart format lib/

# Build (macOS)
./scripts/build_macos_release.sh
./scripts/create_dmg.sh

# Clean
flutter clean
flutter pub get
```

## Summary

This is a well-architected Flutter application following:
- ✅ Clean Architecture (Domain/Data/Presentation)
- ✅ BLoC Pattern for state management
- ✅ Dependency Injection (GetIt + Injectable)
- ✅ Type-safe error handling (Result<T>)
- ✅ OAuth 2.0 with PKCE
- ✅ Multi-platform support (Web, macOS, iOS, Android)
- ✅ In-memory caching
- ✅ Comprehensive logging
- ✅ API field normalization
- ✅ **"Soft Modernism" / "Ethereal Tech" Design Language**
- ✅ **17-component themed widget library**
- ✅ **Google Fonts (DM Sans) + Phosphor Icons**
- ✅ **Glassmorphism effects and mesh gradients**
- ✅ **Deep linking support**
- ✅ **File-based OAuth storage fallback**

**Major Features:**
1. **OAuth 2.0 Authentication** - Complete with PKCE, token refresh, secure storage
2. **Dashboard** - Message inbox with workspace/conversation filtering
3. **User Management** - User profile with permissions
4. **Workspace Management** - Multi-workspace support
5. **Conversation Management** - Full conversation lifecycle
6. **Message Management** - Reply, compose, view, download (audio + transcripts)
7. **Preview Feature** - Public conversation previews with shareable URLs (podcast-style)
8. **Audio Player** - Just Audio integration with playback controls
9. **Voice Memos** - Voice memo management
10. **Settings** - Application configuration

**Code Quality:**
- 99% UI refactor complete with themed components
- ~40% code reduction in refactored files
- DRY principle applied throughout
- Type-safe APIs
- Comprehensive documentation

When working on this codebase, always:
1. **Follow the clean architecture layers** (Domain → Data → Presentation)
2. **Use Result<T> for error handling** (no throwing exceptions)
3. **Use themed widgets from `lib/core/widgets/`** (don't use Material widgets directly)
4. **Follow the "Soft Modernism" design language** (glassmorphism, DM Sans, Phosphor icons)
5. **Mark new classes with appropriate DI annotations** (@injectable, @lazySingleton)
6. **Run code generation after changes** (build_runner)
7. **Add proper logging** (use Logger with appropriate levels)
8. **Write tests for new features** (unit, widget, BLoC tests)
9. **Keep consistent naming conventions** (PascalCase for classes, camelCase for variables)
10. **Consult documentation** (WIDGET_LIBRARY.md, API_ENDPOINTS.md, etc.)
