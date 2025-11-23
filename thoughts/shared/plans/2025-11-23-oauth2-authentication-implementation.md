# OAuth 2.0 Authentication Implementation Plan - Carbon Voice Console

## Overview

This plan implements OAuth 2.0 Authorization Code Flow with PKCE for the Carbon Voice Console Flutter application targeting **Web** and **Desktop (macOS/Windows/Linux)** platforms. The implementation uses the existing project architecture (go_router, flutter_bloc, get_it/injectable, dio) and provides a production-ready authentication system with secure token management, automatic refresh, and platform-specific optimizations.

## Current State Analysis

### Existing Infrastructure:
- **Routing**: go_router v14.6.2 with `AppRouter` singleton ([app_router.dart](lib/core/routing/app_router.dart))
- **State Management**: flutter_bloc v8.1.6 (configured but no implementations yet)
- **DI**: get_it + injectable with code generation ([injection.dart](lib/core/di/injection.dart))
- **HTTP**: dio v5.7.0 registered in `RegisterModule` ([register_module.dart](lib/core/di/register_module.dart))
- **Current Auth**: Basic `LoginPage` that bypasses authentication (line 39 directly navigates to dashboard)
- **Platforms**: Web + Desktop (macOS confirmed, Windows/Linux compatible)

### Key Discoveries:
- ShellRoute pattern already separates authenticated routes ([app_router.dart](lib/core/routing/app_router.dart):31-63)
- Dio already configured with base options ([register_module.dart](lib/core/di/register_module.dart):7-17)
- Feature-based directory structure with `bloc/`, `models/`, `presentation/` separation
- `auth` feature directory exists with empty `bloc/` and `models/` folders

### Constraints:
- Carbon Voice API details not yet available (will use placeholders)
- Must support both web and desktop with different redirect URI strategies
- No mobile platforms (iOS/Android) needed
- First OAuth implementation for this developer

## Desired End State

A fully functional OAuth 2.0 authentication system where:

1. **Users can authenticate** via Carbon Voice API using browser-based OAuth flow
2. **Tokens are securely stored** with platform-appropriate encryption
3. **API requests automatically include** valid access tokens with auto-refresh
4. **Platform-specific flows work seamlessly**:
   - Web: Same-origin callback route handling
   - Desktop: Local HTTP server callback interception
5. **Routing guards protect** authenticated routes
6. **Auth state is managed** via BLoC pattern with proper error handling
7. **User can log out** with complete token cleanup

### Verification Criteria:
- User clicks "Login", browser opens OAuth page, redirects back, user is authenticated
- Access token automatically attached to all API requests
- Token refresh works transparently when token expires
- Logout clears all stored tokens
- Protected routes redirect unauthenticated users to login
- Works on web (Chrome/Firefox/Safari) and desktop (macOS/Windows/Linux)

## What We're NOT Doing

- Mobile platform support (iOS/Android)
- Social login providers (Google, Apple, etc.) - only Carbon Voice OAuth
- Biometric authentication
- Multi-factor authentication (unless Carbon Voice API requires it)
- Custom OAuth flows (implicit, client credentials, password grant)
- Backend token validation (assumes API handles this)
- Offline authentication
- Session management beyond token-based auth

## Implementation Approach

We'll use **OAuth 2.0 Authorization Code Flow with PKCE** (Proof Key for Code Exchange) for maximum security on web and desktop platforms. The implementation is split into 6 phases:

1. **Dependencies & Configuration** - Add packages, environment setup
2. **Core OAuth Infrastructure** - Models, constants, utilities
3. **Platform-Specific OAuth Handlers** - Web callback route, desktop local server
4. **Token Management & Storage** - Secure storage with encryption
5. **API Integration & Interceptors** - Automatic token attachment and refresh
6. **Auth BLoC & UI Integration** - State management, routing guards, login flow

Each phase includes automated verification steps and manual testing checkpoints.

---

## Phase 1: Dependencies & Configuration

### Overview
Set up required packages, environment variables, and base configuration files.

### Changes Required:

#### 1. Update `pubspec.yaml`
**File**: [pubspec.yaml](pubspec.yaml)
**Changes**: Add OAuth and security dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Routing
  go_router: ^14.6.2

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7

  # Dependency Injection
  get_it: ^8.0.2
  injectable: ^2.5.0

  # Networking
  dio: ^5.7.0

  # JSON Serialization
  json_annotation: ^4.9.0

  # NEW: OAuth & Security Dependencies
  flutter_secure_storage: ^9.2.2      # Secure token storage (desktop)
  crypto: ^3.0.6                       # PKCE code generation
  url_launcher: ^6.3.1                 # Launch browser for OAuth
  flutter_dotenv: ^5.2.1               # Environment variable management
  shelf: ^1.4.2                        # Desktop local HTTP server for callback
  shelf_router: ^1.1.4                 # Routing for local server

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # Code Generation
  build_runner: ^2.4.13
  injectable_generator: ^2.6.2
  json_serializable: ^6.8.0
  mockito: ^5.4.4                      # NEW: For testing
```

#### 2. Create `.env.example`
**File**: `.env.example` (root directory)
**Purpose**: Template for environment-specific configuration

```env
# Carbon Voice API Configuration
# TODO: Replace these values when you receive credentials from the client

# OAuth Endpoints
OAUTH_AUTHORIZATION_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
OAUTH_REVOKE_URL=https://api.carbonvoice.app/oauth/revoke

# Client Credentials
OAUTH_CLIENT_ID=your_client_id_here
# NOTE: Client secret should NOT be used in frontend apps
# If Carbon Voice requires it, contact them about PKCE support

# Redirect URIs (platform-specific)
# Web: Must match your deployed domain
OAUTH_REDIRECT_URI_WEB=http://localhost:5000/auth/callback
# Desktop: Localhost server
OAUTH_REDIRECT_URI_DESKTOP=http://localhost:8080/callback

# OAuth Scopes (space-separated)
# TODO: Get required scopes from Carbon Voice API docs
OAUTH_SCOPES=read:memos write:memos user:profile

# API Configuration
API_BASE_URL=https://api.carbonvoice.app
API_TIMEOUT_SECONDS=30

# Environment
ENVIRONMENT=development
```

#### 3. Create actual `.env` file
**File**: `.env` (root directory, gitignored)
**Action**: Copy from `.env.example` and fill in actual values when available

```bash
# Copy example file
cp .env.example .env
# Edit .env with real credentials (DO NOT commit this file)
```

#### 4. Update `.gitignore`
**File**: [.gitignore](.gitignore)
**Changes**: Ensure sensitive files are ignored

```gitignore
# Add these lines if not already present:
.env
*.env
!.env.example
```

#### 5. Load environment in `main.dart`
**File**: [lib/main.dart](lib/main.dart)
**Changes**: Load .env file before app initialization

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // ADD
import 'core/di/injection.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");  // ADD

  // Initialize dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

// ... rest of file unchanged
```

#### 6. Create OAuth configuration class
**File**: `lib/core/config/oauth_config.dart` (NEW)
**Purpose**: Centralized OAuth configuration from environment

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OAuthConfig {
  // Private constructor
  OAuthConfig._();

  // OAuth Endpoints
  static String get authorizationUrl =>
      dotenv.env['OAUTH_AUTHORIZATION_URL'] ?? '';

  static String get tokenUrl =>
      dotenv.env['OAUTH_TOKEN_URL'] ?? '';

  static String get revokeUrl =>
      dotenv.env['OAUTH_REVOKE_URL'] ?? '';

  // Client Credentials
  static String get clientId =>
      dotenv.env['OAUTH_CLIENT_ID'] ?? '';

  // Redirect URI (platform-specific)
  static String get redirectUri {
    if (kIsWeb) {
      return dotenv.env['OAUTH_REDIRECT_URI_WEB'] ??
             'http://localhost:5000/auth/callback';
    } else {
      return dotenv.env['OAUTH_REDIRECT_URI_DESKTOP'] ??
             'http://localhost:8080/callback';
    }
  }

  // OAuth Scopes
  static String get scopes =>
      dotenv.env['OAUTH_SCOPES'] ?? 'read:memos';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.carbonvoice.app';

  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;

  // Validation
  static bool get isConfigured {
    return authorizationUrl.isNotEmpty &&
           tokenUrl.isNotEmpty &&
           clientId.isNotEmpty;
  }

  static String get configStatus {
    if (!isConfigured) {
      final missing = <String>[];
      if (authorizationUrl.isEmpty) missing.add('OAUTH_AUTHORIZATION_URL');
      if (tokenUrl.isEmpty) missing.add('OAUTH_TOKEN_URL');
      if (clientId.isEmpty) missing.add('OAUTH_CLIENT_ID');
      return 'Missing configuration: ${missing.join(', ')}';
    }
    return 'Configuration loaded successfully';
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Dependencies install successfully: `flutter pub get`
- [ ] No dependency conflicts in pubspec.lock
- [ ] .env.example file exists in root directory
- [ ] OAuthConfig class compiles: `flutter analyze lib/core/config/oauth_config.dart`
- [ ] App builds without errors: `flutter build web --debug` and `flutter build macos --debug`

#### Manual Verification:
- [ ] Create .env file from .env.example
- [ ] Verify environment variables load (add debug print in main.dart temporarily)
- [ ] Check that OAuthConfig.configStatus shows appropriate message
- [ ] Confirm .env is gitignored (run `git status`, should not show .env)

**Implementation Note**: After completing Phase 1 automated checks, pause to manually create and verify the .env file before proceeding to Phase 2.

---

## Phase 2: Core OAuth Infrastructure

### Overview
Create data models, constants, and utility classes for OAuth flow management.

### Changes Required:

#### 1. OAuth Token Model
**File**: `lib/features/auth/data/models/oauth_token.dart` (NEW)
**Purpose**: Token data structure with JSON serialization

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'oauth_token.g.dart';

@JsonSerializable()
class OAuthToken extends Equatable {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  @JsonKey(name: 'scope')
  final String? scope;

  // Calculated expiry timestamp (stored locally)
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  const OAuthToken({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    this.scope,
    this.expiresAt,
  });

  // Calculate expiry time on creation
  factory OAuthToken.fromJson(Map<String, dynamic> json) {
    final token = _$OAuthTokenFromJson(json);
    final expiresAt = DateTime.now().add(Duration(seconds: token.expiresIn));
    return OAuthToken(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresIn,
      scope: token.scope,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() => _$OAuthTokenToJson(this);

  // Check if token is expired (with 60s buffer)
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(
      expiresAt!.subtract(const Duration(seconds: 60)),
    );
  }

  // Check if token is valid
  bool get isValid => accessToken.isNotEmpty && !isExpired;

  // Authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        tokenType,
        expiresIn,
        scope,
        expiresAt,
      ];

  OAuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
    String? scope,
    DateTime? expiresAt,
  }) {
    return OAuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      scope: scope ?? this.scope,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
```

#### 2. PKCE Generator Utility
**File**: `lib/core/utils/pkce_generator.dart` (NEW)
**Purpose**: Generate PKCE code_verifier and code_challenge

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PKCEGenerator {
  // Generate cryptographically secure random code_verifier
  static String generateCodeVerifier() {
    const length = 128; // Between 43-128 characters
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Generate code_challenge from code_verifier using S256 method
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);

    // Base64 URL encode without padding
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  // Generate state parameter for CSRF protection
  static String generateState() {
    const length = 32;
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }
}

// PKCE data holder
class PKCEData {
  final String codeVerifier;
  final String codeChallenge;
  final String state;

  PKCEData({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.state,
  });

  factory PKCEData.generate() {
    final verifier = PKCEGenerator.generateCodeVerifier();
    return PKCEData(
      codeVerifier: verifier,
      codeChallenge: PKCEGenerator.generateCodeChallenge(verifier),
      state: PKCEGenerator.generateState(),
    );
  }
}
```

#### 3. OAuth Exception Classes
**File**: `lib/core/errors/oauth_exceptions.dart` (NEW)
**Purpose**: Specific exception types for OAuth errors

```dart
class OAuthException implements Exception {
  final String message;
  final String? error;
  final String? errorDescription;
  final int? statusCode;

  OAuthException({
    required this.message,
    this.error,
    this.errorDescription,
    this.statusCode,
  });

  @override
  String toString() {
    if (errorDescription != null) {
      return 'OAuthException: $message - $errorDescription';
    }
    return 'OAuthException: $message';
  }
}

class AuthorizationException extends OAuthException {
  AuthorizationException({
    String message = 'Authorization failed',
    String? error,
    String? errorDescription,
  }) : super(
          message: message,
          error: error,
          errorDescription: errorDescription,
        );
}

class TokenException extends OAuthException {
  TokenException({
    String message = 'Token exchange failed',
    String? error,
    String? errorDescription,
    int? statusCode,
  }) : super(
          message: message,
          error: error,
          errorDescription: errorDescription,
          statusCode: statusCode,
        );
}

class TokenRefreshException extends OAuthException {
  TokenRefreshException({
    String message = 'Token refresh failed',
    String? error,
    String? errorDescription,
  }) : super(
          message: message,
          error: error,
          errorDescription: errorDescription,
        );
}

class StorageException extends OAuthException {
  StorageException({
    String message = 'Token storage failed',
  }) : super(message: message);
}

class UserCancelledException extends OAuthException {
  UserCancelledException()
      : super(message: 'User cancelled the authorization');
}
```

#### 4. Create directory structure
**Command**: Create necessary directories

```bash
mkdir -p lib/core/config
mkdir -p lib/core/utils
mkdir -p lib/core/errors
mkdir -p lib/features/auth/data/models
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/repositories
```

### Success Criteria:

#### Automated Verification:
- [ ] Generate code: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify oauth_token.g.dart is generated
- [ ] All new files compile: `flutter analyze lib/core lib/features/auth`
- [ ] No linting errors: `flutter analyze`
- [ ] Models serialize correctly (add simple test):

```dart
// test/models/oauth_token_test.dart
void main() {
  test('OAuthToken serialization', () {
    final json = {
      'access_token': 'test_token',
      'token_type': 'Bearer',
      'expires_in': 3600,
    };
    final token = OAuthToken.fromJson(json);
    expect(token.accessToken, 'test_token');
    expect(token.isValid, true);
  });
}
```

Run: `flutter test test/models/oauth_token_test.dart`

#### Manual Verification:
- [ ] PKCE generator creates valid codes (add debug test):
  ```dart
  final pkce = PKCEData.generate();
  print('Verifier: ${pkce.codeVerifier}');
  print('Challenge: ${pkce.codeChallenge}');
  print('State: ${pkce.state}');
  ```
- [ ] Code verifier is 128 characters
- [ ] Code challenge is base64url encoded (no =, +, /)
- [ ] State is 32 characters

**Implementation Note**: After automated tests pass, continue to Phase 3.

---

## Phase 3: Token Storage Service

### Overview
Implement secure token storage with platform-specific encryption.

### Changes Required:

#### 1. Secure Storage Service Interface
**File**: `lib/core/storage/secure_storage_service.dart` (NEW)
**Purpose**: Abstract storage interface

```dart
abstract class SecureStorageService {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
  Future<bool> containsKey({required String key});
}
```

#### 2. Flutter Secure Storage Implementation
**File**: `lib/core/storage/flutter_secure_storage_service.dart` (NEW)
**Purpose**: Platform-specific secure storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'secure_storage_service.dart';

@LazySingleton(as: SecureStorageService)
class FlutterSecureStorageService implements SecureStorageService {
  late final FlutterSecureStorage _storage;

  FlutterSecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      webOptions: WebOptions(
        dbName: 'carbon_voice_auth',
        publicKey: 'carbon_voice_public_key',
      ),
      linuxOptions: LinuxOptions(
        encryptSharedPrefs: true,
      ),
      windowsOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(message: 'Failed to write $key: $e');
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to read $key: $e');
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to delete $key: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(message: 'Failed to delete all: $e');
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw StorageException(message: 'Failed to check $key: $e');
    }
  }
}
```

#### 3. Token Storage Service
**File**: `lib/features/auth/data/datasources/token_storage_datasource.dart` (NEW)
**Purpose**: Token-specific storage operations

```dart
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/errors/oauth_exceptions.dart';
import '../models/oauth_token.dart';

@lazySingleton
class TokenStorageDataSource {
  final SecureStorageService _secureStorage;

  static const String _accessTokenKey = 'oauth_access_token';
  static const String _refreshTokenKey = 'oauth_refresh_token';
  static const String _tokenDataKey = 'oauth_token_data';

  TokenStorageDataSource(this._secureStorage);

  // Save complete token data
  Future<void> saveToken(OAuthToken token) async {
    try {
      final tokenJson = jsonEncode(token.toJson());
      await _secureStorage.write(
        key: _tokenDataKey,
        value: tokenJson,
      );

      // Also store access token separately for quick access
      await _secureStorage.write(
        key: _accessTokenKey,
        value: token.accessToken,
      );

      // Store refresh token if available
      if (token.refreshToken != null) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: token.refreshToken!,
        );
      }
    } catch (e) {
      throw StorageException(message: 'Failed to save token: $e');
    }
  }

  // Retrieve token data
  Future<OAuthToken?> getToken() async {
    try {
      final tokenJson = await _secureStorage.read(key: _tokenDataKey);
      if (tokenJson == null) return null;

      final tokenMap = jsonDecode(tokenJson) as Map<String, dynamic>;
      return OAuthToken.fromJson(tokenMap);
    } catch (e) {
      throw StorageException(message: 'Failed to retrieve token: $e');
    }
  }

  // Get access token only (faster)
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      throw StorageException(message: 'Failed to retrieve access token: $e');
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      throw StorageException(message: 'Failed to retrieve refresh token: $e');
    }
  }

  // Check if token exists
  Future<bool> hasToken() async {
    try {
      return await _secureStorage.containsKey(key: _tokenDataKey);
    } catch (e) {
      return false;
    }
  }

  // Delete all tokens
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenDataKey);
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw StorageException(message: 'Failed to delete tokens: $e');
    }
  }

  // Clear all auth data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw StorageException(message: 'Failed to clear storage: $e');
    }
  }
}
```

#### 4. Register in DI
**File**: `lib/core/di/register_module.dart`
**Changes**: Add storage to module (if needed for web fallback)

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(
        BaseOptions(
          baseUrl: 'https://api.placeholder.com', // Will be updated in Phase 4
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Regenerate DI: `dart run build_runner build --delete-conflicting-outputs`
- [ ] No compilation errors: `flutter analyze lib/core/storage lib/features/auth/data`
- [ ] Storage service registered in GetIt
- [ ] Unit test for token storage:

```dart
// test/datasources/token_storage_test.dart
void main() {
  late MockSecureStorageService mockStorage;
  late TokenStorageDataSource dataSource;

  setUp(() {
    mockStorage = MockSecureStorageService();
    dataSource = TokenStorageDataSource(mockStorage);
  });

  test('saveToken stores token correctly', () async {
    final token = OAuthToken(
      accessToken: 'test_access',
      tokenType: 'Bearer',
      expiresIn: 3600,
    );

    await dataSource.saveToken(token);

    verify(mockStorage.write(
      key: 'oauth_token_data',
      value: any,
    )).called(1);
  });
}
```

Run: `flutter test test/datasources/token_storage_test.dart`

#### Manual Verification:
- [ ] Create a test page to save/retrieve a token
- [ ] Verify token persists across app restarts
- [ ] Check platform-specific storage:
  - Web: Browser DevTools → Application → IndexedDB
  - macOS: Keychain Access → Search "carbon_voice"
  - Windows: Credential Manager (if applicable)
- [ ] Delete token and verify removal

**Implementation Note**: After verification, continue to Phase 4.

---

## Phase 4: Platform-Specific OAuth Flow Handlers

### Overview
Implement web callback route handling and desktop local server for OAuth redirect interception.

### Changes Required:

#### 1. OAuth Service Interface
**File**: `lib/features/auth/domain/repositories/oauth_repository.dart` (NEW)
**Purpose**: Abstract OAuth operations

```dart
import '../../../data/models/oauth_token.dart';

abstract class OAuthRepository {
  Future<OAuthToken> authorize();
  Future<OAuthToken> refreshToken(String refreshToken);
  Future<void> revokeToken(String token);
  Future<OAuthToken?> getStoredToken();
  Future<void> saveToken(OAuthToken token);
  Future<void> clearToken();
}
```

#### 2. Web OAuth Handler
**File**: `lib/features/auth/data/datasources/web_oauth_datasource.dart` (NEW)
**Purpose**: Web-specific OAuth authorization

```dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/utils/pkce_generator.dart';
import '../../../../core/errors/oauth_exceptions.dart';

class WebOAuthDataSource {
  PKCEData? _pkceData;
  Completer<Map<String, String>>? _authCompleter;

  // Generate authorization URL
  String generateAuthorizationUrl() {
    if (!kIsWeb) {
      throw OAuthException(message: 'WebOAuthDataSource only works on web');
    }

    _pkceData = PKCEData.generate();

    final params = {
      'response_type': 'code',
      'client_id': OAuthConfig.clientId,
      'redirect_uri': OAuthConfig.redirectUri,
      'scope': OAuthConfig.scopes,
      'state': _pkceData!.state,
      'code_challenge': _pkceData!.codeChallenge,
      'code_challenge_method': 'S256',
    };

    final uri = Uri.parse(OAuthConfig.authorizationUrl).replace(
      queryParameters: params,
    );

    return uri.toString();
  }

  // Launch authorization in same window (web redirects)
  Future<Map<String, String>> authorize() async {
    if (!kIsWeb) {
      throw OAuthException(message: 'WebOAuthDataSource only works on web');
    }

    _authCompleter = Completer<Map<String, String>>();

    final authUrl = generateAuthorizationUrl();
    final uri = Uri.parse(authUrl);

    // On web, use same-window navigation
    if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw AuthorizationException(
        message: 'Could not launch authorization URL',
      );
    }

    return _authCompleter!.future;
  }

  // Handle callback (called by callback route)
  void handleCallback(Uri callbackUri) {
    if (_authCompleter == null || _authCompleter!.isCompleted) {
      throw OAuthException(message: 'No authorization in progress');
    }

    final params = callbackUri.queryParameters;

    // Check for errors
    if (params.containsKey('error')) {
      final error = params['error'];
      final description = params['error_description'];
      _authCompleter!.completeError(
        AuthorizationException(
          error: error,
          errorDescription: description,
        ),
      );
      return;
    }

    // Validate state
    if (params['state'] != _pkceData?.state) {
      _authCompleter!.completeError(
        AuthorizationException(
          message: 'Invalid state parameter (CSRF protection)',
        ),
      );
      return;
    }

    // Extract authorization code
    final code = params['code'];
    if (code == null) {
      _authCompleter!.completeError(
        AuthorizationException(message: 'No authorization code received'),
      );
      return;
    }

    _authCompleter!.complete({
      'code': code,
      'code_verifier': _pkceData!.codeVerifier,
    });
  }

  void dispose() {
    _authCompleter = null;
    _pkceData = null;
  }
}
```

#### 3. Desktop OAuth Handler
**File**: `lib/features/auth/data/datasources/desktop_oauth_datasource.dart` (NEW)
**Purpose**: Desktop local server for callback

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/utils/pkce_generator.dart';
import '../../../../core/errors/oauth_exceptions.dart';

class DesktopOAuthDataSource {
  PKCEData? _pkceData;
  HttpServer? _server;
  Completer<Map<String, String>>? _authCompleter;

  static const int _defaultPort = 8080;
  static const String _callbackPath = '/callback';

  // Start local server and launch browser
  Future<Map<String, String>> authorize() async {
    if (kIsWeb) {
      throw OAuthException(message: 'DesktopOAuthDataSource only works on desktop');
    }

    _authCompleter = Completer<Map<String, String>>();
    _pkceData = PKCEData.generate();

    try {
      // Start local callback server
      await _startCallbackServer();

      // Generate authorization URL
      final authUrl = _generateAuthorizationUrl();

      // Launch browser
      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri)) {
        throw AuthorizationException(
          message: 'Could not launch browser for authorization',
        );
      }

      // Wait for callback
      final result = await _authCompleter!.future
          .timeout(const Duration(minutes: 5), onTimeout: () {
        throw AuthorizationException(
          message: 'Authorization timeout - user did not complete login',
        );
      });

      return result;
    } catch (e) {
      await _stopCallbackServer();
      rethrow;
    } finally {
      await _stopCallbackServer();
    }
  }

  String _generateAuthorizationUrl() {
    final params = {
      'response_type': 'code',
      'client_id': OAuthConfig.clientId,
      'redirect_uri': OAuthConfig.redirectUri,
      'scope': OAuthConfig.scopes,
      'state': _pkceData!.state,
      'code_challenge': _pkceData!.codeChallenge,
      'code_challenge_method': 'S256',
    };

    final uri = Uri.parse(OAuthConfig.authorizationUrl).replace(
      queryParameters: params,
    );

    return uri.toString();
  }

  Future<void> _startCallbackServer() async {
    // Try to bind to configured port, fallback to random port
    int port = _defaultPort;
    final uri = Uri.parse(OAuthConfig.redirectUri);
    if (uri.port > 0) {
      port = uri.port;
    }

    try {
      _server = await shelf_io.serve(
        _handleRequest,
        InternetAddress.loopbackIPv4,
        port,
      );
      print('OAuth callback server listening on http://localhost:${_server!.port}$_callbackPath');
    } catch (e) {
      // Port might be in use, try random port
      _server = await shelf_io.serve(
        _handleRequest,
        InternetAddress.loopbackIPv4,
        0, // Random port
      );
      print('OAuth callback server listening on http://localhost:${_server!.port}$_callbackPath (fallback)');
    }
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.url.path != _callbackPath.substring(1)) {
      return shelf.Response.notFound('Not found');
    }

    final params = request.url.queryParameters;

    // Check for errors
    if (params.containsKey('error')) {
      final error = params['error'];
      final description = params['error_description'];

      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(
          AuthorizationException(
            error: error,
            errorDescription: description,
          ),
        );
      }

      return shelf.Response.ok(
        _htmlResponse(
          'Authorization Failed',
          'Error: ${description ?? error}',
          isError: true,
        ),
        headers: {'Content-Type': 'text/html'},
      );
    }

    // Validate state
    if (params['state'] != _pkceData?.state) {
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(
          AuthorizationException(
            message: 'Invalid state parameter (CSRF protection)',
          ),
        );
      }

      return shelf.Response.ok(
        _htmlResponse(
          'Authorization Failed',
          'Security validation failed. Please try again.',
          isError: true,
        ),
        headers: {'Content-Type': 'text/html'},
      );
    }

    // Extract authorization code
    final code = params['code'];
    if (code == null) {
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(
          AuthorizationException(message: 'No authorization code received'),
        );
      }

      return shelf.Response.ok(
        _htmlResponse(
          'Authorization Failed',
          'No authorization code received.',
          isError: true,
        ),
        headers: {'Content-Type': 'text/html'},
      );
    }

    // Success!
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete({
        'code': code,
        'code_verifier': _pkceData!.codeVerifier,
      });
    }

    return shelf.Response.ok(
      _htmlResponse(
        'Authorization Successful',
        'You can now close this window and return to the app.',
        isError: false,
      ),
      headers: {'Content-Type': 'text/html'},
    );
  }

  String _htmlResponse(String title, String message, {required bool isError}) {
    final color = isError ? '#f44336' : '#4CAF50';
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>$title</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 400px;
    }
    h1 {
      color: $color;
      margin-bottom: 20px;
    }
    p {
      color: #666;
      line-height: 1.6;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">${isError ? '❌' : '✅'}</div>
    <h1>$title</h1>
    <p>$message</p>
    <script>
      // Auto-close window after 3 seconds on success
      ${!isError ? 'setTimeout(() => window.close(), 3000);' : ''}
    </script>
  </div>
</body>
</html>
''';
  }

  Future<void> _stopCallbackServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  void dispose() {
    _stopCallbackServer();
    _authCompleter = null;
    _pkceData = null;
  }
}
```

#### 4. OAuth Callback Route (Web)
**File**: Update `lib/core/routing/app_router.dart`
**Changes**: Add callback route for web

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/oauth_callback_page.dart';  // NEW
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/users/presentation/users_page.dart';
import '../../features/voice_memos/presentation/voice_memos_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import 'app_routes.dart';

@singleton
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      routes: [
        // Standalone login route (no shell)
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const LoginPage(),
          ),
        ),
        // NEW: OAuth callback route (web only)
        GoRoute(
          path: AppRoutes.authCallback,
          name: 'authCallback',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const OAuthCallbackPage(),
          ),
        ),
        // Authenticated routes wrapped in AppShell
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.users,
              name: 'users',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UsersPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.voiceMemos,
              name: 'voiceMemos',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: VoiceMemosPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.path}'),
        ),
      ),
    );
  }

  GoRouter get instance => router;
}
```

#### 5. Add Callback Route Constant
**File**: Update `lib/core/routing/app_routes.dart`
**Changes**: Add authCallback route

```dart
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Route paths
  static const String login = '/login';
  static const String authCallback = '/auth/callback';  // NEW
  static const String dashboard = '/dashboard';
  static const String users = '/dashboard/users';
  static const String voiceMemos = '/dashboard/voice-memos';
  static const String settings = '/dashboard/settings';
}
```

#### 6. OAuth Callback Page (Web)
**File**: `lib/features/auth/presentation/oauth_callback_page.dart` (NEW)
**Purpose**: Handle OAuth redirect on web

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../bloc/auth_bloc.dart';

class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  void _handleCallback() {
    // Get current URI from browser
    final uri = Uri.base;

    // Send to auth bloc
    context.read<AuthBloc>().add(OAuthCallbackReceived(uri));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Success - navigate to dashboard
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          // Error - show message and return to login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            context.go(AppRoutes.login);
          });
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Completing authentication...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `flutter analyze lib/features/auth lib/core/routing`
- [ ] No linting errors
- [ ] Web build succeeds: `flutter build web --debug`
- [ ] Desktop build succeeds: `flutter build macos --debug`

#### Manual Verification:
- [ ] **Web Test**:
  - Run `flutter run -d chrome`
  - Navigate to `/auth/callback?code=test&state=test` manually
  - Verify OAuthCallbackPage loads
- [ ] **Desktop Test**:
  - Create simple test to start local server
  - Verify server starts on port 8080
  - Open `http://localhost:8080/callback?code=test&state=test`
  - Verify HTML response displays
  - Verify server closes properly
- [ ] URL launcher permissions configured (may need platform-specific setup)

**Implementation Note**: Platform-specific handlers are ready but not integrated with auth flow yet. This happens in Phase 5.

---

## Phase 5: Token Exchange and API Integration

### Overview
Implement token exchange, refresh logic, and Dio interceptor for automatic token management.

### Changes Required:

#### 1. Token Exchange Data Source
**File**: `lib/features/auth/data/datasources/token_exchange_datasource.dart` (NEW)
**Purpose**: Exchange authorization code for tokens

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/errors/oauth_exceptions.dart';
import '../models/oauth_token.dart';

@lazySingleton
class TokenExchangeDataSource {
  final Dio _dio;

  TokenExchangeDataSource(this._dio);

  // Exchange authorization code for access token
  Future<OAuthToken> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final response = await _dio.post(
        OAuthConfig.tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': OAuthConfig.redirectUri,
          'client_id': OAuthConfig.clientId,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return OAuthToken.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw TokenException(
          message: 'Token exchange failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        throw TokenException(
          message: 'Token exchange failed',
          error: data['error'],
          errorDescription: data['error_description'],
          statusCode: e.response!.statusCode,
        );
      } else {
        throw TokenException(
          message: 'Network error during token exchange: ${e.message}',
        );
      }
    }
  }

  // Refresh access token
  Future<OAuthToken> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        OAuthConfig.tokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': OAuthConfig.clientId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return OAuthToken.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw TokenRefreshException(
          message: 'Token refresh failed',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        throw TokenRefreshException(
          message: 'Token refresh failed',
          error: data['error'],
          errorDescription: data['error_description'],
        );
      } else {
        throw TokenRefreshException(
          message: 'Network error during token refresh: ${e.message}',
        );
      }
    }
  }

  // Revoke token
  Future<void> revokeToken(String token) async {
    if (OAuthConfig.revokeUrl.isEmpty) {
      // Revocation endpoint not configured
      return;
    }

    try {
      await _dio.post(
        OAuthConfig.revokeUrl,
        data: {
          'token': token,
          'client_id': OAuthConfig.clientId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
    } on DioException catch (e) {
      // Revocation errors are non-critical
      print('Token revocation failed: ${e.message}');
    }
  }
}
```

#### 2. OAuth Repository Implementation
**File**: `lib/features/auth/data/repositories/oauth_repository_impl.dart` (NEW)
**Purpose**: Coordinate OAuth flow components

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import '../../domain/repositories/oauth_repository.dart';
import '../models/oauth_token.dart';
import '../datasources/token_storage_datasource.dart';
import '../datasources/token_exchange_datasource.dart';
import '../datasources/web_oauth_datasource.dart';
import '../datasources/desktop_oauth_datasource.dart';
import '../../../../core/errors/oauth_exceptions.dart';

@LazySingleton(as: OAuthRepository)
class OAuthRepositoryImpl implements OAuthRepository {
  final TokenStorageDataSource _tokenStorage;
  final TokenExchangeDataSource _tokenExchange;
  final WebOAuthDataSource _webOAuth;
  final DesktopOAuthDataSource _desktopOAuth;

  OAuthRepositoryImpl(
    this._tokenStorage,
    this._tokenExchange,
    this._webOAuth,
    this._desktopOAuth,
  );

  @override
  Future<OAuthToken> authorize() async {
    try {
      // Platform-specific authorization
      final Map<String, String> authResult;

      if (kIsWeb) {
        authResult = await _webOAuth.authorize();
      } else {
        authResult = await _desktopOAuth.authorize();
      }

      // Exchange code for token
      final token = await _tokenExchange.exchangeCodeForToken(
        code: authResult['code']!,
        codeVerifier: authResult['code_verifier']!,
      );

      // Store token
      await _tokenStorage.saveToken(token);

      return token;
    } catch (e) {
      throw OAuthException(message: 'Authorization failed: $e');
    }
  }

  @override
  Future<OAuthToken> refreshToken(String refreshToken) async {
    try {
      final newToken = await _tokenExchange.refreshAccessToken(refreshToken);
      await _tokenStorage.saveToken(newToken);
      return newToken;
    } catch (e) {
      // Clear invalid tokens
      await _tokenStorage.deleteToken();
      throw TokenRefreshException(
        message: 'Token refresh failed: $e',
      );
    }
  }

  @override
  Future<void> revokeToken(String token) async {
    await _tokenExchange.revokeToken(token);
    await _tokenStorage.deleteToken();
  }

  @override
  Future<OAuthToken?> getStoredToken() async {
    return await _tokenStorage.getToken();
  }

  @override
  Future<void> saveToken(OAuthToken token) async {
    await _tokenStorage.saveToken(token);
  }

  @override
  Future<void> clearToken() async {
    await _tokenStorage.deleteToken();
  }
}
```

#### 3. Auth Interceptor for Dio
**File**: `lib/core/api/auth_interceptor.dart` (NEW)
**Purpose**: Automatic token attachment and refresh

```dart
import 'package:dio/dio.dart';
import '../../features/auth/data/datasources/token_storage_datasource.dart';
import '../../features/auth/data/datasources/token_exchange_datasource.dart';
import '../../features/auth/data/models/oauth_token.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorageDataSource _tokenStorage;
  final TokenExchangeDataSource _tokenExchange;

  // Prevent concurrent refresh attempts
  bool _isRefreshing = false;
  final List<void Function()> _refreshQueue = [];

  AuthInterceptor(this._tokenStorage, this._tokenExchange);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for token endpoint
    if (options.path.contains('/oauth/token')) {
      return handler.next(options);
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token != null && token.isValid) {
        // Token is valid, attach it
        options.headers['Authorization'] = token.authorizationHeader;
      } else if (token != null && token.refreshToken != null) {
        // Token expired, try refresh
        final newToken = await _refreshTokenIfNeeded(token);
        if (newToken != null) {
          options.headers['Authorization'] = newToken.authorizationHeader;
        }
      }
    } catch (e) {
      print('Auth interceptor error: $e');
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      try {
        final token = await _tokenStorage.getToken();

        if (token?.refreshToken != null) {
          // Try to refresh token
          final newToken = await _refreshTokenIfNeeded(token!);

          if (newToken != null) {
            // Retry original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = newToken.authorizationHeader;

            final dio = Dio();
            final response = await dio.fetch(options);
            return handler.resolve(response);
          }
        }
      } catch (e) {
        print('Token refresh on 401 failed: $e');
        // Clear invalid tokens
        await _tokenStorage.deleteToken();
      }
    }

    return handler.next(err);
  }

  Future<OAuthToken?> _refreshTokenIfNeeded(OAuthToken token) async {
    if (!token.isExpired) {
      return token;
    }

    if (token.refreshToken == null) {
      return null;
    }

    // Wait if refresh is already in progress
    if (_isRefreshing) {
      return await _waitForRefresh();
    }

    _isRefreshing = true;

    try {
      final newToken = await _tokenExchange.refreshAccessToken(
        token.refreshToken!,
      );
      await _tokenStorage.saveToken(newToken);

      // Notify queued requests
      for (final callback in _refreshQueue) {
        callback();
      }
      _refreshQueue.clear();

      return newToken;
    } catch (e) {
      await _tokenStorage.deleteToken();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<OAuthToken?> _waitForRefresh() async {
    final completer = Completer<void>();
    _refreshQueue.add(completer.complete);
    await completer.future;
    return await _tokenStorage.getToken();
  }
}
```

#### 4. Register Interceptor and DataSources in DI
**File**: Update `lib/core/di/register_module.dart`
**Changes**: Add auth interceptor to Dio

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../api/auth_interceptor.dart';
import '../../features/auth/data/datasources/token_storage_datasource.dart';
import '../../features/auth/data/datasources/token_exchange_datasource.dart';
import '../config/oauth_config.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio dio(
    TokenStorageDataSource tokenStorage,
    TokenExchangeDataSource tokenExchange,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: OAuthConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: OAuthConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor
    dio.interceptors.add(AuthInterceptor(tokenStorage, tokenExchange));

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }

  // Register platform-specific OAuth handlers
  @lazySingleton
  WebOAuthDataSource get webOAuth => WebOAuthDataSource();

  @lazySingleton
  DesktopOAuthDataSource get desktopOAuth => DesktopOAuthDataSource();
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Regenerate DI: `dart run build_runner build --delete-conflicting-outputs`
- [ ] All files compile: `flutter analyze`
- [ ] No circular dependencies in DI
- [ ] Unit test for token exchange:

```dart
void main() {
  test('exchangeCodeForToken success', () async {
    // Mock dio response
    final mockDio = MockDio();
    when(mockDio.post(any, data: anyNamed('data')))
        .thenAnswer((_) async => Response(
              data: {
                'access_token': 'test_access',
                'token_type': 'Bearer',
                'expires_in': 3600,
              },
              statusCode: 200,
            ));

    final dataSource = TokenExchangeDataSource(mockDio);
    final token = await dataSource.exchangeCodeForToken(
      code: 'test_code',
      codeVerifier: 'test_verifier',
    );

    expect(token.accessToken, 'test_access');
  });
}
```

#### Manual Verification:
- [ ] Create test endpoint call with hardcoded token
- [ ] Verify Authorization header is attached
- [ ] Simulate token expiry and verify refresh triggers
- [ ] Simulate 401 error and verify retry with new token
- [ ] Verify refresh queue prevents concurrent refreshes

**Implementation Note**: Core auth infrastructure is complete. Next phase integrates with BLoC state management.

---

## Phase 6: Auth BLoC and State Management

### Overview
Implement BLoC pattern for authentication state management with events and states.

### Changes Required:

#### 1. Auth Events
**File**: `lib/features/auth/bloc/auth_event.dart` (NEW)
**Purpose**: Define all auth events

```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// App started - check for existing token
class AppStarted extends AuthEvent {
  const AppStarted();
}

// User initiated login
class LoginRequested extends AuthEvent {
  const LoginRequested();
}

// OAuth callback received (web only)
class OAuthCallbackReceived extends AuthEvent {
  final Uri callbackUri;

  const OAuthCallbackReceived(this.callbackUri);

  @override
  List<Object?> get props => [callbackUri];
}

// Desktop OAuth completed
class DesktopOAuthCompleted extends AuthEvent {
  final Map<String, String> authResult;

  const DesktopOAuthCompleted(this.authResult);

  @override
  List<Object?> get props => [authResult];
}

// Token refresh requested
class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}

// Logout requested
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
```

#### 2. Auth States
**File**: `lib/features/auth/bloc/auth_state.dart` (NEW)
**Purpose**: Define all auth states

```dart
import 'package:equatable/equatable.dart';
import '../data/models/oauth_token.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state - checking for existing session
class AuthInitial extends AuthState {
  const AuthInitial();
}

// No authentication
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

// Authentication in progress
class Authenticating extends AuthState {
  final String? message;

  const Authenticating({this.message});

  @override
  List<Object?> get props => [message];
}

// Successfully authenticated
class Authenticated extends AuthState {
  final OAuthToken token;

  const Authenticated(this.token);

  @override
  List<Object?> get props => [token];
}

// Token refresh in progress
class TokenRefreshing extends AuthState {
  final OAuthToken currentToken;

  const TokenRefreshing(this.currentToken);

  @override
  List<Object?> get props => [currentToken];
}

// Authentication error
class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
```

#### 3. Auth BLoC
**File**: `lib/features/auth/bloc/auth_bloc.dart` (NEW)
**Purpose**: Orchestrate authentication flow

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../domain/repositories/oauth_repository.dart';
import '../../../core/errors/oauth_exceptions.dart';
import '../data/datasources/web_oauth_datasource.dart';
import '../data/datasources/token_exchange_datasource.dart';
import '../data/datasources/token_storage_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@singleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final OAuthRepository _oauthRepository;
  final WebOAuthDataSource _webOAuth;
  final TokenExchangeDataSource _tokenExchange;
  final TokenStorageDataSource _tokenStorage;

  AuthBloc(
    this._oauthRepository,
    this._webOAuth,
    this._tokenExchange,
    this._tokenStorage,
  ) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<OAuthCallbackReceived>(_onOAuthCallbackReceived);
    on<DesktopOAuthCompleted>(_onDesktopOAuthCompleted);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // Check for existing token on app start
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _oauthRepository.getStoredToken();

      if (token != null && token.isValid) {
        emit(Authenticated(token));
      } else if (token != null && token.refreshToken != null) {
        // Token expired but can be refreshed
        add(const TokenRefreshRequested());
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  // User clicked login button
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Authenticating(message: 'Redirecting to login...'));

    try {
      if (kIsWeb) {
        // Web: Generate auth URL and redirect
        // Actual redirect happens in UI layer
        // State stays as Authenticating
        // Completion happens via OAuthCallbackReceived
      } else {
        // Desktop: Launch browser and wait for callback
        final token = await _oauthRepository.authorize();
        emit(Authenticated(token));
      }
    } on UserCancelledException {
      emit(const AuthError('Login cancelled by user'));
      emit(const Unauthenticated());
    } on AuthorizationException catch (e) {
      emit(AuthError(
        e.errorDescription ?? e.message,
        errorCode: e.error,
      ));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Login failed: $e'));
      emit(const Unauthenticated());
    }
  }

  // Web OAuth callback received
  Future<void> _onOAuthCallbackReceived(
    OAuthCallbackReceived event,
    Emitter<AuthState> emit,
  ) async {
    if (!kIsWeb) return;

    emit(const Authenticating(message: 'Completing authentication...'));

    try {
      // Pass callback to web OAuth handler
      _webOAuth.handleCallback(event.callbackUri);

      // Get auth result from handler's completer
      final authResult = await _webOAuth._authCompleter?.future;

      if (authResult == null) {
        throw OAuthException(message: 'No auth result received');
      }

      // Exchange code for token
      final token = await _tokenExchange.exchangeCodeForToken(
        code: authResult['code']!,
        codeVerifier: authResult['code_verifier']!,
      );

      // Save token
      await _tokenStorage.saveToken(token);

      emit(Authenticated(token));
    } on AuthorizationException catch (e) {
      emit(AuthError(
        e.errorDescription ?? e.message,
        errorCode: e.error,
      ));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Authentication failed: $e'));
      emit(const Unauthenticated());
    }
  }

  // Desktop OAuth completed (not used on web)
  Future<void> _onDesktopOAuthCompleted(
    DesktopOAuthCompleted event,
    Emitter<AuthState> emit,
  ) async {
    // This is handled in LoginRequested for desktop
    // Kept for future alternative flows
  }

  // Refresh token
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentToken = await _oauthRepository.getStoredToken();

    if (currentToken == null || currentToken.refreshToken == null) {
      emit(const Unauthenticated());
      return;
    }

    emit(TokenRefreshing(currentToken));

    try {
      final newToken = await _oauthRepository.refreshToken(
        currentToken.refreshToken!,
      );
      emit(Authenticated(newToken));
    } on TokenRefreshException catch (e) {
      emit(AuthError('Session expired: ${e.message}'));
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Token refresh failed: $e'));
      emit(const Unauthenticated());
    }
  }

  // Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _oauthRepository.getStoredToken();

      if (token != null) {
        // Revoke token on server
        await _oauthRepository.revokeToken(token.accessToken);
      }

      // Clear local storage
      await _oauthRepository.clearToken();

      emit(const Unauthenticated());
    } catch (e) {
      // Even if revocation fails, clear local tokens
      await _oauthRepository.clearToken();
      emit(const Unauthenticated());
    }
  }
}
```

#### 4. BLoC Barrel Export
**File**: `lib/features/auth/bloc/bloc.dart` (NEW)
**Purpose**: Convenient imports

```dart
export 'auth_bloc.dart';
export 'auth_event.dart';
export 'auth_state.dart';
```

### Success Criteria:

#### Automated Verification:
- [ ] Regenerate DI: `dart run build_runner build --delete-conflicting-outputs`
- [ ] BLoC files compile: `flutter analyze lib/features/auth/bloc`
- [ ] No state management errors
- [ ] Unit test for BLoC:

```dart
void main() {
  blocTest<AuthBloc, AuthState>(
    'emits Authenticated when AppStarted with valid token',
    build: () {
      when(mockOAuthRepository.getStoredToken())
          .thenAnswer((_) async => testToken);
      return AuthBloc(mockOAuthRepository, ...);
    },
    act: (bloc) => bloc.add(const AppStarted()),
    expect: () => [Authenticated(testToken)],
  );
}
```

Run: `flutter test test/bloc/auth_bloc_test.dart`

#### Manual Verification:
- [ ] Add debug prints to BLoC events/states
- [ ] Trigger login flow and observe state transitions
- [ ] Verify states follow expected sequence:
  - Unauthenticated → Authenticating → Authenticated
- [ ] Test logout: Authenticated → Unauthenticated
- [ ] Test error handling: Invalid token → AuthError → Unauthenticated

**Implementation Note**: BLoC is ready. Next phase connects it to UI and routing.

---

## Phase 7: UI Integration and Routing Guards

### Overview
Update LoginPage to trigger OAuth flow, add routing guards, and provide BLoC to app.

### Changes Required:

#### 1. Update LoginPage
**File**: Update `lib/features/auth/presentation/login_page.dart`
**Changes**: Replace mock navigation with real OAuth flow

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/config/oauth_config.dart';
import '../bloc/bloc.dart';
import '../../auth/data/datasources/web_oauth_datasource.dart';
import '../../../core/di/injection.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate to dashboard on success
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carbon Voice Console'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticating) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        state.message ?? 'Authenticating...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  );
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Carbon Voice Console',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (!OAuthConfig.isConfigured)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '⚠️ ${OAuthConfig.configStatus}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: OAuthConfig.isConfigured
                          ? () => _handleLogin(context)
                          : null,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Login with Carbon Voice'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    if (state is AuthError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) async {
    if (kIsWeb) {
      // Web: Generate URL and navigate in same window
      final webOAuth = getIt<WebOAuthDataSource>();
      final authUrl = webOAuth.generateAuthorizationUrl();
      final uri = Uri.parse(authUrl);

      // Trigger BLoC event
      context.read<AuthBloc>().add(const LoginRequested());

      // Launch browser (will redirect back to /auth/callback)
      if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open login page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Desktop: BLoC handles everything
      context.read<AuthBloc>().add(const LoginRequested());
    }
  }
}
```

#### 2. Add Auth Guard to Router
**File**: Update `lib/core/routing/app_router.dart`
**Changes**: Add redirect logic for protected routes

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/oauth_callback_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/users/presentation/users_page.dart';
import '../../features/voice_memos/presentation/voice_memos_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/auth/data/datasources/token_storage_datasource.dart';
import 'app_routes.dart';

@singleton
class AppRouter {
  late final GoRouter router;
  final TokenStorageDataSource _tokenStorage;

  AppRouter(this._tokenStorage) {
    router = GoRouter(
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,
      redirect: _authGuard,
      routes: [
        // Standalone login route (no shell)
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const LoginPage(),
          ),
        ),
        // OAuth callback route (web only)
        GoRoute(
          path: AppRoutes.authCallback,
          name: 'authCallback',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const OAuthCallbackPage(),
          ),
        ),
        // Authenticated routes wrapped in AppShell
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.users,
              name: 'users',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UsersPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.voiceMemos,
              name: 'voiceMemos',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: VoiceMemosPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.path}'),
        ),
      ),
    );
  }

  // Auth guard redirect logic
  Future<String?> _authGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isLoginRoute = state.uri.path == AppRoutes.login;
    final isCallbackRoute = state.uri.path == AppRoutes.authCallback;

    // Allow login and callback routes without auth
    if (isLoginRoute || isCallbackRoute) {
      return null;
    }

    // Check if user has valid token
    final token = await _tokenStorage.getToken();
    final isAuthenticated = token != null && token.isValid;

    if (!isAuthenticated) {
      // Redirect to login
      return AppRoutes.login;
    }

    // User is authenticated, allow access
    return null;
  }

  GoRouter get instance => router;
}
```

#### 3. Provide AuthBloc to App
**File**: Update `lib/main.dart`
**Changes**: Wrap app with BlocProvider

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'features/auth/bloc/bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();
    final authBloc = getIt<AuthBloc>();

    return BlocProvider<AuthBloc>(
      create: (context) => authBloc..add(const AppStarted()),
      child: MaterialApp.router(
        title: 'Carbon Voice Console',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: appRouter.instance,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

#### 4. Add Logout Button to Settings
**File**: Update `lib/features/settings/presentation/settings_page.dart`
**Changes**: Add logout functionality

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/bloc.dart';
import '../../../core/routing/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Navigate to login after logout
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Account'),
              subtitle: const Text('Manage your account settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Final DI generation: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Full app compiles: `flutter analyze`
- [ ] No routing errors
- [ ] Web build: `flutter build web --release`
- [ ] Desktop build: `flutter build macos --release`

#### Manual Verification:
- [ ] **Complete Flow Test (Web)**:
  1. Run `flutter run -d chrome`
  2. App loads at `/login`
  3. Click "Login with Carbon Voice"
  4. Browser redirects to OAuth provider (will fail if no credentials yet)
  5. (With credentials) After OAuth approval, redirects to `/auth/callback`
  6. App navigates to `/dashboard`
  7. Refresh page - stays authenticated
  8. Navigate to Settings → Logout
  9. Returns to `/login`

- [ ] **Complete Flow Test (Desktop)**:
  1. Run `flutter run -d macos`
  2. App loads at login page
  3. Click "Login with Carbon Voice"
  4. Browser opens OAuth page
  5. After approval, local server catches callback
  6. Browser shows success page
  7. App navigates to dashboard
  8. Restart app - stays authenticated
  9. Logout works

- [ ] **Protected Routes Test**:
  1. Manually navigate to `/dashboard/users` when logged out
  2. Verify redirect to `/login`
  3. Login and verify access granted

- [ ] **Token Persistence Test**:
  1. Login successfully
  2. Close app completely
  3. Reopen app
  4. Verify automatic login (AppStarted event)

**Implementation Note**: OAuth flow is fully integrated. Final phase is configuration and deployment prep.

---

## Phase 8: Configuration, Testing & Documentation

### Overview
Finalize configuration, add comprehensive testing, and create deployment documentation.

### Changes Required:

#### 1. Platform-Specific Configuration

**Web Configuration**:
**File**: `web/index.html` (if needed)
**Note**: Usually no changes needed, but verify CORS headers in deployment

**Desktop Configuration**:
**File**: Update platform-specific files if using custom URI scheme (optional)

For **macOS** custom URI scheme (alternative to localhost):
**File**: `macos/Runner/Info.plist`
**Changes**: Add URL scheme handler

```xml
<!-- Add this inside <dict> tag -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.carbonvoice.console</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>carbonvoice</string>
    </array>
  </dict>
</array>
```

Then update `.env`:
```env
OAUTH_REDIRECT_URI_DESKTOP=carbonvoice://callback
```

#### 2. Environment Files for Different Stages

**File**: `.env.development` (NEW)
```env
# Development Environment
OAUTH_AUTHORIZATION_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
OAUTH_REVOKE_URL=https://api.carbonvoice.app/oauth/revoke
OAUTH_CLIENT_ID=dev_client_id_here
OAUTH_REDIRECT_URI_WEB=http://localhost:5000/auth/callback
OAUTH_REDIRECT_URI_DESKTOP=http://localhost:8080/callback
OAUTH_SCOPES=read:memos write:memos user:profile
API_BASE_URL=https://api.carbonvoice.app
API_TIMEOUT_SECONDS=30
ENVIRONMENT=development
```

**File**: `.env.staging` (NEW)
```env
# Staging Environment
OAUTH_AUTHORIZATION_URL=https://staging-api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://staging-api.carbonvoice.app/oauth/token
OAUTH_REVOKE_URL=https://staging-api.carbonvoice.app/oauth/revoke
OAUTH_CLIENT_ID=staging_client_id_here
OAUTH_REDIRECT_URI_WEB=https://staging.carbonvoice.app/auth/callback
OAUTH_REDIRECT_URI_DESKTOP=http://localhost:8080/callback
OAUTH_SCOPES=read:memos write:memos user:profile
API_BASE_URL=https://staging-api.carbonvoice.app
API_TIMEOUT_SECONDS=30
ENVIRONMENT=staging
```

**File**: `.env.production` (NEW)
```env
# Production Environment
OAUTH_AUTHORIZATION_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
OAUTH_REVOKE_URL=https://api.carbonvoice.app/oauth/revoke
OAUTH_CLIENT_ID=prod_client_id_here
OAUTH_REDIRECT_URI_WEB=https://app.carbonvoice.com/auth/callback
OAUTH_REDIRECT_URI_DESKTOP=http://localhost:8080/callback
OAUTH_SCOPES=read:memos write:memos user:profile
API_BASE_URL=https://api.carbonvoice.app
API_TIMEOUT_SECONDS=30
ENVIRONMENT=production
```

**File**: `lib/main.dart`
**Changes**: Support environment selection

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'features/auth/bloc/bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment-specific .env file
  // Default to .env, override with --dart-define=ENV=staging
  const environment = String.fromEnvironment('ENV', defaultValue: 'development');
  final envFile = environment == 'development'
      ? '.env'
      : '.env.$environment';

  await dotenv.load(fileName: envFile);

  // Initialize dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

// ... rest unchanged
```

Build commands:
```bash
# Development (uses .env)
flutter run -d chrome

# Staging
flutter run -d chrome --dart-define=ENV=staging

# Production
flutter build web --release --dart-define=ENV=production
```

#### 3. Integration Tests

**File**: `test/integration/oauth_flow_test.dart` (NEW)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:carbon_voice_console/features/auth/bloc/bloc.dart';
import 'package:carbon_voice_console/features/auth/data/models/oauth_token.dart';

void main() {
  group('OAuth Flow Integration Tests', () {
    late AuthBloc authBloc;
    late MockOAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockOAuthRepository();
      authBloc = AuthBloc(mockRepository, ...);
    });

    test('Complete login flow', () async {
      final testToken = OAuthToken(
        accessToken: 'test_access',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      when(mockRepository.authorize())
          .thenAnswer((_) async => testToken);

      authBloc.add(const LoginRequested());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<Authenticating>(),
          isA<Authenticated>(),
        ]),
      );
    });

    test('Token refresh on expiry', () async {
      final expiredToken = OAuthToken(
        accessToken: 'expired',
        refreshToken: 'refresh_123',
        tokenType: 'Bearer',
        expiresIn: -1, // Expired
      );

      final newToken = OAuthToken(
        accessToken: 'new_access',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      when(mockRepository.getStoredToken())
          .thenAnswer((_) async => expiredToken);
      when(mockRepository.refreshToken(any))
          .thenAnswer((_) async => newToken);

      authBloc.add(const AppStarted());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<TokenRefreshing>(),
          isA<Authenticated>(),
        ]),
      );
    });

    test('Logout clears tokens', () async {
      when(mockRepository.getStoredToken())
          .thenAnswer((_) async => testToken);

      authBloc.add(const LogoutRequested());

      await expectLater(
        authBloc.stream,
        emits(isA<Unauthenticated>()),
      );

      verify(mockRepository.clearToken()).called(1);
    });
  });
}
```

#### 4. README Documentation

**File**: `docs/OAUTH_SETUP.md` (NEW)
**Purpose**: OAuth implementation guide

```markdown
# OAuth 2.0 Setup Guide

## Overview
This application uses OAuth 2.0 Authorization Code Flow with PKCE for secure authentication with the Carbon Voice API.

## Prerequisites

1. **Carbon Voice API Credentials**
   - Obtain from Carbon Voice API administrator
   - Required: Client ID, OAuth endpoints, scopes
   - Register redirect URIs for your application

2. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Fill in actual credentials (see below)

## Configuration Steps

### 1. Get Credentials from Carbon Voice

Contact the Carbon Voice API team to obtain:

- **Client ID**: Unique identifier for your application
- **Authorization URL**: Full URL for OAuth authorization
- **Token URL**: Full URL for token exchange
- **Revoke URL**: (Optional) URL for token revocation
- **Required Scopes**: Space-separated list of permissions
- **Redirect URIs**: Must be registered in Carbon Voice system

### 2. Configure Environment Variables

Edit your `.env` file:

```env
# OAuth Endpoints (from Carbon Voice)
OAUTH_AUTHORIZATION_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
OAUTH_REVOKE_URL=https://api.carbonvoice.app/oauth/revoke

# Client Credentials (from Carbon Voice)
OAUTH_CLIENT_ID=your_actual_client_id

# Redirect URIs
# Web: Must match deployed domain (use localhost for development)
OAUTH_REDIRECT_URI_WEB=http://localhost:5000/auth/callback

# Desktop: Localhost callback server
OAUTH_REDIRECT_URI_DESKTOP=http://localhost:8080/callback

# Scopes (from Carbon Voice API documentation)
OAUTH_SCOPES=read:memos write:memos user:profile

# API Configuration
API_BASE_URL=https://api.carbonvoice.app
API_TIMEOUT_SECONDS=30
```

### 3. Register Redirect URIs

**IMPORTANT**: You must register these redirect URIs with Carbon Voice:

**For Development:**
- Web: `http://localhost:5000/auth/callback`
- Desktop: `http://localhost:8080/callback`

**For Production:**
- Web: `https://your-production-domain.com/auth/callback`
- Desktop: `http://localhost:8080/callback` (same for all users)

### 4. Verify Configuration

Run the app and check the login page:

```bash
flutter run -d chrome
```

If configuration is missing, you'll see:
```
⚠️ Missing configuration: OAUTH_CLIENT_ID, OAUTH_AUTHORIZATION_URL
```

## Platform-Specific Setup

### Web

1. **Development**:
   ```bash
   flutter run -d chrome --web-port=5000
   ```

2. **Deployment**:
   - Build: `flutter build web --release --dart-define=ENV=production`
   - Deploy to your hosting (Firebase, Netlify, etc.)
   - Update redirect URI in `.env.production` to match domain
   - Re-register redirect URI with Carbon Voice

### Desktop (macOS/Windows/Linux)

1. **Run**:
   ```bash
   flutter run -d macos
   ```

2. **Build**:
   ```bash
   flutter build macos --release
   ```

3. **Optional - Custom URI Scheme** (instead of localhost):
   - macOS: Edit `macos/Runner/Info.plist` (see Phase 8, step 1)
   - Update `OAUTH_REDIRECT_URI_DESKTOP=carbonvoice://callback`
   - Re-register with Carbon Voice

## Troubleshooting

### "Could not launch authorization URL"
- Check URL launcher permissions
- Verify browser is installed
- Check firewall settings (desktop)

### "Invalid redirect URI"
- Ensure redirect URI exactly matches what's registered in Carbon Voice
- Check for trailing slashes
- Verify port numbers match

### "Token exchange failed"
- Verify `OAUTH_TOKEN_URL` is correct
- Check network connectivity
- Confirm client ID is valid

### "CORS errors" (web only)
- Carbon Voice API must allow your domain in CORS settings
- For development, ensure `http://localhost:5000` is allowed

### "State parameter mismatch"
- Clear browser cache/cookies
- Restart OAuth flow
- Check for browser extensions interfering

## Security Notes

1. **Never commit `.env` file** - It's gitignored
2. **Client Secret**: Should NOT be used in frontend apps
   - If Carbon Voice requires it, request PKCE support instead
3. **Token Storage**:
   - Web: Encrypted browser storage (limited security)
   - Desktop: Keychain/Credential Manager (secure)
4. **HTTPS**: Always use HTTPS in production
5. **PKCE**: Always enabled for additional security

## Flow Diagrams

### Web OAuth Flow
```
User clicks "Login"
  → App redirects to Carbon Voice OAuth page
  → User approves
  → Carbon Voice redirects to yourapp.com/auth/callback?code=XXX
  → App exchanges code for token
  → Token stored in encrypted browser storage
  → User authenticated
```

### Desktop OAuth Flow
```
User clicks "Login"
  → App starts local server on localhost:8080
  → App opens browser to Carbon Voice OAuth page
  → User approves
  → Carbon Voice redirects to localhost:8080/callback?code=XXX
  → Local server receives code
  → App exchanges code for token
  → Token stored in system keychain
  → Browser shows success page
  → User authenticated
```

## API Usage After Authentication

Once authenticated, all API calls automatically include the access token:

```dart
// Example API call
final dio = getIt<Dio>();
final response = await dio.get('/api/voice-memos');
// Authorization header automatically added by AuthInterceptor
```

Token refresh happens automatically when tokens expire.

## Support

For issues with:
- **OAuth credentials**: Contact Carbon Voice API team
- **App implementation**: Check application logs or GitHub issues
```

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] Integration tests pass: `flutter test test/integration`
- [ ] Build succeeds for all environments:
  ```bash
  flutter build web --dart-define=ENV=development
  flutter build web --dart-define=ENV=staging
  flutter build web --dart-define=ENV=production
  flutter build macos --release
  ```
- [ ] No analyzer warnings: `flutter analyze`

#### Manual Verification:
- [ ] Documentation is clear and complete
- [ ] .env.example has all required fields
- [ ] Different environment files load correctly
- [ ] OAuth flow works on web (Chrome, Firefox, Safari)
- [ ] OAuth flow works on desktop (macOS, Windows if available)
- [ ] Token persistence works across app restarts
- [ ] Token refresh works automatically
- [ ] Logout clears all tokens
- [ ] Protected routes redirect to login when unauthenticated
- [ ] Error messages are user-friendly

**Implementation Note**: OAuth implementation is complete! Ready for Carbon Voice API credentials.

---

## Testing Strategy

### Unit Tests

**Files to Test**:
1. `oauth_token.dart` - Serialization, expiry logic
2. `pkce_generator.dart` - Code generation, security
3. `token_storage_datasource.dart` - Storage operations
4. `token_exchange_datasource.dart` - API calls (mocked)
5. `auth_bloc.dart` - State transitions

**Example Test Structure**:
```dart
// test/features/auth/bloc/auth_bloc_test.dart
void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockOAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockOAuthRepository();
      authBloc = AuthBloc(mockRepository, ...);
    });

    tearDown(() {
      authBloc.close();
    });

    blocTest(
      'AppStarted with valid token emits Authenticated',
      build: () {
        when(mockRepository.getStoredToken())
            .thenAnswer((_) async => validToken);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [Authenticated(validToken)],
    );

    // More tests...
  });
}
```

### Integration Tests

Test complete user flows:
1. Login → Token Storage → API Call → Logout
2. Login → Token Expiry → Auto Refresh → API Call
3. Login → App Restart → Auto Re-authentication

### Manual Testing Checklist

#### Web Platform:
- [ ] Login flow works in Chrome
- [ ] Login flow works in Firefox
- [ ] Login flow works in Safari
- [ ] Callback route handles authorization code
- [ ] Token persists on page reload
- [ ] Token refresh works automatically
- [ ] Logout clears all data
- [ ] Error messages display correctly

#### Desktop Platform:
- [ ] Local server starts successfully
- [ ] Browser launches for OAuth
- [ ] Callback intercepted correctly
- [ ] Success page displays
- [ ] Token stored in keychain
- [ ] App restart preserves session
- [ ] Multiple app instances handled

## Performance Considerations

1. **Token Refresh Queue**: Prevents concurrent refresh attempts (implemented in `AuthInterceptor`)
2. **Storage Caching**: Access token cached separately for quick retrieval
3. **Lazy DI**: Dependencies created only when needed
4. **Router Guards**: Async token check on navigation

## Security Best Practices

### Implemented:
✅ PKCE (Proof Key for Code Exchange)
✅ State parameter for CSRF protection
✅ Secure token storage (platform-specific encryption)
✅ Token expiry checking with 60s buffer
✅ Automatic token refresh
✅ No client secret in frontend
✅ HTTPS for production (deployment requirement)

### Recommendations:
- Use short-lived access tokens (< 1 hour)
- Rotate refresh tokens (if Carbon Voice API supports)
- Implement rate limiting on OAuth endpoints (server-side)
- Monitor for suspicious auth patterns

## Migration Notes

### From Current Bypass Auth:

**Before** ([login_page.dart](lib/features/auth/presentation/login_page.dart):39):
```dart
onPressed: () => context.go(AppRoutes.dashboard),
```

**After**:
```dart
onPressed: () => _handleLogin(context),
```

All existing routes and navigation work unchanged. The router guard automatically redirects unauthenticated users.

## Deployment Checklist

### Before Deploying to Production:

- [ ] Obtain production OAuth credentials from Carbon Voice
- [ ] Update `.env.production` with real values
- [ ] Register production redirect URI with Carbon Voice
- [ ] Test OAuth flow in staging environment first
- [ ] Configure CORS on Carbon Voice API for your domain
- [ ] Set up HTTPS for web deployment
- [ ] Test token refresh edge cases
- [ ] Verify logout revokes tokens server-side
- [ ] Review security headers (CSP, HSTS, etc.)
- [ ] Monitor error logs for auth failures

### Web Deployment:

```bash
# Build for production
flutter build web --release --dart-define=ENV=production

# Deploy to hosting (example: Firebase)
firebase deploy --only hosting
```

### Desktop Deployment:

```bash
# macOS
flutter build macos --release --dart-define=ENV=production

# Windows
flutter build windows --release --dart-define=ENV=production

# Linux
flutter build linux --release --dart-define=ENV=production
```

## Next Steps After Implementation

1. **Get Carbon Voice Credentials**
   - Contact client for OAuth credentials
   - Register redirect URIs
   - Test in development environment

2. **API Integration**
   - Update existing API calls to use authenticated Dio instance
   - Add error handling for 401/403 responses
   - Implement user profile fetching

3. **Enhanced Features** (optional future work)
   - Remember me checkbox (optional token persistence)
   - Account linking (if multiple OAuth providers later)
   - Session timeout warnings
   - Activity logging

## References

- **OAuth 2.0 RFC**: https://datatracker.ietf.org/doc/html/rfc6749
- **PKCE RFC**: https://datatracker.ietf.org/doc/html/rfc7636
- **Carbon Voice API Docs**: https://api.carbonvoice.app/docs (TODO: Update when accessible)
- **Flutter Secure Storage**: https://pub.dev/packages/flutter_secure_storage
- **go_router Auth**: https://pub.dev/packages/go_router#redirection

---

## Summary

This implementation provides:

✅ **Complete OAuth 2.0 Flow** - Authorization code with PKCE
✅ **Platform Support** - Web and Desktop (macOS/Windows/Linux)
✅ **Secure Token Storage** - Platform-appropriate encryption
✅ **Automatic Token Management** - Refresh, expiry handling, retry
✅ **BLoC State Management** - Clean architecture with events/states
✅ **Routing Guards** - Protected routes with auto-redirect
✅ **Error Handling** - User-friendly messages, graceful failures
✅ **Environment Support** - Dev/Staging/Production configurations
✅ **Comprehensive Testing** - Unit, integration, manual tests
✅ **Documentation** - Setup guides, troubleshooting, deployment

**Total Files Created/Modified**: ~30 files across 8 phases

**Next Action**: Fill in Carbon Voice API credentials in `.env` file and test the complete flow!
the presentation layer looks okay, 