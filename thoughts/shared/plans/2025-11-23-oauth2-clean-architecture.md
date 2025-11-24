# OAuth 2.0 Clean Architecture Implementation Plan

## Overview

This plan implements OAuth 2.0 Authorization Code Flow with PKCE using **Clean Architecture** principles. Each layer has strict, explicit responsibilities with clear boundaries. The architecture ensures testability, maintainability, and scalability suitable for senior-level engineering standards.

## Architecture Principles

### Layer Separation Rules

1. **Presentation Layer** (BLoC) - UI Coordination Only
   - Reacts to UI events
   - Calls use cases
   - Emits UI states
   - **NO** business logic, networking, storage, or platform code

2. **Domain Layer** - Pure Business Logic
   - Use cases encapsulate all business rules
   - Entities define core data structures
   - Repository interfaces (contracts only)
   - **NO** Flutter imports, HTTP clients, or storage implementations
   - Returns `Result<T>` (Success/Failure)

3. **Data Layer** - Protocol & Storage Implementation
   - Repository implementations delegate to data sources
   - Remote data source handles OAuth protocol (PKCE, token exchange)
   - Local data source handles secure storage
   - Maps exceptions to domain failures
   - **NO** BLoC types, widgets, or routing

4. **Infrastructure Layer** - Platform Adapters
   - Browser launching
   - Redirect URI handling (web callback route, desktop local server)
   - Platform detection (web vs desktop)
   - **NO** business logic or state management

### Dependency Flow

```
Presentation (BLoC)
    ↓ depends on
Domain (Use Cases + Interfaces)
    ↑ implemented by
Data (Repositories + Data Sources)
    ↑ uses
Infrastructure (Platform Adapters)
```

---

## Project Structure

```
lib/
├── core/
│   ├── errors/
│   │   ├── failures.dart              # Domain failure types
│   │   └── exceptions.dart            # Data layer exceptions
│   ├── utils/
│   │   ├── result.dart                # Result<T> type
│   │   └── constants.dart             # App-wide constants
│   └── config/
│       └── oauth_config.dart          # Environment configuration
│
├── features/
│   └── auth/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── token.dart         # Token entity (pure data)
│       │   │   └── oauth_state.dart   # OAuth flow state entity
│       │   ├── repositories/
│       │   │   └── auth_repository.dart     # Repository interface
│       │   └── usecases/
│       │       ├── generate_auth_url_usecase.dart
│       │       ├── exchange_code_usecase.dart
│       │       ├── refresh_token_usecase.dart
│       │       ├── load_saved_token_usecase.dart
│       │       ├── save_token_usecase.dart
│       │       └── logout_usecase.dart
│       │
│       ├── data/
│       │   ├── models/
│       │   │   ├── token_model.dart   # Token JSON serialization
│       │   │   └── oauth_response_model.dart
│       │   ├── datasources/
│       │   │   ├── auth_remote_datasource.dart     # OAuth API calls
│       │   │   └── auth_local_datasource.dart      # Secure storage
│       │   └── repositories/
│       │       └── auth_repository_impl.dart       # Repository implementation
│       │
│       ├── presentation/
│       │   ├── bloc/
│       │   │   ├── auth_bloc.dart
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart
│       │   └── pages/
│       │       ├── login_page.dart
│       │       └── oauth_callback_page.dart
│       │
│       └── infrastructure/
│           ├── adapters/
│           │   ├── oauth_launcher.dart            # Platform-specific launcher
│           │   ├── web_callback_handler.dart     # Web redirect handling
│           │   └── desktop_callback_server.dart  # Desktop HTTP server
│           └── services/
│               ├── pkce_service.dart             # PKCE generation
│               └── secure_storage_service.dart   # Storage abstraction
│
└── injection.dart  # Dependency injection
```

---

## Layer 1: Domain Layer (Pure Business Logic)

### Responsibilities
- Define business entities
- Define repository contracts (interfaces)
- Implement use cases that orchestrate business rules
- Return `Result<T>` for error handling without exceptions
- **ZERO** dependencies on Flutter, HTTP, or platform code

### 1.1 Core Result Type

**File**: `lib/core/utils/result.dart`

```dart
/// Result type for handling success/failure without exceptions
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

/// Extension for easier result handling
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  AppFailure? get failureOrNull => this is Failure<T> ? (this as Failure<T>).failure : null;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).failure);
    }
  }
}
```

### 1.2 Domain Failures

**File**: `lib/core/errors/failures.dart`

```dart
import 'package:equatable/equatable.dart';

/// Base class for all domain failures
abstract class AppFailure extends Equatable {
  final String message;
  final String? code;

  const AppFailure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Authentication-specific failures
class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, super.code});
}

class TokenExpiredFailure extends AppFailure {
  const TokenExpiredFailure()
      : super(message: 'Your session has expired. Please login again.');
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({String? message})
      : super(message: message ?? 'Network error. Please check your connection.');
}

class StorageFailure extends AppFailure {
  const StorageFailure({required super.message});
}

class InvalidStateFailure extends AppFailure {
  const InvalidStateFailure()
      : super(message: 'Invalid state parameter. Possible CSRF attack.');
}

class UserCancelledFailure extends AppFailure {
  const UserCancelledFailure()
      : super(message: 'Login was cancelled.');
}

class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({required super.message});
}
```

### 1.3 Domain Entity: Token

**File**: `lib/features/auth/domain/entities/token.dart`

```dart
import 'package:equatable/equatable.dart';

/// Token entity - pure business object with no JSON concerns
class Token extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final DateTime expiresAt;
  final List<String> scopes;

  const Token({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresAt,
    this.scopes = const [],
  });

  /// Check if token is expired (with 60 second buffer)
  bool get isExpired {
    final now = DateTime.now();
    final buffer = const Duration(seconds: 60);
    return now.isAfter(expiresAt.subtract(buffer));
  }

  /// Check if token is valid and not expired
  bool get isValid => accessToken.isNotEmpty && !isExpired;

  /// Get authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  /// Check if refresh is available
  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresAt, scopes];

  Token copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    List<String>? scopes,
  }) {
    return Token(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
      scopes: scopes ?? this.scopes,
    );
  }
}
```

### 1.4 Domain Entity: OAuth Flow State

**File**: `lib/features/auth/domain/entities/oauth_flow_state.dart`

```dart
import 'package:equatable/equatable.dart';

/// Represents the state of an OAuth flow in progress
class OAuthFlowState extends Equatable {
  final String codeVerifier;
  final String state;

  const OAuthFlowState({
    required this.codeVerifier,
    required this.state,
  });

  @override
  List<Object?> get props => [codeVerifier, state];
}
```

### 1.5 Repository Interface

**File**: `lib/features/auth/domain/repositories/auth_repository.dart`

```dart
import '../../../../core/utils/result.dart';
import '../entities/token.dart';
import '../entities/oauth_flow_state.dart';

/// Repository interface - contract for auth operations
/// Implementation lives in data layer
abstract class AuthRepository {
  /// Generate OAuth authorization URL
  /// Returns URL string to redirect user to
  Future<Result<String>> generateAuthorizationUrl();

  /// Get current OAuth flow state (code verifier, state parameter)
  /// Needed after redirect to exchange code
  Result<OAuthFlowState?> getCurrentFlowState();

  /// Exchange authorization code for access token
  Future<Result<Token>> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  });

  /// Refresh access token using refresh token
  Future<Result<Token>> refreshToken(String refreshToken);

  /// Save token to secure storage
  Future<Result<void>> saveToken(Token token);

  /// Load saved token from secure storage
  Future<Result<Token?>> loadSavedToken();

  /// Revoke token and clear storage
  Future<Result<void>> logout();

  /// Clear all auth data
  Future<Result<void>> clearAuthData();
}
```

### 1.6 Use Case: Generate Auth URL

**File**: `lib/features/auth/domain/usecases/generate_auth_url_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case: Generate OAuth authorization URL
/// Business rule: URL must be generated and flow state must be stored
class GenerateAuthUrlUseCase {
  final AuthRepository _repository;

  const GenerateAuthUrlUseCase(this._repository);

  Future<Result<String>> call() async {
    return await _repository.generateAuthorizationUrl();
  }
}
```

### 1.7 Use Case: Exchange Code

**File**: `lib/features/auth/domain/usecases/exchange_code_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

/// Use case: Exchange authorization code for access token
/// Business rule: Must validate state, exchange code, and save token
class ExchangeCodeUseCase {
  final AuthRepository _repository;

  const ExchangeCodeUseCase(this._repository);

  Future<Result<Token>> call({
    required String code,
    required String state,
  }) async {
    // Validate state parameter (CSRF protection)
    final flowStateResult = _repository.getCurrentFlowState();

    if (flowStateResult is Failure) {
      return flowStateResult as Result<Token>;
    }

    final flowState = (flowStateResult as Success).value;

    if (flowState == null) {
      return const Failure(AuthFailure(
        message: 'No OAuth flow in progress',
        code: 'NO_FLOW',
      ));
    }

    if (flowState.state != state) {
      return const Failure(InvalidStateFailure());
    }

    // Exchange code for token
    final tokenResult = await _repository.exchangeCodeForToken(
      code: code,
      codeVerifier: flowState.codeVerifier,
    );

    // Save token if successful
    if (tokenResult is Success<Token>) {
      final saveResult = await _repository.saveToken(tokenResult.value);
      if (saveResult is Failure) {
        return Failure(saveResult.failure);
      }
    }

    return tokenResult;
  }
}
```

### 1.8 Use Case: Refresh Token

**File**: `lib/features/auth/domain/usecases/refresh_token_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

/// Use case: Refresh access token
/// Business rule: Load current token, refresh it, save new token
class RefreshTokenUseCase {
  final AuthRepository _repository;

  const RefreshTokenUseCase(this._repository);

  Future<Result<Token>> call() async {
    // Load current token
    final currentTokenResult = await _repository.loadSavedToken();

    if (currentTokenResult is Failure) {
      return Failure(currentTokenResult.failure);
    }

    final currentToken = (currentTokenResult as Success<Token?>).value;

    if (currentToken == null) {
      return const Failure(AuthFailure(
        message: 'No token to refresh',
        code: 'NO_TOKEN',
      ));
    }

    if (!currentToken.canRefresh) {
      return const Failure(AuthFailure(
        message: 'No refresh token available',
        code: 'NO_REFRESH_TOKEN',
      ));
    }

    // Refresh token
    final newTokenResult = await _repository.refreshToken(
      currentToken.refreshToken!,
    );

    // Save new token if successful
    if (newTokenResult is Success<Token>) {
      final saveResult = await _repository.saveToken(newTokenResult.value);
      if (saveResult is Failure) {
        return Failure(saveResult.failure);
      }
    }

    return newTokenResult;
  }
}
```

### 1.9 Use Case: Load Saved Token

**File**: `lib/features/auth/domain/usecases/load_saved_token_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

/// Use case: Load saved token from storage
/// Business rule: Check if token exists and is valid
class LoadSavedTokenUseCase {
  final AuthRepository _repository;

  const LoadSavedTokenUseCase(this._repository);

  Future<Result<Token?>> call() async {
    return await _repository.loadSavedToken();
  }
}
```

### 1.10 Use Case: Save Token

**File**: `lib/features/auth/domain/usecases/save_token_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../entities/token.dart';
import '../repositories/auth_repository.dart';

/// Use case: Save token to secure storage
class SaveTokenUseCase {
  final AuthRepository _repository;

  const SaveTokenUseCase(this._repository);

  Future<Result<void>> call(Token token) async {
    return await _repository.saveToken(token);
  }
}
```

### 1.11 Use Case: Logout

**File**: `lib/features/auth/domain/usecases/logout_usecase.dart`

```dart
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use case: Logout user
/// Business rule: Revoke token on server and clear all local data
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<Result<void>> call() async {
    return await _repository.logout();
  }
}
```

---

## Layer 2: Data Layer (Implementation Details)

### Responsibilities
- Implement repository interface
- Handle OAuth protocol (PKCE, token exchange, refresh)
- Manage secure storage
- Catch exceptions and map to domain failures
- **NO** business logic, BLoC types, or UI concerns

### 2.1 Data Layer Exceptions

**File**: `lib/core/errors/exceptions.dart`

```dart
/// Base exception for data layer
class AppException implements Exception {
  final String message;
  final String? code;

  AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message ${code != null ? '($code)' : ''}';
}

class NetworkException extends AppException {
  final int? statusCode;

  NetworkException({
    required super.message,
    super.code,
    this.statusCode,
  });
}

class StorageException extends AppException {
  StorageException({required super.message});
}

class OAuthException extends AppException {
  OAuthException({required super.message, super.code});
}

class ServerException extends AppException {
  final int statusCode;

  ServerException({
    required super.message,
    required this.statusCode,
    super.code,
  });
}
```

### 2.2 Token Model (Data Layer)

**File**: `lib/features/auth/data/models/token_model.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/token.dart';

part 'token_model.g.dart';

/// Token model - handles JSON serialization
/// Maps to/from domain Token entity
@JsonSerializable()
class TokenModel {
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

  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  const TokenModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    this.scope,
    this.expiresAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) =>
      _$TokenModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenModelToJson(this);

  /// Convert to domain entity
  Token toDomain() {
    final DateTime calculatedExpiresAt;

    if (expiresAt != null) {
      calculatedExpiresAt = DateTime.parse(expiresAt!);
    } else {
      calculatedExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    }

    return Token(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresAt: calculatedExpiresAt,
      scopes: scope?.split(' ') ?? [],
    );
  }

  /// Convert from domain entity
  factory TokenModel.fromDomain(Token token) {
    return TokenModel(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresAt.difference(DateTime.now()).inSeconds,
      scope: token.scopes.join(' '),
      expiresAt: token.expiresAt.toIso8601String(),
    );
  }
}
```

### 2.3 Remote Data Source Interface

**File**: `lib/features/auth/data/datasources/auth_remote_datasource.dart`

```dart
import '../models/token_model.dart';

/// Remote data source interface for OAuth operations
abstract class AuthRemoteDataSource {
  /// Build OAuth authorization URL with PKCE
  /// Returns: URL string
  /// Throws: OAuthException
  Future<String> buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
  });

  /// Exchange authorization code for access token
  /// Throws: NetworkException, ServerException, OAuthException
  Future<TokenModel> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  });

  /// Refresh access token using refresh token
  /// Throws: NetworkException, ServerException, OAuthException
  Future<TokenModel> refreshAccessToken(String refreshToken);

  /// Revoke token on server
  /// Throws: NetworkException, ServerException
  Future<void> revokeToken(String token);
}
```

### 2.4 Remote Data Source Implementation

**File**: `lib/features/auth/data/datasources/auth_remote_datasource_impl.dart`

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/token_model.dart';
import 'auth_remote_datasource.dart';

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<String> buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
  }) async {
    try {
      final params = {
        'response_type': 'code',
        'client_id': OAuthConfig.clientId,
        'redirect_uri': OAuthConfig.redirectUri,
        'scope': OAuthConfig.scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      };

      final uri = Uri.parse(OAuthConfig.authorizationUrl).replace(
        queryParameters: params,
      );

      return uri.toString();
    } catch (e) {
      throw OAuthException(
        message: 'Failed to build authorization URL: $e',
      );
    }
  }

  @override
  Future<TokenModel> exchangeCodeForToken({
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
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Token exchange failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final error = data is Map ? data['error'] : null;
        final description = data is Map ? data['error_description'] : null;

        throw ServerException(
          message: description ?? error ?? 'Token exchange failed',
          statusCode: e.response!.statusCode ?? 500,
          code: error,
        );
      } else {
        throw NetworkException(
          message: 'Network error during token exchange: ${e.message}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw OAuthException(
        message: 'Unexpected error during token exchange: $e',
      );
    }
  }

  @override
  Future<TokenModel> refreshAccessToken(String refreshToken) async {
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
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Token refresh failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final error = data is Map ? data['error'] : null;
        final description = data is Map ? data['error_description'] : null;

        throw ServerException(
          message: description ?? error ?? 'Token refresh failed',
          statusCode: e.response!.statusCode ?? 500,
          code: error,
        );
      } else {
        throw NetworkException(
          message: 'Network error during token refresh: ${e.message}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw OAuthException(
        message: 'Unexpected error during token refresh: $e',
      );
    }
  }

  @override
  Future<void> revokeToken(String token) async {
    if (OAuthConfig.revokeUrl.isEmpty) {
      return; // Revocation not supported
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
    } catch (e) {
      print('Token revocation error: $e');
    }
  }
}
```

### 2.5 Local Data Source Interface

**File**: `lib/features/auth/data/datasources/auth_local_datasource.dart`

```dart
import '../models/token_model.dart';

/// Local data source interface for token storage
abstract class AuthLocalDataSource {
  /// Save token to secure storage
  /// Throws: StorageException
  Future<void> saveToken(TokenModel token);

  /// Load token from secure storage
  /// Returns: TokenModel or null if not found
  /// Throws: StorageException
  Future<TokenModel?> loadToken();

  /// Delete token from storage
  /// Throws: StorageException
  Future<void> deleteToken();

  /// Delete all auth data
  /// Throws: StorageException
  Future<void> clearAllData();
}
```

### 2.6 Local Data Source Implementation

**File**: `lib/features/auth/data/datasources/auth_local_datasource_impl.dart`

```dart
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../infrastructure/services/secure_storage_service.dart';
import '../models/token_model.dart';
import 'auth_local_datasource.dart';

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _secureStorage;

  static const String _tokenKey = 'oauth_token';

  AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> saveToken(TokenModel token) async {
    try {
      final tokenJson = jsonEncode(token.toJson());
      await _secureStorage.write(key: _tokenKey, value: tokenJson);
    } catch (e) {
      throw StorageException(message: 'Failed to save token: $e');
    }
  }

  @override
  Future<TokenModel?> loadToken() async {
    try {
      final tokenJson = await _secureStorage.read(key: _tokenKey);

      if (tokenJson == null) {
        return null;
      }

      final tokenMap = jsonDecode(tokenJson) as Map<String, dynamic>;
      return TokenModel.fromJson(tokenMap);
    } catch (e) {
      throw StorageException(message: 'Failed to load token: $e');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw StorageException(message: 'Failed to delete token: $e');
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw StorageException(message: 'Failed to clear auth data: $e');
    }
  }
}
```

### 2.7 Repository Implementation

**File**: `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'package:injectable/injectable.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/token.dart';
import '../../domain/entities/oauth_flow_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/services/pkce_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final PKCEService _pkceService;

  // Store current flow state (code verifier, state parameter)
  OAuthFlowState? _currentFlowState;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._pkceService,
  );

  @override
  Future<Result<String>> generateAuthorizationUrl() async {
    try {
      // Generate PKCE codes
      final codeVerifier = _pkceService.generateCodeVerifier();
      final codeChallenge = _pkceService.generateCodeChallenge(codeVerifier);
      final state = _pkceService.generateState();

      // Store flow state for later validation
      _currentFlowState = OAuthFlowState(
        codeVerifier: codeVerifier,
        state: state,
      );

      // Build authorization URL
      final url = await _remoteDataSource.buildAuthorizationUrl(
        codeChallenge: codeChallenge,
        state: state,
      );

      return Success(url);
    } on OAuthException catch (e) {
      return Failure(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Failure(AuthFailure(message: 'Failed to generate auth URL: $e'));
    }
  }

  @override
  Result<OAuthFlowState?> getCurrentFlowState() {
    try {
      return Success(_currentFlowState);
    } catch (e) {
      return Failure(AuthFailure(message: 'Failed to get flow state: $e'));
    }
  }

  @override
  Future<Result<Token>> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
      );

      final token = tokenModel.toDomain();

      // Clear flow state after successful exchange
      _currentFlowState = null;

      return Success(token);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Failure(AuthFailure(
        message: e.message,
        code: e.code,
      ));
    } on OAuthException catch (e) {
      return Failure(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Failure(AuthFailure(message: 'Token exchange failed: $e'));
    }
  }

  @override
  Future<Result<Token>> refreshToken(String refreshToken) async {
    try {
      final tokenModel = await _remoteDataSource.refreshAccessToken(
        refreshToken,
      );

      return Success(tokenModel.toDomain());
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      if (e.statusCode == 401 || e.code == 'invalid_grant') {
        return const Failure(TokenExpiredFailure());
      }
      return Failure(AuthFailure(message: e.message, code: e.code));
    } on OAuthException catch (e) {
      return Failure(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      return Failure(AuthFailure(message: 'Token refresh failed: $e'));
    }
  }

  @override
  Future<Result<void>> saveToken(Token token) async {
    try {
      final tokenModel = TokenModel.fromDomain(token);
      await _localDataSource.saveToken(tokenModel);
      return const Success(null);
    } on StorageException catch (e) {
      return Failure(StorageFailure(message: e.message));
    } catch (e) {
      return Failure(StorageFailure(message: 'Failed to save token: $e'));
    }
  }

  @override
  Future<Result<Token?>> loadSavedToken() async {
    try {
      final tokenModel = await _localDataSource.loadToken();

      if (tokenModel == null) {
        return const Success(null);
      }

      return Success(tokenModel.toDomain());
    } on StorageException catch (e) {
      return Failure(StorageFailure(message: e.message));
    } catch (e) {
      return Failure(StorageFailure(message: 'Failed to load token: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Load current token to revoke
      final tokenModel = await _localDataSource.loadToken();

      if (tokenModel != null) {
        // Revoke on server (best effort)
        await _remoteDataSource.revokeToken(tokenModel.accessToken);
      }

      // Clear local storage
      await _localDataSource.deleteToken();

      // Clear flow state
      _currentFlowState = null;

      return const Success(null);
    } on StorageException catch (e) {
      return Failure(StorageFailure(message: e.message));
    } catch (e) {
      // Even if revocation fails, clear local data
      try {
        await _localDataSource.deleteToken();
        _currentFlowState = null;
        return const Success(null);
      } catch (clearError) {
        return Failure(StorageFailure(
          message: 'Logout failed: $clearError',
        ));
      }
    }
  }

  @override
  Future<Result<void>> clearAuthData() async {
    try {
      await _localDataSource.clearAllData();
      _currentFlowState = null;
      return const Success(null);
    } on StorageException catch (e) {
      return Failure(StorageFailure(message: e.message));
    } catch (e) {
      return Failure(StorageFailure(message: 'Failed to clear data: $e'));
    }
  }
}
```

---

## Layer 3: Infrastructure Layer (Platform Adapters)

### Responsibilities
- Handle platform-specific code (web vs desktop)
- Browser launching
- Redirect URI handling (web callback route, desktop local HTTP server)
- PKCE generation (cryptographic operations)
- Secure storage abstraction
- **NO** business logic or state management

### 3.1 PKCE Service

**File**: `lib/features/auth/infrastructure/services/pkce_service.dart`

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PKCEService {
  /// Generate cryptographically secure code verifier
  String generateCodeVerifier() {
    const length = 128;
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generate code challenge from code verifier (S256 method)
  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);

    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Generate state parameter for CSRF protection
  String generateState() {
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
```

### 3.2 Secure Storage Service

**File**: `lib/features/auth/infrastructure/services/secure_storage_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Abstraction over platform-specific secure storage
@lazySingleton
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
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

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

### 3.3 OAuth Launcher (Platform-Specific)

**File**: `lib/features/auth/infrastructure/adapters/oauth_launcher.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

/// Platform-specific OAuth browser launcher
@lazySingleton
class OAuthLauncher {
  /// Launch OAuth URL in browser
  /// Web: Same-window navigation
  /// Desktop: External browser
  Future<bool> launchOAuthUrl(String url) async {
    final uri = Uri.parse(url);

    if (kIsWeb) {
      // Web: Navigate in same window (will redirect back to callback route)
      return await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      // Desktop: Open in external browser
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
```

### 3.4 Web Callback Handler

**File**: `lib/features/auth/infrastructure/adapters/web_callback_handler.dart`

```dart
import 'package:injectable/injectable.dart';

/// Handles web callback URI parsing
@lazySingleton
class WebCallbackHandler {
  /// Parse callback URI for authorization code and state
  /// Returns map with 'code' and 'state' keys
  /// Throws if error parameter present
  Map<String, String> parseCallbackUri(Uri callbackUri) {
    final params = callbackUri.queryParameters;

    // Check for OAuth errors
    if (params.containsKey('error')) {
      final error = params['error'];
      final description = params['error_description'];
      throw Exception(description ?? error ?? 'OAuth error');
    }

    // Extract code and state
    final code = params['code'];
    final state = params['state'];

    if (code == null || state == null) {
      throw Exception('Missing code or state in callback');
    }

    return {
      'code': code,
      'state': state,
    };
  }
}
```

### 3.5 Desktop Callback Server

**File**: `lib/features/auth/infrastructure/adapters/desktop_callback_server.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Local HTTP server for desktop OAuth callback
@lazySingleton
class DesktopCallbackServer {
  HttpServer? _server;
  Completer<Map<String, String>>? _completer;

  static const int _defaultPort = 8080;
  static const String _callbackPath = '/callback';

  /// Start local server and wait for callback
  /// Returns map with 'code' and 'state' keys
  /// Throws on timeout or error
  Future<Map<String, String>> waitForCallback({
    int port = _defaultPort,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    _completer = Completer<Map<String, String>>();

    try {
      // Start server
      _server = await shelf_io.serve(
        _handleRequest,
        InternetAddress.loopbackIPv4,
        port,
      );

      print('OAuth callback server listening on http://localhost:${_server!.port}$_callbackPath');

      // Wait for callback with timeout
      final result = await _completer!.future.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('OAuth callback timeout - user did not complete login');
        },
      );

      return result;
    } finally {
      await stopServer();
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

      _completer?.completeError(
        Exception(description ?? error ?? 'OAuth error'),
      );

      return shelf.Response.ok(
        _htmlResponse(
          'Authorization Failed',
          'Error: ${description ?? error}',
          isError: true,
        ),
        headers: {'Content-Type': 'text/html'},
      );
    }

    // Extract code and state
    final code = params['code'];
    final state = params['state'];

    if (code == null || state == null) {
      _completer?.completeError(
        Exception('Missing code or state in callback'),
      );

      return shelf.Response.ok(
        _htmlResponse(
          'Authorization Failed',
          'Missing authorization parameters.',
          isError: true,
        ),
        headers: {'Content-Type': 'text/html'},
      );
    }

    // Success
    _completer?.complete({
      'code': code,
      'state': state,
    });

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
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
      ${!isError ? 'setTimeout(() => window.close(), 3000);' : ''}
    </script>
  </div>
</body>
</html>
''';
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _completer = null;
  }
}
```

---

## Layer 4: Presentation Layer (BLoC)

### Responsibilities
- React to UI events
- Call use cases
- Emit UI states
- **NO** business logic, networking, storage, or platform code

### 4.1 Auth Events

**File**: `lib/features/auth/presentation/bloc/auth_event.dart`

```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App started - check for existing token
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// User clicked login button
class LoginRequested extends AuthEvent {
  const LoginRequested();
}

/// OAuth callback received (web or desktop)
class OAuthCallbackReceived extends AuthEvent {
  final String code;
  final String state;

  const OAuthCallbackReceived({
    required this.code,
    required this.state,
  });

  @override
  List<Object?> get props => [code, state];
}

/// Token refresh needed
class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}

/// User clicked logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
```

### 4.2 Auth States

**File**: `lib/features/auth/presentation/bloc/auth_state.dart`

```dart
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading (checking existing token)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Redirect to OAuth provider
class RedirectToOAuth extends AuthState {
  final String authorizationUrl;

  const RedirectToOAuth(this.authorizationUrl);

  @override
  List<Object?> get props => [authorizationUrl];
}

/// Processing OAuth callback
class ProcessingCallback extends AuthState {
  const ProcessingCallback();
}

/// Successfully authenticated
class Authenticated extends AuthState {
  final String? message; // Optional success message

  const Authenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// Error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Logged out
class LoggedOut extends AuthState {
  const LoggedOut();
}
```

### 4.3 Auth BLoC

**File**: `lib/features/auth/presentation/bloc/auth_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/generate_auth_url_usecase.dart';
import '../../domain/usecases/exchange_code_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/load_saved_token_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/utils/result.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@singleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GenerateAuthUrlUseCase _generateAuthUrl;
  final ExchangeCodeUseCase _exchangeCode;
  final RefreshTokenUseCase _refreshToken;
  final LoadSavedTokenUseCase _loadSavedToken;
  final LogoutUseCase _logout;

  AuthBloc(
    this._generateAuthUrl,
    this._exchangeCode,
    this._refreshToken,
    this._loadSavedToken,
    this._logout,
  ) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<OAuthCallbackReceived>(_onOAuthCallbackReceived);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  /// Check for existing token on app start
  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loadSavedToken();

    result.fold(
      onSuccess: (token) {
        if (token == null) {
          emit(const Unauthenticated());
        } else if (token.isValid) {
          emit(const Authenticated());
        } else if (token.canRefresh) {
          // Token expired but can refresh
          add(const TokenRefreshRequested());
        } else {
          emit(const Unauthenticated());
        }
      },
      onFailure: (failure) {
        emit(const Unauthenticated());
      },
    );
  }

  /// User clicked login - generate OAuth URL
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _generateAuthUrl();

    result.fold(
      onSuccess: (url) {
        // Emit state with URL - UI layer handles browser launch
        emit(RedirectToOAuth(url));
      },
      onFailure: (failure) {
        emit(AuthError(failure.message));
        emit(const Unauthenticated());
      },
    );
  }

  /// OAuth callback received - exchange code for token
  Future<void> _onOAuthCallbackReceived(
    OAuthCallbackReceived event,
    Emitter<AuthState> emit,
  ) async {
    emit(const ProcessingCallback());

    final result = await _exchangeCode(
      code: event.code,
      state: event.state,
    );

    result.fold(
      onSuccess: (token) {
        emit(const Authenticated(message: 'Login successful'));
      },
      onFailure: (failure) {
        emit(AuthError(failure.message));
        emit(const Unauthenticated());
      },
    );
  }

  /// Refresh token
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshToken();

    result.fold(
      onSuccess: (token) {
        emit(const Authenticated());
      },
      onFailure: (failure) {
        emit(AuthError(failure.message));
        emit(const Unauthenticated());
      },
    );
  }

  /// Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _logout();

    result.fold(
      onSuccess: (_) {
        emit(const LoggedOut());
      },
      onFailure: (failure) {
        // Even if logout fails, clear session
        emit(const LoggedOut());
      },
    );
  }
}
```

### 4.4 Login Page

**File**: `lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/config/oauth_config.dart';
import '../../../../core/di/injection.dart';
import '../../infrastructure/adapters/oauth_launcher.dart';
import '../../infrastructure/adapters/desktop_callback_server.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate to dashboard
          context.go(AppRoutes.dashboard);
        } else if (state is RedirectToOAuth) {
          // Launch OAuth flow
          _handleOAuthRedirect(context, state.authorizationUrl);
        } else if (state is AuthError) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Carbon Voice Console'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AuthState state) {
    if (state is AuthLoading || state is ProcessingCallback) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            state is AuthLoading ? 'Loading...' : 'Completing authentication...',
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
          onPressed: OAuthConfig.isConfigured && state is! RedirectToOAuth
              ? () => context.read<AuthBloc>().add(const LoginRequested())
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
      ],
    );
  }

  Future<void> _handleOAuthRedirect(BuildContext context, String url) async {
    final launcher = getIt<OAuthLauncher>();

    if (kIsWeb) {
      // Web: Launch OAuth URL (will redirect to callback route)
      await launcher.launchOAuthUrl(url);
    } else {
      // Desktop: Launch browser and wait for local server callback
      final server = getIt<DesktopCallbackServer>();

      try {
        // Launch browser
        await launcher.launchOAuthUrl(url);

        // Wait for callback
        final callbackData = await server.waitForCallback();

        // Send callback to BLoC
        if (context.mounted) {
          context.read<AuthBloc>().add(OAuthCallbackReceived(
                code: callbackData['code']!,
                state: callbackData['state']!,
              ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OAuth failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
          context.read<AuthBloc>().add(const AppStarted());
        }
      }
    }
  }
}
```

### 4.5 OAuth Callback Page (Web Only)

**File**: `lib/features/auth/presentation/pages/oauth_callback_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/di/injection.dart';
import '../../infrastructure/adapters/web_callback_handler.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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
    try {
      final handler = getIt<WebCallbackHandler>();
      final callbackData = handler.parseCallbackUri(Uri.base);

      context.read<AuthBloc>().add(OAuthCallbackReceived(
            code: callbackData['code']!,
            state: callbackData['state']!,
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OAuth callback error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go(AppRoutes.login);
            }
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

---

## Configuration & Dependency Injection

### OAuth Configuration

**File**: `lib/core/config/oauth_config.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OAuthConfig {
  OAuthConfig._();

  static String get authorizationUrl =>
      dotenv.env['OAUTH_AUTHORIZATION_URL'] ?? '';

  static String get tokenUrl =>
      dotenv.env['OAUTH_TOKEN_URL'] ?? '';

  static String get revokeUrl =>
      dotenv.env['OAUTH_REVOKE_URL'] ?? '';

  static String get clientId =>
      dotenv.env['OAUTH_CLIENT_ID'] ?? '';

  static String get redirectUri {
    if (kIsWeb) {
      return dotenv.env['OAUTH_REDIRECT_URI_WEB'] ??
             'http://localhost:5000/auth/callback';
    } else {
      return dotenv.env['OAUTH_REDIRECT_URI_DESKTOP'] ??
             'http://localhost:8080/callback';
    }
  }

  static String get scopes =>
      dotenv.env['OAUTH_SCOPES'] ?? 'read:memos';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.carbonvoice.app';

  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;

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
      return 'Missing: ${missing.join(', ')}';
    }
    return 'Configured';
  }
}
```

### Dependency Injection Module

**File**: Update `lib/core/di/register_module.dart`

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/oauth_config.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(
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
}
```

---

## Implementation Phases

### Phase 1: Setup Dependencies & Configuration

**Files to Create/Update**:
1. Update `pubspec.yaml` with dependencies
2. Create `.env.example` with placeholders
3. Create `lib/core/config/oauth_config.dart`
4. Create `lib/core/utils/result.dart`
5. Create `lib/core/errors/failures.dart`
6. Create `lib/core/errors/exceptions.dart`

**Success Criteria**:
- [ ] `flutter pub get` succeeds
- [ ] `.env.example` created
- [ ] `OAuthConfig` compiles
- [ ] `Result<T>` type works

### Phase 2: Domain Layer

**Files to Create**:
1. `lib/features/auth/domain/entities/token.dart`
2. `lib/features/auth/domain/entities/oauth_flow_state.dart`
3. `lib/features/auth/domain/repositories/auth_repository.dart`
4. All use case files (6 total)

**Success Criteria**:
- [ ] All domain files compile
- [ ] Zero Flutter imports in domain layer
- [ ] Use cases use only domain types
- [ ] Repository interface complete

### Phase 3: Infrastructure Layer

**Files to Create**:
1. `lib/features/auth/infrastructure/services/pkce_service.dart`
2. `lib/features/auth/infrastructure/services/secure_storage_service.dart`
3. `lib/features/auth/infrastructure/adapters/oauth_launcher.dart`
4. `lib/features/auth/infrastructure/adapters/web_callback_handler.dart`
5. `lib/features/auth/infrastructure/adapters/desktop_callback_server.dart`

**Success Criteria**:
- [ ] PKCE generation works
- [ ] Secure storage abstraction compiles
- [ ] Platform adapters handle web/desktop

### Phase 4: Data Layer

**Files to Create**:
1. `lib/features/auth/data/models/token_model.dart`
2. `lib/features/auth/data/datasources/auth_remote_datasource.dart`
3. `lib/features/auth/data/datasources/auth_remote_datasource_impl.dart`
4. `lib/features/auth/data/datasources/auth_local_datasource.dart`
5. `lib/features/auth/data/datasources/auth_local_datasource_impl.dart`
6. `lib/features/auth/data/repositories/auth_repository_impl.dart`

**Success Criteria**:
- [ ] Generate code: `dart run build_runner build`
- [ ] Repository returns `Result<T>`
- [ ] Exceptions mapped to failures
- [ ] No BLoC types in data layer

### Phase 5: Presentation Layer

**Files to Create**:
1. `lib/features/auth/presentation/bloc/auth_event.dart`
2. `lib/features/auth/presentation/bloc/auth_state.dart`
3. `lib/features/auth/presentation/bloc/auth_bloc.dart`
4. `lib/features/auth/presentation/pages/login_page.dart`
5. `lib/features/auth/presentation/pages/oauth_callback_page.dart`

**Success Criteria**:
- [ ] BLoC only calls use cases
- [ ] No networking in BLoC
- [ ] No storage in BLoC
- [ ] States are UI-focused

### Phase 6: Integration & Testing

**Tasks**:
1. Register all dependencies
2. Update router with callback route
3. Provide BLoC to app
4. Add routing guards
5. Test complete flow

**Success Criteria**:
- [ ] DI generation succeeds
- [ ] Web OAuth flow works
- [ ] Desktop OAuth flow works
- [ ] Token persistence works
- [ ] Refresh works
- [ ] Logout works

---

## Testing Strategy

### Unit Tests

**Domain Layer**:
```dart
// test/features/auth/domain/usecases/exchange_code_usecase_test.dart
void main() {
  late ExchangeCodeUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ExchangeCodeUseCase(mockRepository);
  });

  test('should validate state parameter', () async {
    when(mockRepository.getCurrentFlowState())
        .thenReturn(Success(OAuthFlowState(
          codeVerifier: 'verifier',
          state: 'state123',
        )));

    final result = await useCase(code: 'code', state: 'wrong_state');

    expect(result, isA<Failure>());
    expect((result as Failure).failure, isA<InvalidStateFailure>());
  });

  test('should exchange code when state is valid', () async {
    final flowState = OAuthFlowState(
      codeVerifier: 'verifier',
      state: 'state123',
    );
    final token = Token(
      accessToken: 'access',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
    );

    when(mockRepository.getCurrentFlowState())
        .thenReturn(Success(flowState));
    when(mockRepository.exchangeCodeForToken(
      code: anyNamed('code'),
      codeVerifier: anyNamed('codeVerifier'),
    )).thenAnswer((_) async => Success(token));
    when(mockRepository.saveToken(any))
        .thenAnswer((_) async => const Success(null));

    final result = await useCase(code: 'code', state: 'state123');

    expect(result, isA<Success<Token>>());
    verify(mockRepository.saveToken(token)).called(1);
  });
}
```

**BLoC Tests**:
```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart
void main() {
  late AuthBloc authBloc;
  late MockGenerateAuthUrlUseCase mockGenerateAuthUrl;
  late MockLoadSavedTokenUseCase mockLoadSavedToken;

  setUp(() {
    mockGenerateAuthUrl = MockGenerateAuthUrlUseCase();
    mockLoadSavedToken = MockLoadSavedTokenUseCase();
    // ... other mocks

    authBloc = AuthBloc(
      mockGenerateAuthUrl,
      // ... other dependencies
    );
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, Authenticated] when valid token exists',
    build: () {
      when(mockLoadSavedToken())
          .thenAnswer((_) async => Success(validToken));
      return authBloc;
    },
    act: (bloc) => bloc.add(const AppStarted()),
    expect: () => [
      const AuthLoading(),
      const Authenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [RedirectToOAuth] when login requested',
    build: () {
      when(mockGenerateAuthUrl())
          .thenAnswer((_) async => Success('https://oauth.url'));
      return authBloc;
    },
    act: (bloc) => bloc.add(const LoginRequested()),
    expect: () => [
      RedirectToOAuth('https://oauth.url'),
    ],
  );
}
```

---

## Architecture Validation Checklist

### Domain Layer ✅
- [ ] No Flutter imports
- [ ] No HTTP client imports
- [ ] No storage imports
- [ ] Only `Result<T>` returns (no exceptions)
- [ ] Use cases orchestrate business rules
- [ ] Entities are pure data classes

### Data Layer ✅
- [ ] No BLoC imports
- [ ] No widget imports
- [ ] Exceptions caught and mapped to failures
- [ ] Repository delegates to data sources
- [ ] Models handle JSON serialization

### Presentation Layer ✅
- [ ] BLoC only calls use cases
- [ ] No networking code
- [ ] No storage code
- [ ] No PKCE generation
- [ ] States are UI-focused

### Infrastructure Layer ✅
- [ ] Platform-specific code isolated
- [ ] No business logic
- [ ] No state management
- [ ] Services are reusable

---

## Summary

This clean architecture implementation provides:

✅ **Strict Layer Separation** - Each layer has explicit, single responsibility
✅ **Testable** - Pure functions, dependency injection, mockable interfaces
✅ **Scalable** - Easy to add new features, swap implementations
✅ **Maintainable** - Clear boundaries, readable code structure
✅ **Production-Ready** - Error handling, security, platform support
✅ **Senior-Level Standard** - Suitable as hiring reference

**Key Architectural Decisions**:
1. BLoC is a thin coordinator - only calls use cases and emits states
2. All business logic lives in use cases
3. Repository is the only bridge between domain and data
4. Platform-specific code is isolated in infrastructure layer
5. Error handling uses Result<T> type (no exceptions in domain/presentation)
6. Dependencies flow inward (presentation → domain ← data ← infrastructure)

This implementation follows SOLID principles, Clean Architecture, and Flutter best practices.
