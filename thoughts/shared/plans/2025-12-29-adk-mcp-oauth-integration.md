# ADK MCP OAuth2 Authentication Integration Plan

## Overview

This plan details the integration of OAuth2 authentication for MCP (Model Context Protocol) servers within the agent chat feature. When users interact with the agent and request operations requiring external authentication (GitHub, Carbon Voice, etc.), the agent will emit a special `adk_request_credential` function call event via SSE. The Flutter application will detect this event, launch the OAuth flow in a browser/webview, capture the callback, and submit the credentials back to the agent to continue processing.

## Current State Analysis

### What Exists Now

**Agent Configuration** ([agent/agent/agent.py](agent/agent/agent.py:37-145))
- Root orchestrator agent with three sub-agents:
  - **GitHub Agent** (lines 37-73): Requires OAuth2 with scopes `repo`, `user`, `read:org`
  - **Carbon Voice Agent** (lines 77-114): Requires OAuth2 with scopes `files:read`, `files:write`
  - **Atlassian Agent** (lines 117-137): Uses MCP remote connection (no OAuth configured yet)
- Each agent configured with `auth_scheme` (OAuth2 flows) and `auth_credential` (client credentials)

**Existing OAuth Infrastructure**
- **PKCE-based OAuth flow** for Carbon Voice API authentication ([lib/features/auth/data/repositories/oauth_repository_impl.dart](lib/features/auth/data/repositories/oauth_repository_impl.dart))
- **Platform-specific token storage**:
  - Web: `localStorage` for credentials, `sessionStorage` for OAuth state
  - Desktop: File-based storage with base64 encoding (workaround for keychain issues)
- **Deep linking service** for desktop OAuth callbacks ([lib/core/services/deep_linking_service.dart](lib/core/services/deep_linking_service.dart))
- **URL scheme registration**: `carbonvoice://` registered in [macos/Runner/Info.plist](macos/Runner/Info.plist:46-58)

**SSE Event Processing** ([lib/features/agent_chat/data/datasources/adk_api_service.dart](lib/features/agent_chat/data/datasources/adk_api_service.dart:114-174))
- Connects to `/run_sse` endpoint with POST request
- Parses SSE format: `"data: {...}\n\n"`
- Events deserialized into `EventDto` with structure:
  - `content.role`: "user" or "model"
  - `content.parts[]`: Array containing `text` messages
  - `actions.functionCalls[]`: Array of function calls with `{name, args}`
  - `actions.functionResponses[]`: Array of function responses with `{name, response}`

**Current Event Handling**
- **Text messages**: Converted to `AgentChatMessage` and displayed in UI
- **Function calls**: Currently not being processed from `actions.functionCalls[]`
- **No handling for `adk_request_credential`**: This is the missing piece

### What's Missing

1. **Event detection** for `adk_request_credential` in `actions.functionCalls[]`
2. **AuthConfig extraction** from function call arguments
3. **OAuth callback URL capture** (client-side only, no token exchange)
4. **Function response submission** back to agent with callback URL
5. **UI for OAuth authorization** during active chat sessions

### Important: Token Security Model

**Client does NOT handle tokens** - The secure flow is:
1. Client detects `adk_request_credential` function call
2. Client opens OAuth authorization URL in browser
3. User authorizes at provider (GitHub, Carbon Voice)
4. Provider redirects back with authorization code in URL
5. **Client captures the full callback URL** (with code and state)
6. **Client sends callback URL to ADK backend** via function response
7. **ADK backend exchanges code for token** and stores it securely
8. Client never sees or stores access tokens

This follows the ADK documentation pattern where the client only provides `auth_response_uri` (the callback URL), and the backend handles all token operations.

### Key Constraints Discovered

- **SSE is unidirectional** (server → client): Cannot inject function response mid-stream
- **Must resume session** with new message containing `FunctionResponse` content
- **Function call ID** must be preserved to correlate request/response
- **Multiple providers**: Need provider-specific OAuth configs (GitHub, Carbon Voice MCP, Atlassian)
- **Platform differences**: Web vs Desktop OAuth callback handling

## Desired End State

### User Experience Flow

1. User sends message: "Show me my GitHub repositories"
2. Agent attempts to call GitHub MCP tool
3. Agent detects missing credentials, emits `adk_request_credential` in `actions.functionCalls[]`
4. UI shows: "🔐 GitHub authentication required" with "Authorize" button
5. User clicks "Authorize" → Browser opens to GitHub OAuth page
6. User authorizes → Provider redirects back to app with authorization code in URL
7. **App captures the full callback URL** (e.g., `carbonvoice://callback?code=abc&state=xyz`)
8. **App submits callback URL to ADK backend** via `FunctionResponse` with `auth_response_uri`
9. **ADK backend exchanges code for token** and stores it securely (client never sees token)
10. Agent retries original tool call with valid credentials from backend
11. Chat continues seamlessly with GitHub data

### Verification Criteria

**Automated Verification:**
- [ ] New DTOs compile without errors: `dart run build_runner build`
- [ ] All unit tests pass: `flutter test`
- [ ] No linting errors: `dart analyze`
- [ ] Code generation produces valid serialization code

**Manual Verification:**
- [ ] Agent emits `adk_request_credential` in `actions.functionCalls[]` when prompting "Show me my GitHub repos" (without prior auth)
- [ ] UI displays OAuth authorization button when credential request detected
- [ ] Clicking "Authorize" opens GitHub OAuth page in browser
- [ ] After authorization, callback URL is captured (with code and state parameters)
- [ ] Function response with `auth_response_uri` is successfully submitted back to agent
- [ ] Agent continues with original request (backend has exchanged code for token)
- [ ] Subsequent requests to same provider use backend-cached credentials (no re-auth)
- [ ] Multiple providers (GitHub, Carbon Voice) can be authorized independently
- [ ] Client never stores or logs access tokens (only callback URLs)

## What We're NOT Doing

- **Not exchanging tokens on client side** (ADK backend handles token exchange and storage)
- **Not storing access/refresh tokens in Flutter app** (only callback URLs are handled client-side)
- **Not implementing token refresh** (backend responsibility, client just triggers re-auth if needed)
- **Not building a credentials management UI** (v1 is inline auth only)
- **Not supporting multiple accounts per provider** (one GitHub account, one Carbon Voice account)
- **Not implementing Atlassian OAuth** (agent config shows it doesn't require OAuth yet)
- **Not modifying the agent Python code** (only Flutter changes)

## Implementation Approach

We'll extend the existing SSE event processing to detect `adk_request_credential` function calls in the `actions.functionCalls[]` array, extract OAuth configuration from the arguments, launch the OAuth flow in a browser, capture the callback URL, and submit it back to the agent via function response. The ADK backend handles all token operations.

**Simplified client responsibilities:**
1. **Detect credential requests** in `actions.functionCalls[]`
2. **Open authorization URL** in browser (from `authConfig.exchangedAuthCredential.oauth2.auth_uri`)
3. **Capture callback URL** via deep linking (desktop) or route handling (web)
4. **Submit callback URL** to backend via function response (as `auth_response_uri`)
5. **Display UI status** during OAuth flow

**Backend responsibilities (ADK agent):**
- Token exchange (code → access token)
- Secure token storage
- Token refresh (if applicable)
- Retry original tool call with credentials

The implementation follows the existing architecture:
- **Data layer**: Update `ActionsDto` to include `functionCalls[]`, create minimal OAuth DTOs for auth config
- **Domain layer**: Lightweight entities for providers (no credential entities needed - backend handles tokens)
- **Presentation layer**: BLoC for OAuth state, UI components for authorization prompts

---

## Phase 1: Data Layer - Event Models and Detection

### Overview
Update `ActionsDto` to include the `functionCalls[]` array, create DTOs for OAuth configuration, and add event detection logic to identify `adk_request_credential` function calls in the `actions` object.

### Changes Required

#### 1. Update ActionsDto to Include FunctionCalls Array
**File**: `lib/features/agent_chat/data/models/event_dto.dart`

**Current ActionsDto** (lines 100-115):
```dart
@JsonSerializable()
class ActionsDto {
  ActionsDto({
    this.stateDelta,
    this.artifactDelta,
  });

  factory ActionsDto.fromJson(Map<String, dynamic> json) =>
      _$ActionsDtoFromJson(json);

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;

  Map<String, dynamic> toJson() => _$ActionsDtoToJson(this);
}
```

**Updated ActionsDto** (add functionCalls and functionResponses):
```dart
@JsonSerializable()
class ActionsDto {
  ActionsDto({
    this.stateDelta,
    this.artifactDelta,
    this.functionCalls,      // NEW
    this.functionResponses,  // NEW
  });

  factory ActionsDto.fromJson(Map<String, dynamic> json) =>
      _$ActionsDtoFromJson(json);

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;
  final List<FunctionCallItemDto>? functionCalls;      // NEW
  final List<FunctionResponseItemDto>? functionResponses;  // NEW

  Map<String, dynamic> toJson() => _$ActionsDtoToJson(this);
}

/// Function call item in actions.functionCalls[] array
@JsonSerializable()
class FunctionCallItemDto {
  FunctionCallItemDto({
    required this.name,
    required this.args,
  });

  factory FunctionCallItemDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallItemDtoFromJson(json);

  final String name;
  final Map<String, dynamic> args;

  Map<String, dynamic> toJson() => _$FunctionCallItemDtoToJson(this);
}

/// Function response item in actions.functionResponses[] array
@JsonSerializable()
class FunctionResponseItemDto {
  FunctionResponseItemDto({
    required this.name,
    required this.response,
  });

  factory FunctionResponseItemDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseItemDtoFromJson(json);

  final String name;
  final Map<String, dynamic> response;

  Map<String, dynamic> toJson() => _$FunctionResponseItemDtoToJson(this);
}
```

#### 2. Add MCP Auth DTOs
**File**: `lib/features/agent_chat/data/models/mcp_auth_dto.dart` (NEW)

**Purpose**: Deserialize the `authConfig` object from `adk_request_credential` function call args

```dart
import 'package:json_annotation/json_annotation.dart';

part 'mcp_auth_dto.g.dart';

/// DTO for ADK request credential function call
@JsonSerializable()
class AdkRequestCredentialDto {
  AdkRequestCredentialDto({
    required this.authConfig,
  });

  factory AdkRequestCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$AdkRequestCredentialDtoFromJson(json);

  final AuthConfigDto authConfig;

  Map<String, dynamic> toJson() => _$AdkRequestCredentialDtoToJson(this);
}

/// DTO for auth configuration from ADK
@JsonSerializable()
class AuthConfigDto {
  AuthConfigDto({
    required this.exchangedAuthCredential,
  });

  factory AuthConfigDto.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigDtoFromJson(json);

  final ExchangedAuthCredentialDto exchangedAuthCredential;

  Map<String, dynamic> toJson() => _$AuthConfigDtoToJson(this);
}

/// DTO for exchanged auth credential
@JsonSerializable()
class ExchangedAuthCredentialDto {
  ExchangedAuthCredentialDto({
    required this.oauth2,
  });

  factory ExchangedAuthCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$ExchangedAuthCredentialDtoFromJson(json);

  final OAuth2ConfigDto oauth2;

  Map<String, dynamic> toJson() => _$ExchangedAuthCredentialDtoToJson(this);
}

/// DTO for OAuth2 configuration from ADK
@JsonSerializable()
class OAuth2ConfigDto {
  OAuth2ConfigDto({
    required this.authUri,
    required this.tokenUri,
    required this.clientId,
    required this.clientSecret,
    this.scopes,
    this.authResponseUri,
    this.redirectUri,
  });

  factory OAuth2ConfigDto.fromJson(Map<String, dynamic> json) =>
      _$OAuth2ConfigDtoFromJson(json);

  @JsonKey(name: 'auth_uri')
  final String authUri;

  @JsonKey(name: 'token_uri')
  final String tokenUri;

  @JsonKey(name: 'client_id')
  final String clientId;

  @JsonKey(name: 'client_secret')
  final String clientSecret;

  final List<String>? scopes;

  @JsonKey(name: 'auth_response_uri')
  String? authResponseUri;

  @JsonKey(name: 'redirect_uri')
  String? redirectUri;

  Map<String, dynamic> toJson() => _$OAuth2ConfigDtoToJson(this);
}
```

#### 3. Extend Event Mapper to Detect Credential Requests
**File**: `lib/features/agent_chat/data/mappers/event_mapper.dart`

**Add method** (after existing `getStatusMessage` method):

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/mcp_auth_dto.dart';

extension EventDtoMapper on EventDto {
  // ... existing toDomain and getStatusMessage methods ...

  /// Check if this event contains an adk_request_credential function call
  bool isCredentialRequest() {
    if (actions == null || actions!.functionCalls == null) return false;

    return actions!.functionCalls!.any((call) => call.name == 'adk_request_credential');
  }

  /// Extract credential request data if this is a credential request event
  /// Returns null if not a credential request
  CredentialRequestData? getCredentialRequest() {
    if (actions == null || actions!.functionCalls == null) return null;

    final credentialCalls = actions!.functionCalls!
        .where((call) => call.name == 'adk_request_credential')
        .toList();

    if (credentialCalls.isEmpty) return null;

    final call = credentialCalls.first;

    try {
      final requestDto = AdkRequestCredentialDto.fromJson(call.args);
      return CredentialRequestData(
        authConfig: requestDto.authConfig,
        provider: _extractProviderFromAuthor(author),
      );
    } catch (e) {
      // Log error and return null
      return null;
    }
  }

  /// Extract provider name from author field
  /// Examples: "github_agent" -> "github", "carbon_voice_agent" -> "carbon"
  String _extractProviderFromAuthor(String author) {
    if (author.contains('github')) return 'github';
    if (author.contains('carbon')) return 'carbon';
    if (author.contains('atlassian')) return 'atlassian';
    return 'unknown';
  }
}

/// Data class for credential request information
class CredentialRequestData {
  CredentialRequestData({
    required this.authConfig,
    required this.provider,
  });

  final AuthConfigDto authConfig;
  final String provider;
}
```

#### 4. Update Repository to Detect and Emit Credential Requests
**File**: `lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`

**Add new callback parameter** to `sendMessageStreaming` method signature (line 56):

```dart
Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
  required String sessionId,
  required String content,
  Map<String, dynamic>? context,
  Function(String status, String? subAgent)? onStatus,
  Function(String chunk)? onMessageChunk,
  Function(CredentialRequestData credentialRequest)? onCredentialRequest, // NEW
}) async {
```

**Add credential request detection** in event loop (after line 85):

```dart
// Check for credential requests - NEW CODE
if (eventDto.isCredentialRequest()) {
  final credentialRequest = eventDto.getCredentialRequest();
  if (credentialRequest != null && onCredentialRequest != null) {
    onCredentialRequest(credentialRequest);
  }
}
```

#### 5. Update Agent Chat Repository Interface
**File**: `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart`

**Update method signature** (add new callback parameter):

```dart
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';

abstract class AgentChatRepository {
  // ... existing methods ...

  Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
    Function(String status, String? subAgent)? onStatus,
    Function(String chunk)? onMessageChunk,
    Function(CredentialRequestData credentialRequest)? onCredentialRequest, // NEW
  });
}
```

### Success Criteria

#### Automated Verification:
- [ ] DTOs compile successfully: `dart run build_runner build --delete-conflicting-outputs`
- [ ] No analyzer errors: `dart analyze`
- [ ] Code follows linting rules: `dart fix --dry-run`

#### Manual Verification:
- [ ] When agent emits `adk_request_credential` in `actions.functionCalls[]`, `onCredentialRequest` callback is invoked
- [ ] `CredentialRequestData` contains valid `authConfig` and `provider`
- [ ] OAuth configuration includes `auth_uri`, `token_uri`, `client_id`, `client_secret`
- [ ] Provider is correctly identified from `author` field ("github", "carbon", etc.)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual testing with agent prompts that trigger authentication before proceeding to Phase 2.

---

## Phase 2: Domain Layer - MCP Provider Entity and Function Response Builder

### Overview
Create a lightweight MCP Provider entity to hold OAuth configuration extracted from `authConfig`, and add a helper to build the function response payload for submitting callback URLs to the ADK backend.

### Changes Required

#### 1. Create MCP Provider Entity
**File**: `lib/features/agent_chat/domain/entities/mcp_provider.dart` (NEW)

**Purpose**: Represent an MCP provider with OAuth configuration (lightweight, no credential storage)

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/mcp_auth_dto.dart';
import 'package:equatable/equatable.dart';

/// Represents an MCP provider that requires OAuth authentication
/// Note: This only holds config for the OAuth flow, NOT credentials/tokens
class McpProvider extends Equatable {
  const McpProvider({
    required this.id,
    required this.displayName,
    required this.authConfig,
  });

  /// Factory to build from ADK auth config
  factory McpProvider.fromAuthConfig({
    required String providerId,
    required AuthConfigDto authConfig,
  }) {
    String displayName;
    switch (providerId) {
      case 'github':
        displayName = 'GitHub';
        break;
      case 'carbon':
        displayName = 'Carbon Voice';
        break;
      case 'atlassian':
        displayName = 'Atlassian';
        break;
      default:
        displayName = providerId.toUpperCase();
    }

    return McpProvider(
      id: providerId,
      displayName: displayName,
      authConfig: authConfig,
    );
  }

  /// Unique identifier for this provider (e.g., "github", "carbon")
  final String id;

  /// User-facing display name (e.g., "GitHub", "Carbon Voice")
  final String displayName;

  /// OAuth configuration from ADK (contains auth_uri, token_uri, client_id, etc.)
  final AuthConfigDto authConfig;

  /// Get authorization URL from auth config
  String get authorizationUrl => authConfig.exchangedAuthCredential.oauth2.authUri;

  /// Get scopes from auth config
  List<String> get scopes => authConfig.exchangedAuthCredential.oauth2.scopes ?? [];

  @override
  List<Object?> get props => [id, displayName, authConfig];
}
```

#### 2. Create Function Response Builder Utility
**File**: `lib/features/agent_chat/domain/utils/mcp_oauth_utils.dart` (NEW)

**Purpose**: Build ADK function response payload for submitting OAuth callback URL

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/mcp_auth_dto.dart';

class McpOAuthUtils {
  /// Build function response content for ADK
  /// This submits the callback URL to the backend, which then handles token exchange
  static Map<String, dynamic> buildFunctionResponse({
    required AuthConfigDto authConfig,
    required String callbackUrl,
    required String redirectUri,
  }) {
    // Update auth config with callback URL and redirect URI
    authConfig.exchangedAuthCredential.oauth2.authResponseUri = callbackUrl;
    authConfig.exchangedAuthCredential.oauth2.redirectUri = redirectUri;

    // Build function response content matching ADK format
    // The function call name is always 'adk_request_credential'
    return {
      'role': 'user',
      'parts': [
        {
          'function_response': {
            'name': 'adk_request_credential',
            'response': authConfig.toJson(),
          },
        },
      ],
    };
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Entity and utility classes compile without errors: `dart analyze`
- [ ] `McpProvider` factory creates correct instances from auth config
- [ ] `McpOAuthUtils.buildFunctionResponse()` generates valid JSON structure
- [ ] Equatable implementations are correct (no missing props)

#### Manual Verification:
- [ ] Provider display names are correct for known providers (GitHub, Carbon Voice, Atlassian)
- [ ] Authorization URL is correctly extracted from auth config
- [ ] Function response payload matches ADK expected format

**Implementation Note**: This phase has no manual testing requirements. Proceed to Phase 3 immediately after automated verification passes.

---

## Phase 3: Data Layer - MCP OAuth Repository Implementation

### Overview
Implement the MCP OAuth repository with PKCE flow, platform-specific token storage, and function response building.

### Changes Required

#### 1. Create MCP OAuth Local Data Source
**File**: `lib/features/agent_chat/data/datasources/mcp_oauth_local_datasource.dart` (NEW)

**Purpose**: Handle secure storage of MCP provider credentials

```dart
import 'dart:convert';
import 'dart:io';

import 'package:carbon_voice_console/features/agent_chat/domain/entities/mcp_credentials.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as web;

abstract class McpOAuthLocalDataSource {
  Future<void> saveCredentials(String providerId, McpCredentials credentials);
  Future<McpCredentials?> loadCredentials(String providerId);
  Future<void> deleteCredentials(String providerId);
  Future<void> saveOAuthState(String providerId, String state, String codeVerifier);
  Future<Map<String, String>?> loadOAuthState(String providerId, String state);
  Future<void> clearOAuthState(String providerId, String state);
}

@LazySingleton(as: McpOAuthLocalDataSource)
class McpOAuthLocalDataSourceImpl implements McpOAuthLocalDataSource {
  McpOAuthLocalDataSourceImpl(this._storage, this._logger);

  final FlutterSecureStorage _storage;
  final Logger _logger;

  String _credentialsKey(String providerId) => 'mcp_credentials_$providerId';
  String _oauthStateKey(String providerId, String state) => 'mcp_oauth_state_${providerId}_$state';

  @override
  Future<void> saveCredentials(String providerId, McpCredentials credentials) async {
    final json = jsonEncode({
      'providerId': credentials.providerId,
      'accessToken': credentials.accessToken,
      'tokenType': credentials.tokenType,
      'expiresAt': credentials.expiresAt,
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
    });

    if (kIsWeb) {
      try {
        web.window.localStorage[_credentialsKey(providerId)] = json;
        _logger.d('MCP credentials saved to localStorage for provider: $providerId');
      } on Exception catch (e) {
        _logger.e('Error saving MCP credentials to localStorage', error: e);
      }
    } else {
      try {
        await _saveToFile(providerId, json);
        _logger.d('MCP credentials saved to file storage for provider: $providerId');
      } on Exception catch (e) {
        _logger.e('Error saving MCP credentials to file', error: e);
        rethrow;
      }
    }
  }

  @override
  Future<McpCredentials?> loadCredentials(String providerId) async {
    String? json;

    if (kIsWeb) {
      try {
        json = web.window.localStorage[_credentialsKey(providerId)];
      } on Exception catch (e) {
        _logger.e('Error loading MCP credentials from localStorage', error: e);
        return null;
      }
    } else {
      try {
        json = await _loadFromFile(providerId);
      } on Exception catch (e) {
        _logger.e('Error loading MCP credentials from file', error: e);
        return null;
      }
    }

    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return McpCredentials(
        providerId: data['providerId'] as String,
        accessToken: data['accessToken'] as String,
        tokenType: data['tokenType'] as String,
        expiresAt: data['expiresAt'] as int,
        refreshToken: data['refreshToken'] as String?,
        scopes: (data['scopes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      _logger.e('Error parsing MCP credentials', error: e);
      return null;
    }
  }

  @override
  Future<void> deleteCredentials(String providerId) async {
    if (kIsWeb) {
      try {
        web.window.localStorage.remove(_credentialsKey(providerId));
      } on Exception catch (e) {
        _logger.e('Error deleting MCP credentials from localStorage', error: e);
      }
    } else {
      try {
        final filePath = await _credentialsFilePath(providerId);
        final file = File(filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } on Exception catch (e) {
        _logger.e('Error deleting MCP credentials file', error: e);
      }
    }
  }

  @override
  Future<void> saveOAuthState(String providerId, String state, String codeVerifier) async {
    if (!kIsWeb) return;

    try {
      final data = {
        'providerId': providerId,
        'state': state,
        'codeVerifier': codeVerifier,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      web.window.sessionStorage[_oauthStateKey(providerId, state)] = jsonEncode(data);
    } on Exception catch (e) {
      _logger.e('Error saving MCP OAuth state', error: e);
    }
  }

  @override
  Future<Map<String, String>?> loadOAuthState(String providerId, String state) async {
    if (!kIsWeb) return null;

    try {
      final dataStr = web.window.sessionStorage[_oauthStateKey(providerId, state)];
      if (dataStr == null) return null;

      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      return {
        'providerId': data['providerId'] as String,
        'state': data['state'] as String,
        'codeVerifier': data['codeVerifier'] as String,
      };
    } on Exception catch (e) {
      _logger.e('Error loading MCP OAuth state', error: e);
      return null;
    }
  }

  @override
  Future<void> clearOAuthState(String providerId, String state) async {
    if (!kIsWeb) return;

    try {
      web.window.sessionStorage.remove(_oauthStateKey(providerId, state));
    } on Exception catch (e) {
      _logger.e('Error clearing MCP OAuth state', error: e);
    }
  }

  // File-based storage helpers (desktop)
  Future<String> _credentialsFilePath(String providerId) async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/mcp_credentials_$providerId.dat';
  }

  Future<void> _saveToFile(String providerId, String data) async {
    if (kIsWeb) return;
    final filePath = await _credentialsFilePath(providerId);
    final file = File(filePath);

    await file.parent.create(recursive: true);

    final encoded = base64Encode(utf8.encode(data));
    await file.writeAsString(encoded);
  }

  Future<String?> _loadFromFile(String providerId) async {
    if (kIsWeb) return null;
    try {
      final filePath = await _credentialsFilePath(providerId);
      final file = File(filePath);

      if (!file.existsSync()) return null;

      final encoded = await file.readAsString();
      final decoded = utf8.decode(base64Decode(encoded));
      return decoded;
    } on Exception catch (e) {
      _logger.e('Error reading MCP credentials file', error: e);
      return null;
    }
  }
}
```

#### 2. Implement MCP OAuth Repository
**File**: `lib/features/agent_chat/data/repositories/mcp_oauth_repository_impl.dart` (NEW)

**Purpose**: Implement OAuth flow for MCP providers

```dart
import 'dart:convert';

import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/pkce_generator.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/mcp_oauth_local_datasource.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/mcp_auth_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/mcp_credentials.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/mcp_provider.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/mcp_oauth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: McpOAuthRepository)
class McpOAuthRepositoryImpl implements McpOAuthRepository {
  McpOAuthRepositoryImpl(
    this._localDataSource,
    this._logger,
  );

  final McpOAuthLocalDataSource _localDataSource;
  final Logger _logger;

  // Store code verifiers for desktop OAuth
  final Map<String, String> _desktopOAuthStates = {};

  @override
  Future<Result<String>> getAuthorizationUrl({
    required McpProvider provider,
  }) async {
    try {
      final codeVerifier = PKCEGenerator.generateCodeVerifier();
      final codeChallenge = PKCEGenerator.generateCodeChallenge(codeVerifier);
      final state = PKCEGenerator.generateState();

      // Save state and code verifier
      if (kIsWeb) {
        await _localDataSource.saveOAuthState(provider.id, state, codeVerifier);
      } else {
        _desktopOAuthStates['${provider.id}_$state'] = codeVerifier;
      }

      // Build authorization URL
      final authUrl = Uri.parse(provider.authorizationUrl).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': provider.clientId,
          'redirect_uri': provider.redirectUri,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'scope': provider.scopes.join(' '),
          'state': state,
        },
      );

      return success(authUrl.toString());
    } catch (e, stack) {
      _logger.e('Error creating authorization URL for ${provider.id}', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<McpCredentials>> exchangeCodeForToken({
    required McpProvider provider,
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final tokenBody = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': provider.redirectUri,
        'client_id': provider.clientId,
        'client_secret': provider.clientSecret,
        'code_verifier': codeVerifier,
      };

      final tokenResponse = await http
          .post(
            Uri.parse(provider.tokenUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: tokenBody,
          )
          .timeout(const Duration(seconds: 30));

      if (tokenResponse.statusCode != 200) {
        _logger.e('Token exchange failed for ${provider.id}', error: tokenResponse.body);
        return failure(AuthFailure(
          code: 'TOKEN_EXCHANGE_FAILED',
          details: 'Token exchange failed: ${tokenResponse.body}',
        ));
      }

      final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;

      final expiresIn = tokenJson['expires_in'] as int? ?? 3600;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

      final credentials = McpCredentials(
        providerId: provider.id,
        accessToken: tokenJson['access_token'] as String,
        tokenType: tokenJson['token_type'] as String? ?? 'Bearer',
        expiresAt: expiresAt,
        refreshToken: tokenJson['refresh_token'] as String?,
        scopes: tokenJson['scope'] is List
            ? (tokenJson['scope'] as List).map((e) => e.toString()).toList()
            : (tokenJson['scope'] as String?)?.split(' ') ?? provider.scopes,
      );

      await _localDataSource.saveCredentials(provider.id, credentials);

      return success(credentials);
    } catch (e, stack) {
      _logger.e('Error exchanging code for token (${provider.id})', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveCredentials({
    required String providerId,
    required McpCredentials credentials,
  }) async {
    try {
      await _localDataSource.saveCredentials(providerId, credentials);
      return success(null);
    } catch (e) {
      _logger.e('Error saving credentials for $providerId', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<McpCredentials?>> loadCredentials({
    required String providerId,
  }) async {
    try {
      final credentials = await _localDataSource.loadCredentials(providerId);
      return success(credentials);
    } catch (e) {
      _logger.e('Error loading credentials for $providerId', error: e);
      return success(null);
    }
  }

  @override
  Future<Result<void>> deleteCredentials({
    required String providerId,
  }) async {
    try {
      await _localDataSource.deleteCredentials(providerId);
      return success(null);
    } catch (e) {
      _logger.e('Error deleting credentials for $providerId', error: e);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  McpProvider buildProviderFromAuthConfig({
    required String providerId,
    required AuthConfigDto authConfig,
  }) {
    final oauth2 = authConfig.exchangedAuthCredential.oauth2;

    // Determine display name from provider ID
    String displayName;
    switch (providerId) {
      case 'github':
        displayName = 'GitHub';
        break;
      case 'carbon':
        displayName = 'Carbon Voice';
        break;
      case 'atlassian':
        displayName = 'Atlassian';
        break;
      default:
        displayName = providerId.toUpperCase();
    }

    // Use custom redirect URI for MCP OAuth
    const redirectUri = 'carbonvoice://mcp-oauth-callback';

    return McpProvider(
      id: providerId,
      name: '${providerId}_agent',
      displayName: displayName,
      authorizationUrl: oauth2.authUri,
      tokenUrl: oauth2.tokenUri,
      clientId: oauth2.clientId,
      clientSecret: oauth2.clientSecret,
      scopes: oauth2.scopes ?? [],
      redirectUri: redirectUri,
    );
  }

  @override
  Map<String, dynamic> buildFunctionResponse({
    required String functionCallId,
    required AuthConfigDto authConfig,
    required String callbackUrl,
    required String redirectUri,
  }) {
    // Update auth config with callback URL and redirect URI
    authConfig.exchangedAuthCredential.oauth2.authResponseUri = callbackUrl;
    authConfig.exchangedAuthCredential.oauth2.redirectUri = redirectUri;

    // Build function response content matching ADK format
    return {
      'role': 'user',
      'parts': [
        {
          'function_response': {
            'id': functionCallId,
            'name': 'adk_request_credential',
            'response': authConfig.toJson(),
          },
        },
      ],
    };
  }

  /// Helper to retrieve code verifier by provider and state
  String? getCodeVerifier(String providerId, String state) {
    return _desktopOAuthStates['${providerId}_$state'];
  }

  /// Helper to remove code verifier after use
  void clearCodeVerifier(String providerId, String state) {
    _desktopOAuthStates.remove('${providerId}_$state');
  }
}
```

#### 3. Add Method to Submit Function Response
**File**: `lib/features/agent_chat/data/datasources/adk_api_service.dart`

**Add new method** after `sendMessageStreaming`:

```dart
/// Submit a function response to continue an agent session
/// Used for OAuth credential submission after user authorization
Future<void> submitFunctionResponse({
  required String sessionId,
  required String userId,
  required Map<String, dynamic> functionResponseContent,
}) async {
  try {
    final url = Uri.parse('${AdkConfig.baseUrl}/run_sse');

    final requestBody = {
      'appName': AdkConfig.appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': functionResponseContent,
      'streaming': false,
    };

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      _logger.e('Failed to submit function response: ${response.body}');
      throw Exception('Failed to submit function response: ${response.statusCode}');
    }

    _logger.d('Function response submitted successfully');
  } catch (e, stack) {
    _logger.e('Error submitting function response', error: e, stackTrace: stack);
    rethrow;
  }
}
```

#### 4. Update Repository to Expose Function Response Submission
**File**: `lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`

**Add new method**:

```dart
Future<Result<void>> submitFunctionResponse({
  required String sessionId,
  required String userId,
  required Map<String, dynamic> functionResponseContent,
}) async {
  try {
    await _apiService.submitFunctionResponse(
      sessionId: sessionId,
      userId: userId,
      functionResponseContent: functionResponseContent,
    );
    return success(null);
  } catch (e) {
    _logger.e('Error submitting function response', error: e);
    return failure(UnknownFailure(details: e.toString()));
  }
}
```

#### 5. Update Repository Interface
**File**: `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart`

**Add method signature**:

```dart
Future<Result<void>> submitFunctionResponse({
  required String sessionId,
  required String userId,
  required Map<String, dynamic> functionResponseContent,
});
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes: `dart run build_runner build --delete-conflicting-outputs`
- [ ] No analyzer errors: `dart analyze`
- [ ] All imports resolve correctly
- [ ] Injectable generates dependency injection code

#### Manual Verification:
- [ ] Authorization URL includes PKCE challenge and correct redirect URI
- [ ] Code verifier is stored correctly (web: sessionStorage, desktop: in-memory)
- [ ] Token exchange successfully retrieves access token
- [ ] Credentials are persisted to storage (web: localStorage, desktop: file)
- [ ] Function response payload matches ADK expected format
- [ ] `submitFunctionResponse` successfully posts to `/run_sse` endpoint

**Implementation Note**: After completing this phase and all automated verification passes, test the OAuth flow manually with a provider to verify token exchange before proceeding to Phase 4.

---

## Phase 4: Presentation Layer - MCP OAuth BLoC and Events

### Overview
Create BLoC for managing MCP OAuth state, handling credential requests, and coordinating the OAuth flow.

### Changes Required

#### 1. Create MCP OAuth Events
**File**: `lib/features/agent_chat/presentation/bloc/mcp_oauth_event.dart` (NEW)

```dart
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';
import 'package:equatable/equatable.dart';

abstract class McpOAuthEvent extends Equatable {
  const McpOAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event fired when agent requests credentials for an MCP provider
class CredentialRequested extends McpOAuthEvent {
  const CredentialRequested({
    required this.sessionId,
    required this.credentialRequest,
  });

  final String sessionId;
  final CredentialRequestData credentialRequest;

  @override
  List<Object?> get props => [sessionId, credentialRequest];
}

/// Event fired when user initiates OAuth authorization
class AuthorizationStarted extends McpOAuthEvent {
  const AuthorizationStarted({
    required this.providerId,
  });

  final String providerId;

  @override
  List<Object?> get props => [providerId];
}

/// Event fired when OAuth callback is received with authorization code
class AuthorizationCallbackReceived extends McpOAuthEvent {
  const AuthorizationCallbackReceived({
    required this.providerId,
    required String callbackUrl,
  }) : _callbackUrl = callbackUrl;

  final String providerId;
  final String _callbackUrl;

  String get callbackUrl => _callbackUrl;

  @override
  List<Object?> get props => [providerId, _callbackUrl];
}

/// Event fired when user dismisses the credential request
class CredentialRequestDismissed extends McpOAuthEvent {
  const CredentialRequestDismissed();
}
```

#### 2. Create MCP OAuth States
**File**: `lib/features/agent_chat/presentation/bloc/mcp_oauth_state.dart` (NEW)

```dart
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/mcp_provider.dart';
import 'package:equatable/equatable.dart';

abstract class McpOAuthState extends Equatable {
  const McpOAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no credential request pending
class McpOAuthIdle extends McpOAuthState {
  const McpOAuthIdle();
}

/// Credential request received, waiting for user to initiate authorization
class CredentialRequestPending extends McpOAuthState {
  const CredentialRequestPending({
    required this.sessionId,
    required this.credentialRequest,
    required this.provider,
  });

  final String sessionId;
  final CredentialRequestData credentialRequest;
  final McpProvider provider;

  @override
  List<Object?> get props => [sessionId, credentialRequest, provider];
}

/// User clicked authorize, opening browser/webview
class AuthorizationInProgress extends McpOAuthState {
  const AuthorizationInProgress({
    required this.providerId,
    required this.providerDisplayName,
  });

  final String providerId;
  final String providerDisplayName;

  @override
  List<Object?> get props => [providerId, providerDisplayName];
}

/// Processing OAuth callback (exchanging code for token)
class ProcessingCallback extends McpOAuthState {
  const ProcessingCallback({
    required this.providerId,
  });

  final String providerId;

  @override
  List<Object?> get props => [providerId];
}

/// Successfully authenticated and submitted credentials to agent
class AuthorizationComplete extends McpOAuthState {
  const AuthorizationComplete({
    required this.providerId,
    required this.providerDisplayName,
  });

  final String providerId;
  final String providerDisplayName;

  @override
  List<Object?> get props => [providerId, providerDisplayName];
}

/// OAuth flow failed
class McpOAuthError extends McpOAuthState {
  const McpOAuthError({
    required this.message,
    required this.providerId,
  });

  final String message;
  final String providerId;

  @override
  List<Object?> get props => [message, providerId];
}
```

#### 3. Create MCP OAuth BLoC
**File**: `lib/features/agent_chat/presentation/bloc/mcp_oauth_bloc.dart` (NEW)

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/mcp_oauth_repository.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

@injectable
class McpOAuthBloc extends Bloc<McpOAuthEvent, McpOAuthState> {
  McpOAuthBloc(
    this._mcpOAuthRepository,
    this._chatRepository,
    this._logger,
  ) : super(const McpOAuthIdle()) {
    on<CredentialRequested>(_onCredentialRequested);
    on<AuthorizationStarted>(_onAuthorizationStarted);
    on<AuthorizationCallbackReceived>(_onAuthorizationCallbackReceived);
    on<CredentialRequestDismissed>(_onCredentialRequestDismissed);
  }

  final McpOAuthRepository _mcpOAuthRepository;
  final AgentChatRepository _chatRepository;
  final Logger _logger;

  // Store current session and credential request for callback processing
  String? _currentSessionId;
  String? _currentUserId; // TODO: Get from auth context

  Future<void> _onCredentialRequested(
    CredentialRequested event,
    Emitter<McpOAuthState> emit,
  ) async {
    try {
      _currentSessionId = event.sessionId;
      _currentUserId = 'user_123'; // TODO: Get from auth context

      // Build provider from auth config
      final provider = _mcpOAuthRepository.buildProviderFromAuthConfig(
        providerId: event.credentialRequest.provider,
        authConfig: event.credentialRequest.authConfig,
      );

      emit(CredentialRequestPending(
        sessionId: event.sessionId,
        credentialRequest: event.credentialRequest,
        provider: provider,
      ));
    } catch (e) {
      _logger.e('Error processing credential request', error: e);
      emit(McpOAuthError(
        message: 'Failed to process credential request: $e',
        providerId: event.credentialRequest.provider,
      ));
    }
  }

  Future<void> _onAuthorizationStarted(
    AuthorizationStarted event,
    Emitter<McpOAuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CredentialRequestPending) {
      _logger.w('Authorization started but no credential request pending');
      return;
    }

    try {
      emit(AuthorizationInProgress(
        providerId: event.providerId,
        providerDisplayName: currentState.provider.displayName,
      ));

      // Generate authorization URL
      final urlResult = await _mcpOAuthRepository.getAuthorizationUrl(
        provider: currentState.provider,
      );

      await urlResult.fold(
        onSuccess: (authUrl) async {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            if (kIsWeb) {
              // Web: Open in popup or new tab
              await launchUrl(uri, webOnlyWindowName: '_blank');
            } else {
              // Desktop: Open in external browser
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            emit(McpOAuthError(
              message: 'Could not launch authorization URL',
              providerId: event.providerId,
            ));
          }
        },
        onFailure: (error) {
          emit(McpOAuthError(
            message: 'Failed to generate authorization URL: ${error.failure.details}',
            providerId: event.providerId,
          ));
        },
      );
    } catch (e) {
      _logger.e('Error starting authorization', error: e);
      emit(McpOAuthError(
        message: 'Failed to start authorization: $e',
        providerId: event.providerId,
      ));
    }
  }

  Future<void> _onAuthorizationCallbackReceived(
    AuthorizationCallbackReceived event,
    Emitter<McpOAuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthorizationInProgress) {
      _logger.w('Callback received but authorization not in progress');
      return;
    }

    if (currentState is! CredentialRequestPending && state is! AuthorizationInProgress) {
      _logger.w('Callback received but no credential request context');
      return;
    }

    // Get credential request from previous state
    CredentialRequestPending? pendingRequest;
    if (currentState is CredentialRequestPending) {
      pendingRequest = currentState;
    }

    if (pendingRequest == null) {
      emit(McpOAuthError(
        message: 'Lost credential request context',
        providerId: event.providerId,
      ));
      return;
    }

    try {
      emit(ProcessingCallback(providerId: event.providerId));

      // Parse callback URL
      final callbackUri = Uri.parse(event.callbackUrl);
      final code = callbackUri.queryParameters['code'];
      final state = callbackUri.queryParameters['state'];
      final error = callbackUri.queryParameters['error'];

      if (error != null) {
        emit(McpOAuthError(
          message: 'Authorization failed: $error',
          providerId: event.providerId,
        ));
        return;
      }

      if (code == null || state == null) {
        emit(McpOAuthError(
          message: 'Invalid callback: missing code or state',
          providerId: event.providerId,
        ));
        return;
      }

      // Retrieve code verifier
      final codeVerifier = await _getCodeVerifier(event.providerId, state);
      if (codeVerifier == null) {
        emit(McpOAuthError(
          message: 'Code verifier not found',
          providerId: event.providerId,
        ));
        return;
      }

      // Exchange code for token
      final tokenResult = await _mcpOAuthRepository.exchangeCodeForToken(
        provider: pendingRequest.provider,
        code: code,
        codeVerifier: codeVerifier,
      );

      await tokenResult.fold(
        onSuccess: (credentials) async {
          // Build function response
          final functionResponse = _mcpOAuthRepository.buildFunctionResponse(
            functionCallId: pendingRequest.credentialRequest.functionCallId,
            authConfig: pendingRequest.credentialRequest.authConfig,
            callbackUrl: event.callbackUrl,
            redirectUri: pendingRequest.provider.redirectUri,
          );

          // Submit to agent
          if (_currentSessionId != null && _currentUserId != null) {
            final submitResult = await _chatRepository.submitFunctionResponse(
              sessionId: _currentSessionId!,
              userId: _currentUserId!,
              functionResponseContent: functionResponse,
            );

            await submitResult.fold(
              onSuccess: (_) async {
                emit(AuthorizationComplete(
                  providerId: event.providerId,
                  providerDisplayName: pendingRequest!.provider.displayName,
                ));

                // Reset to idle after a brief delay
                await Future.delayed(const Duration(seconds: 2));
                emit(const McpOAuthIdle());
              },
              onFailure: (error) {
                emit(McpOAuthError(
                  message: 'Failed to submit credentials: ${error.failure.details}',
                  providerId: event.providerId,
                ));
              },
            );
          }
        },
        onFailure: (error) {
          emit(McpOAuthError(
            message: 'Token exchange failed: ${error.failure.details}',
            providerId: event.providerId,
          ));
        },
      );

      // Clear code verifier
      await _clearCodeVerifier(event.providerId, state);
    } catch (e, stack) {
      _logger.e('Error processing callback', error: e, stackTrace: stack);
      emit(McpOAuthError(
        message: 'Failed to process callback: $e',
        providerId: event.providerId,
      ));
    }
  }

  Future<void> _onCredentialRequestDismissed(
    CredentialRequestDismissed event,
    Emitter<McpOAuthState> emit,
  ) async {
    emit(const McpOAuthIdle());
  }

  /// Helper to retrieve code verifier (platform-specific)
  Future<String?> _getCodeVerifier(String providerId, String state) async {
    if (kIsWeb) {
      final localDataSource = _mcpOAuthRepository as dynamic; // Access to local data source
      final oauthState = await localDataSource._localDataSource.loadOAuthState(providerId, state);
      return oauthState?['codeVerifier'];
    } else {
      final repo = _mcpOAuthRepository as dynamic;
      return repo.getCodeVerifier(providerId, state);
    }
  }

  /// Helper to clear code verifier after use
  Future<void> _clearCodeVerifier(String providerId, String state) async {
    if (kIsWeb) {
      final localDataSource = _mcpOAuthRepository as dynamic;
      await localDataSource._localDataSource.clearOAuthState(providerId, state);
    } else {
      final repo = _mcpOAuthRepository as dynamic;
      repo.clearCodeVerifier(providerId, state);
    }
  }
}
```

#### 4. Update Chat BLoC to Wire Credential Request Callback
**File**: `lib/features/agent_chat/presentation/bloc/chat_bloc.dart`

**Add dependency injection** for `McpOAuthBloc` (update constructor at line 13):

```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(
    this._repository,
    this._logger,
    this._mcpOAuthBloc, // NEW
  ) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageStreaming>(_onSendMessageStreaming);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  final AgentChatRepository _repository;
  final Logger _logger;
  final McpOAuthBloc _mcpOAuthBloc; // NEW
  final Uuid _uuid = const Uuid();
```

**Update `_onSendMessageStreaming`** to pass credential request callback (modify line 70):

```dart
final result = await _repository.sendMessageStreaming(
  sessionId: event.sessionId,
  content: event.content,
  context: event.context,
  onStatus: (status, subAgent) {
    // ... existing status update code ...
  },
  onMessageChunk: (chunk) {
    // ... existing message chunk code ...
  },
  onCredentialRequest: (credentialRequest) {
    // NEW: Forward to MCP OAuth BLoC
    _mcpOAuthBloc.add(CredentialRequested(
      sessionId: event.sessionId,
      credentialRequest: credentialRequest,
    ));
  },
);
```

#### 5. Register BLoC in Provider Configuration
**File**: `lib/core/providers/bloc_providers.dart`

**Add `McpOAuthBloc` provider**:

```dart
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_bloc.dart';

// ... existing imports ...

List<BlocProvider> getBlocProviders() {
  return [
    // ... existing providers ...
    BlocProvider<McpOAuthBloc>(
      create: (context) => getIt<McpOAuthBloc>(),
    ),
  ];
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `dart analyze`
- [ ] Injectable generates BLoC registration: `dart run build_runner build`
- [ ] No linting errors: `dart fix --dry-run`

#### Manual Verification:
- [ ] When `adk_request_credential` event received, `McpOAuthBloc` transitions to `CredentialRequestPending`
- [ ] State includes correct provider info (name, display name, OAuth URLs)
- [ ] Triggering authorization opens browser with correct authorization URL
- [ ] Callback processing extracts code and state correctly
- [ ] Token exchange completes and credentials are saved
- [ ] Function response is submitted to agent successfully
- [ ] BLoC returns to idle state after completion

**Implementation Note**: After completing this phase and all automated verification passes, test the full flow end-to-end with the UI components from Phase 5 before deploying.

---

## Phase 5: Presentation Layer - UI Components for OAuth Authorization

### Overview
Create UI components to display OAuth authorization prompts and handle user interaction during the MCP OAuth flow.

### Changes Required

#### 1. Create OAuth Authorization Dialog
**File**: `lib/features/agent_chat/presentation/widgets/mcp_oauth_authorization_dialog.dart` (NEW)

**Purpose**: Modal dialog prompting user to authorize MCP provider

```dart
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_text_button.dart';
import 'package:carbon_voice_console/core/widgets/cards/glass_card.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class McpOAuthAuthorizationDialog extends StatelessWidget {
  const McpOAuthAuthorizationDialog({
    required this.state,
    super.key,
  });

  final CredentialRequestPending state;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Authorization Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'The agent needs access to your ${state.provider.displayName} account to complete this request.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Scopes (if available)
                if (state.provider.scopes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Requested permissions:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.provider.scopes.map((scope) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.check(PhosphorIconsStyle.bold),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scope,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: 32),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppTextButton(
                      label: 'Cancel',
                      onPressed: () {
                        context.read<McpOAuthBloc>().add(const CredentialRequestDismissed());
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Authorize',
                      onPressed: () {
                        context.read<McpOAuthBloc>().add(
                          AuthorizationStarted(providerId: state.provider.id),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 2. Create Authorization Status Indicator
**File**: `lib/features/agent_chat/presentation/widgets/mcp_oauth_status_indicator.dart` (NEW)

**Purpose**: Show status during OAuth flow (authorizing, processing, complete, error)

```dart
import 'package:carbon_voice_console/core/widgets/cards/app_pill_container.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_state.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class McpOAuthStatusIndicator extends StatelessWidget {
  const McpOAuthStatusIndicator({
    required this.state,
    super.key,
  });

  final McpOAuthState state;

  @override
  Widget build(BuildContext context) {
    if (state is McpOAuthIdle) {
      return const SizedBox.shrink();
    }

    String message;
    IconData icon;
    Color color;

    if (state is AuthorizationInProgress) {
      message = 'Authorizing ${state.providerDisplayName}...';
      icon = PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular);
      color = Theme.of(context).colorScheme.primary;
    } else if (state is ProcessingCallback) {
      message = 'Processing authorization...';
      icon = PhosphorIcons.circleNotch(PhosphorIconsStyle.regular);
      color = Theme.of(context).colorScheme.primary;
    } else if (state is AuthorizationComplete) {
      message = '${state.providerDisplayName} authorized';
      icon = PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      color = Theme.of(context).colorScheme.tertiary;
    } else if (state is McpOAuthError) {
      message = 'Authorization failed';
      icon = PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
      color = Theme.of(context).colorScheme.error;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppPillContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state is ProcessingCallback)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3. Integrate into Chat Conversation Area
**File**: `lib/features/agent_chat/presentation/components/chat_conversation_area.dart`

**Add imports** at top:

```dart
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_oauth_authorization_dialog.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_oauth_status_indicator.dart';
```

**Wrap existing `BlocBuilder<ChatBloc, ChatState>`** with `BlocListener<McpOAuthBloc, McpOAuthState>` and add status indicator:

```dart
@override
Widget build(BuildContext context) {
  return BlocListener<McpOAuthBloc, McpOAuthState>(
    listener: (context, state) {
      // Show authorization dialog when credential request is pending
      if (state is CredentialRequestPending) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => McpOAuthAuthorizationDialog(state: state),
        );
      }
    },
    child: Column(
      children: [
        // OAuth status indicator
        BlocBuilder<McpOAuthBloc, McpOAuthState>(
          builder: (context, oauthState) {
            return McpOAuthStatusIndicator(state: oauthState);
          },
        ),

        // Existing chat conversation
        Expanded(
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              // ... existing chat UI code ...
            },
          ),
        ),
      ],
    ),
  );
}
```

#### 4. Handle Deep Link Callbacks (Desktop)
**File**: `lib/features/agent_chat/presentation/screens/agent_chat_screen.dart`

**Add initialization** in `initState` to listen for deep links:

```dart
import 'package:carbon_voice_console/core/services/deep_linking_service.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_oauth_event.dart';

@override
void initState() {
  super.initState();

  // Setup deep link handler for MCP OAuth callbacks (desktop)
  if (!kIsWeb) {
    final deepLinkingService = getIt<DeepLinkingService>();
    deepLinkingService.setDeepLinkHandler((url) {
      final uri = Uri.parse(url);

      // Check if this is an MCP OAuth callback
      if (uri.path.contains('mcp-oauth-callback')) {
        final providerId = uri.queryParameters['provider'];
        if (providerId != null) {
          context.read<McpOAuthBloc>().add(
            AuthorizationCallbackReceived(
              providerId: providerId,
              callbackUrl: url,
            ),
          );
        }
      }
    });
  }
}

@override
void dispose() {
  // Clear deep link handler
  if (!kIsWeb) {
    final deepLinkingService = getIt<DeepLinkingService>();
    deepLinkingService.clearDeepLinkHandler();
  }
  super.dispose();
}
```

#### 5. Add Web OAuth Callback Route (Optional for Web)
**File**: `lib/core/routing/app_router.dart`

**Add new route** for MCP OAuth callback:

```dart
GoRoute(
  path: '/mcp-oauth-callback',
  name: 'mcpOAuthCallback',
  pageBuilder: (context, state) {
    final providerId = state.uri.queryParameters['provider'];
    final fullUrl = state.uri.toString();

    // Dispatch callback event to MCP OAuth BLoC
    if (providerId != null) {
      context.read<McpOAuthBloc>().add(
        AuthorizationCallbackReceived(
          providerId: providerId,
          callbackUrl: fullUrl,
        ),
      );
    }

    // Redirect to agent chat after processing
    return MaterialPage(
      key: state.pageKey,
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  },
),
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `dart analyze`
- [ ] No linting warnings: `dart fix --dry-run`
- [ ] All imports resolve correctly

#### Manual Verification:
- [ ] When credential request received, authorization dialog appears
- [ ] Dialog shows correct provider name and requested scopes
- [ ] Clicking "Authorize" opens browser with OAuth page
- [ ] After authorizing, callback is captured (desktop: deep link, web: route)
- [ ] Status indicator shows "Authorizing...", then "Processing...", then "Authorized"
- [ ] Dialog dismisses and chat continues after successful authorization
- [ ] Error state is displayed if authorization fails
- [ ] User can dismiss credential request and continue chat

**Implementation Note**: After completing this phase and all automated verification passes, perform complete end-to-end testing with real agent prompts requiring GitHub and Carbon Voice authentication.

---

## Testing Strategy

### Unit Tests

**Data Layer:**
- [ ] `EventDtoMapper.isCredentialRequest()` correctly identifies `adk_request_credential` events
- [ ] `EventDtoMapper.getCredentialRequest()` extracts auth config and function call ID
- [ ] `McpOAuthRepositoryImpl.getAuthorizationUrl()` generates valid PKCE URL
- [ ] `McpOAuthRepositoryImpl.exchangeCodeForToken()` handles successful token response
- [ ] `McpOAuthRepositoryImpl.buildFunctionResponse()` creates correct ADK payload format

**Domain Layer:**
- [ ] `McpCredentials.isExpired` correctly checks expiration timestamp
- [ ] `McpProvider` entity has correct equality comparison

**Presentation Layer:**
- [ ] `McpOAuthBloc` transitions from `Idle` → `CredentialRequestPending` on `CredentialRequested` event
- [ ] `McpOAuthBloc` transitions to `AuthorizationInProgress` on `AuthorizationStarted` event
- [ ] `McpOAuthBloc` handles callback and submits function response
- [ ] `ChatBloc` forwards credential requests to `McpOAuthBloc`

### Integration Tests

**OAuth Flow:**
- [ ] Full OAuth flow from credential request → authorization → callback → token exchange → function response submission
- [ ] Platform-specific storage (web: localStorage/sessionStorage, desktop: file)
- [ ] Multiple providers can be authorized in same session
- [ ] Tokens persist across app restarts

**SSE Event Processing:**
- [ ] `adk_request_credential` events trigger OAuth flow
- [ ] Text and function call events continue to work alongside credential requests
- [ ] Agent continues processing after receiving function response

### Manual Testing Steps

1. **GitHub Authentication Flow:**
   - Start app, navigate to agent chat
   - Send message: "Show me my GitHub repositories"
   - Verify authorization dialog appears with "GitHub" provider
   - Click "Authorize" → browser opens to GitHub OAuth page
   - Authorize app on GitHub
   - Verify callback is captured and token exchanged
   - Verify agent continues with GitHub data
   - Verify subsequent GitHub requests use cached token

2. **Carbon Voice Authentication Flow:**
   - Send message: "List my Carbon Voice files"
   - Verify authorization dialog appears with "Carbon Voice" provider
   - Complete OAuth flow
   - Verify agent accesses Carbon Voice MCP server

3. **Multiple Providers:**
   - Trigger GitHub auth → complete
   - Trigger Carbon Voice auth → complete
   - Verify both providers work independently
   - Verify tokens are stored separately

4. **Error Handling:**
   - Trigger OAuth flow, cancel on provider page
   - Verify error state is shown
   - Trigger OAuth flow, deny permissions
   - Verify error message is displayed
   - Trigger OAuth flow, simulate network failure
   - Verify appropriate error handling

5. **Platform Testing:**
   - **Web:** Test full flow in browser (Chrome, Firefox, Safari)
   - **macOS:** Test deep link callback handling
   - **Storage:** Verify tokens persist after app restart on both platforms

---

## Performance Considerations

### Token Caching
- **Current approach:** Load credentials from storage before each request
- **Optimization:** Implement in-memory cache with expiry tracking
- **Trade-off:** Memory usage vs reduced I/O operations

### SSE Connection Management
- **Current:** New SSE connection per message
- **Future optimization:** Keep connection alive for multiple messages
- **Consideration:** Handle connection timeouts and reconnection logic

### Authorization URL Generation
- **PKCE generation:** Uses cryptographically secure random (acceptable overhead)
- **SHA-256 hashing:** Fast enough for real-time use
- **No optimization needed** for v1

---

## Migration Notes

### Backwards Compatibility
- Existing Carbon Voice API OAuth flow remains unchanged
- New MCP OAuth is completely separate system
- No migration of existing credentials required

### Configuration Changes
- **New URL scheme:** `carbonvoice://mcp-oauth-callback` registered alongside existing `carbonvoice://` scheme
- **Environment variables:** No new environment variables required (credentials come from agent)

### Data Storage
- **New storage keys:** `mcp_credentials_{providerId}` and `mcp_oauth_state_{providerId}_{state}`
- **Separate from:** Existing `oauth_credentials` for Carbon Voice API auth
- **No conflicts:** Different key namespaces

---

## Security Considerations

### Token Storage
- **Web:** localStorage (accessible by JavaScript, acceptable for development)
- **Desktop:** File-based with base64 encoding (not true encryption, acceptable for v1)
- **Future:** Implement encryption at rest using `flutter_secure_storage` properly or external secret manager

### PKCE Flow
- **Code verifier:** 128 characters, cryptographically secure random
- **Code challenge:** SHA-256 hash, base64url encoded
- **State parameter:** 32 characters, cryptographically secure random
- **CSRF protection:** State parameter validated on callback

### Credential Transmission
- **Function response:** Sent to ADK backend via HTTPS
- **Agent backend:** Responsible for secure token storage and usage
- **Flutter app:** Only stores tokens temporarily for session continuity

### Sensitive Data Logging
- **DO NOT log:** Access tokens, refresh tokens, client secrets, code verifiers
- **Safe to log:** Provider IDs, authorization URLs (without tokens), function call IDs

---

## References

- **ADK OAuth2 Documentation:** https://google.github.io/adk-docs/tools-custom/authentication/index.md
- **Agent Configuration:** [agent/agent/agent.py](agent/agent/agent.py)
- **Existing OAuth Flow:** [lib/features/auth/data/repositories/oauth_repository_impl.dart](lib/features/auth/data/repositories/oauth_repository_impl.dart:36-116)
- **SSE Event Processing:** [lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart](lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart:56-116)
- **Deep Linking Service:** [lib/core/services/deep_linking_service.dart](lib/core/services/deep_linking_service.dart)
- **OAuth2 Package Documentation:** https://pub.dev/packages/oauth2
- **PKCE RFC 7636:** https://tools.ietf.org/html/rfc7636
