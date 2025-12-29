# ADK Authentication Event Handling Implementation Plan

## Overview

This plan addresses the architectural refactoring needed to properly handle ADK authentication events (`adk_request_credential` function calls) within a Clean Architecture setup. Currently, the data layer prematurely filters out non-text events, losing critical behavioral signals like authentication requests. This refactoring will expose the full ADK event stream, create an application-layer coordinator to interpret events, and enable multiple consumers (chat UI and authentication flow) to react appropriately.

## Current State Analysis

### Problems Identified

1. **Premature Filtering in Data Layer**: 
   - `EventDtoMapper.toDomain()` returns `null` for non-text events (`content.role != 'model'` or no text parts)
   - This silently drops authentication events and other important ADK protocol signals
   - Location: `lib/features/agent_chat/data/mappers/event_mapper.dart:6-10`

2. **Repository Collapses Event Stream**:
   - `AgentChatRepository.sendMessageStreaming()` accumulates events into `Future<Result<List<AgentChatMessage>>>`
   - Loses the streaming nature and event-by-event semantics required by ADK
   - Location: `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart:5-11`

3. **Loss of Function Call Information**:
   - `EventDto` correctly models ADK events including `functionCall` and `functionResponse`
   - This information is discarded during mapping to `AgentChatMessage`
   - Location: `lib/features/agent_chat/data/mappers/event_mapper.dart:5-44`

4. **Blocs Parsing Protocol Details**:
   - `ChatBloc` receives collapsed chat messages, not raw events
   - No mechanism to handle authentication requests or other ADK control signals

### Current Architecture

```
AdkApiService (Data Layer)
    ↓ Stream<EventDto>
AgentChatRepositoryImpl (Data Layer)
    ↓ Filters & Accumulates into List
    ↓ Future<Result<List<AgentChatMessage>>>
ChatBloc (Presentation Layer)
    ↓ Displays messages
UI
```

### Key Discoveries

- **ADK Event Structure**: Events contain `author`, `content` (with `parts` array), `actions`, `partial`, and other metadata
- **Function Calls**: Can appear in `content.parts[].functionCall` or `actions.functionCalls[]`
- **Authentication Request**: Special function call named `adk_request_credential` with OAuth2 parameters
- **Event Types**: Text messages, function call requests, function responses, state updates, control signals
- **Existing OAuth Infrastructure**: Robust OAuth system exists for main app (`lib/features/auth`), but no handling for agent-initiated auth

## Desired End State

### Architecture Overview

```
AdkApiService (Data Layer)
    ↓ Stream<EventDto>
AgentChatRepositoryImpl (Data Layer)
    ↓ Maps to Domain Events (no filtering)
    ↓ Stream<AdkEvent>
Domain Use Cases (Application Layer)
    ├─→ GetChatMessagesFromEventsUseCase → ChatBloc
    ├─→ GetAuthenticationRequestsUseCase → McpAuthBloc
    └─→ (function calls/responses handled in ChatBloc for "thinking" indicators)
```

### Success Criteria

**After Implementation:**
- ADK event stream is fully preserved from API to application layer
- Authentication requests trigger OAuth flows automatically
- Chat UI displays text messages correctly
- Function calls show as status indicators
- No ADK protocol details leak into Blocs
- Multiple features can consume different event types independently

**Verification:**
1. Send a message that triggers GitHub authentication
2. Observe authentication dialog appears
3. Complete OAuth flow
4. Verify credentials sent back to ADK backend
5. Confirm agent can now use GitHub tools
6. Chat messages display correctly throughout

## What We're NOT Doing

- Automatic retry of failed authentication (manual for now)
- Auto-opening OAuth URLs in browser (dialog-based initially)
- Storing MCP tool credentials locally (backend manages this)
- Migrating existing app OAuth to new event system
- Real-time event streaming with token-level streaming (non-streaming mode for now)
- Handling long-running tool execution (`longRunningToolIds`)
- Processing state deltas (`actions.stateDelta`) or artifact deltas

## Implementation Approach

This refactoring follows Clean Architecture principles:
1. **Preserve Information**: Stop filtering events in data layer
2. **Single Responsibility**: Each use case handles one type of event filtering
3. **Separation of Concerns**: Blocs receive typed streams from use cases, not raw protocol
4. **Dependency Inversion**: Blocs depend on use case abstractions, not repository directly
5. **Open/Closed**: Easy to add new use cases without modifying existing code

We'll implement incrementally, ensuring each phase is testable before proceeding.

---

## Phase 1: Domain Layer - Create ADK Event Entities

### Overview
Define comprehensive domain entities that represent the full ADK event structure, preserving all information from the API.

### Changes Required

#### 1. Create ADK Event Entity
**File**: `lib/features/agent_chat/domain/entities/adk_event.dart`

```dart
import 'package:equatable/equatable.dart';

/// Represents a complete ADK event from the agent execution stream
class AdkEvent extends Equatable {
  const AdkEvent({
    required this.id,
    required this.invocationId,
    required this.author,
    required this.timestamp,
    required this.content,
    this.actions,
    this.partial = false,
    this.branch,
    this.longRunningToolIds,
  });

  final String id;
  final String invocationId;
  final String author;
  final DateTime timestamp;
  final AdkContent content;
  final AdkActions? actions;
  final bool partial;
  final String? branch;
  final List<String>? longRunningToolIds;

  @override
  List<Object?> get props => [
        id,
        invocationId,
        author,
        timestamp,
        content,
        actions,
        partial,
        branch,
        longRunningToolIds,
      ];

  /// Check if this is a final user-facing response (text message)
  bool get isFinalResponse {
    if (partial) return false;
    if (content.parts.isEmpty) return false;
    
    // Has text and no function calls
    final hasText = content.parts.any((p) => p.text != null);
    final hasFunctionCalls = content.parts.any((p) => p.functionCall != null);
    
    return hasText && !hasFunctionCalls;
  }

  /// Check if this event contains an authentication request
  bool get isAuthenticationRequest {
    // Check function calls in parts
    for (final part in content.parts) {
      if (part.functionCall?.name == 'adk_request_credential') {
        return true;
      }
    }
    
    // Check actions
    if (actions?.functionCalls != null) {
      return actions!.functionCalls!
          .any((call) => call.name == 'adk_request_credential');
    }
    
    return false;
  }

  /// Extract authentication request details if present
  AuthenticationRequest? get authenticationRequest {
    // Check parts first
    for (final part in content.parts) {
      if (part.functionCall?.name == 'adk_request_credential') {
        return AuthenticationRequest.fromFunctionCall(part.functionCall!);
      }
    }
    
    // Check actions
    if (actions?.functionCalls != null) {
      final authCall = actions!.functionCalls!
          .firstWhere(
            (call) => call.name == 'adk_request_credential',
            orElse: () => null,
          );
      if (authCall != null) {
        return AuthenticationRequest.fromFunctionCall(authCall);
      }
    }
    
    return null;
  }

  /// Get all function calls in this event
  List<AdkFunctionCall> get functionCalls {
    final calls = <AdkFunctionCall>[];
    
    // From parts
    for (final part in content.parts) {
      if (part.functionCall != null) {
        calls.add(part.functionCall!);
      }
    }
    
    // From actions
    if (actions?.functionCalls != null) {
      calls.addAll(actions!.functionCalls!);
    }
    
    return calls;
  }

  /// Get text content from this event
  String? get textContent {
    final textParts = content.parts
        .where((p) => p.text != null)
        .map((p) => p.text!)
        .toList();
    
    if (textParts.isEmpty) return null;
    return textParts.join('\n');
  }
}

/// Content structure matching ADK's Content type
class AdkContent extends Equatable {
  const AdkContent({
    required this.role,
    required this.parts,
  });

  final String role;
  final List<AdkPart> parts;

  @override
  List<Object?> get props => [role, parts];
}

/// Part structure - can contain text, function calls, or function responses
class AdkPart extends Equatable {
  const AdkPart({
    this.text,
    this.functionCall,
    this.functionResponse,
    this.inlineData,
  });

  final String? text;
  final AdkFunctionCall? functionCall;
  final AdkFunctionResponse? functionResponse;
  final AdkInlineData? inlineData;

  @override
  List<Object?> get props => [text, functionCall, functionResponse, inlineData];
}

/// Function call structure
class AdkFunctionCall extends Equatable {
  const AdkFunctionCall({
    required this.name,
    required this.args,
  });

  final String name;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [name, args];
}

/// Function response structure
class AdkFunctionResponse extends Equatable {
  const AdkFunctionResponse({
    required this.name,
    required this.response,
  });

  final String name;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [name, response];
}

/// Inline data (images, etc.)
class AdkInlineData extends Equatable {
  const AdkInlineData({
    required this.mimeType,
    required this.data,
  });

  final String mimeType;
  final String data; // base64 encoded

  @override
  List<Object?> get props => [mimeType, data];
}

/// Actions that can be attached to events
class AdkActions extends Equatable {
  const AdkActions({
    this.functionCalls,
    this.functionResponses,
    this.skipSummarization = false,
  });

  final List<AdkFunctionCall>? functionCalls;
  final List<AdkFunctionResponse>? functionResponses;
  final bool skipSummarization;

  @override
  List<Object?> get props => [functionCalls, functionResponses, skipSummarization];
}

/// Authentication request extracted from adk_request_credential function call
class AuthenticationRequest extends Equatable {
  const AuthenticationRequest({
    required this.provider,
    required this.authorizationUrl,
    required this.tokenUrl,
    required this.scopes,
    this.additionalParams,
  });

  factory AuthenticationRequest.fromFunctionCall(AdkFunctionCall call) {
    final args = call.args;
    return AuthenticationRequest(
      provider: args['provider'] as String? ?? 'unknown',
      authorizationUrl: args['authorization_url'] as String? ?? args['authorizationUrl'] as String? ?? '',
      tokenUrl: args['token_url'] as String? ?? args['tokenUrl'] as String? ?? '',
      scopes: (args['scopes'] as List<dynamic>?)?.cast<String>() ?? [],
      additionalParams: args['additional_params'] as Map<String, dynamic>? ?? 
                       args['additionalParams'] as Map<String, dynamic>?,
    );
  }

  final String provider;
  final String authorizationUrl;
  final String tokenUrl;
  final List<String> scopes;
  final Map<String, dynamic>? additionalParams;

  @override
  List<Object?> get props => [
        provider,
        authorizationUrl,
        tokenUrl,
        scopes,
        additionalParams,
      ];
}
```

#### 2. Update Repository Interface to Stream Events
**File**: `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart`

Replace the entire content:

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

abstract class AgentChatRepository {
  /// Send a message and receive a stream of ADK events
  /// 
  /// This stream includes all events from the agent: text responses,
  /// function calls, authentication requests, status updates, etc.
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  });

  /// Send authentication credentials back to the ADK agent
  /// 
  /// This is called after the user completes OAuth flow for MCP tools
  Future<void> sendAuthenticationCredentials({
    required String sessionId,
    required String provider,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  });
}
```

### Success Criteria

#### Automated Verification:
- [x] All new domain entities compile without errors: `flutter analyze lib/features/agent_chat/domain/entities/adk_event.dart`
- [x] Repository interface compiles: `flutter analyze lib/features/agent_chat/domain/repositories/agent_chat_repository.dart`
- [x] No breaking changes to existing code yet (we haven't modified implementations)

#### Manual Verification:
- [ ] Review entity structure matches ADK event documentation
- [ ] Confirm all necessary event types are represented
- [ ] Verify authentication request extraction logic is correct

---

## Phase 2: Data Layer - Update Mappers and Repository

### Overview
Modify the data layer to stop filtering events and map all `EventDto` objects to domain `AdkEvent` entities.

### Changes Required

#### 1. Create ADK Event Mapper
**File**: `lib/features/agent_chat/data/mappers/adk_event_mapper.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

extension EventDtoToDomain on EventDto {
  /// Convert EventDto to domain AdkEvent
  /// 
  /// Unlike the old mapper, this preserves ALL event information
  AdkEvent toAdkEvent() {
    return AdkEvent(
      id: id ?? '',
      invocationId: invocationId ?? '',
      author: author,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
          : DateTime.now(),
      content: content.toAdkContent(),
      actions: actions?.toAdkActions(),
      partial: partial ?? false,
      branch: branch,
      longRunningToolIds: longRunningToolIds,
    );
  }
}

extension ContentDtoToDomain on ContentDto {
  AdkContent toAdkContent() {
    return AdkContent(
      role: role,
      parts: parts.map((p) => p.toAdkPart()).toList(),
    );
  }
}

extension PartDtoToDomain on PartDto {
  AdkPart toAdkPart() {
    return AdkPart(
      text: text,
      functionCall: functionCall?.toAdkFunctionCall(),
      functionResponse: functionResponse?.toAdkFunctionResponse(),
      inlineData: inlineData?.toAdkInlineData(),
    );
  }
}

extension FunctionCallDtoToDomain on FunctionCallDto {
  AdkFunctionCall toAdkFunctionCall() {
    return AdkFunctionCall(
      name: name,
      args: args,
    );
  }
}

extension FunctionResponseDtoToDomain on FunctionResponseDto {
  AdkFunctionResponse toAdkFunctionResponse() {
    return AdkFunctionResponse(
      name: name,
      response: response,
    );
  }
}

extension InlineDataDtoToDomain on InlineDataDto {
  AdkInlineData toAdkInlineData() {
    return AdkInlineData(
      mimeType: mimeType,
      data: data,
    );
  }
}

extension ActionsDtoToDomain on ActionsDto {
  AdkActions toAdkActions() {
    return AdkActions(
      functionCalls: functionCalls?.map((c) => c.toAdkFunctionCall()).toList(),
      functionResponses: functionResponses?.map((r) => r.toAdkFunctionResponse()).toList(),
      skipSummarization: skipSummarization ?? false,
    );
  }
}
```

#### 2. Update Repository Implementation
**File**: `lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`

Replace the entire implementation:

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/adk_event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {
  AgentChatRepositoryImpl(
    this._apiService,
    this._logger,
  );

  final AdkApiService _apiService;
  final Logger _logger;

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'test_user'; // Placeholder - matches ADK test user
  }

  @override
  Stream<AdkEvent> sendMessageStreaming({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.d('Streaming message for session: $sessionId');

      await for (final eventDto in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      )) {
        // Map DTO to domain event (no filtering!)
        final adkEvent = eventDto.toAdkEvent();
        
        _logger.d('Event from ${adkEvent.author}: '
            'text=${adkEvent.textContent?.substring(0, 50) ?? "none"}, '
            'functionCalls=${adkEvent.functionCalls.map((c) => c.name).join(", ")}');

        yield adkEvent;
      }
    } on ServerException catch (e) {
      _logger.e('Server error streaming message', error: e);
      throw ServerException(statusCode: e.statusCode, message: e.message);
    } on NetworkException catch (e) {
      _logger.e('Network error streaming message', error: e);
      throw NetworkException(message: e.message);
    } catch (e) {
      _logger.e('Unexpected error streaming message', error: e);
      throw NetworkException(message: 'Failed to stream message: $e');
    }
  }

  @override
  Future<void> sendAuthenticationCredentials({
    required String sessionId,
    required String provider,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    try {
      _logger.i('Sending authentication credentials for provider: $provider');

      // Construct credential message to send back to agent
      final credentialMessage = {
        'role': 'user',
        'parts': [
          {
            'functionResponse': {
              'name': 'adk_request_credential',
              'response': {
                'provider': provider,
                'access_token': accessToken,
                if (refreshToken != null) 'refresh_token': refreshToken,
                if (expiresAt != null)
                  'expires_at': expiresAt.toIso8601String(),
              },
            },
          },
        ],
      };

      // Send credential as a message back to the agent
      await for (final _ in _apiService.sendMessageStreaming(
        userId: _userId,
        sessionId: sessionId,
        message: '', // Empty text, function response in parts
        context: credentialMessage,
      )) {
        // Consume the stream but don't need to process response
        // The agent will acknowledge receipt
      }

      _logger.i('Authentication credentials sent successfully');
    } on ServerException catch (e) {
      _logger.e('Server error sending credentials', error: e);
      throw ServerException(statusCode: e.statusCode, message: e.message);
    } on NetworkException catch (e) {
      _logger.e('Network error sending credentials', error: e);
      throw NetworkException(message: e.message);
    } catch (e) {
      _logger.e('Unexpected error sending credentials', error: e);
      throw NetworkException(message: 'Failed to send credentials: $e');
    }
  }
}
```

#### 3. Keep Old Mapper for Backward Compatibility (Temporary)
**File**: `lib/features/agent_chat/data/mappers/event_mapper.dart`

Keep this file unchanged for now. We'll deprecate it in Phase 4 after migrating consumers.

### Success Criteria

#### Automated Verification:
- [x] New mapper compiles: `flutter analyze lib/features/agent_chat/data/mappers/adk_event_mapper.dart`
- [x] Repository implementation compiles: `flutter analyze lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`
- [x] Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No compilation errors: `flutter analyze`

#### Manual Verification:
- [ ] Review mapper preserves all DTO information
- [ ] Verify authentication credential sending logic
- [ ] Confirm stream properly propagates exceptions

**Implementation Note**: After completing this phase and automated verification passes, we can proceed. The old mapper remains to avoid breaking existing consumers temporarily.

---

## Phase 3: Domain Layer - Create Event Processing Use Cases

### Overview
Create domain use cases that filter and transform raw ADK event streams for specific purposes. Each use case is injected into the relevant bloc, following the established use case pattern in the codebase.

### Changes Required

#### 1. Define Categorized Event Types
**File**: `lib/features/agent_chat/domain/entities/categorized_event.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

/// Base class for categorized events emitted by the coordinator
sealed class CategorizedEvent extends Equatable {
  const CategorizedEvent(this.sourceEvent);

  final AdkEvent sourceEvent;

  @override
  List<Object?> get props => [sourceEvent];
}

/// A text message from the agent (for chat UI)
class ChatMessageEvent extends CategorizedEvent {
  const ChatMessageEvent({
    required super.sourceEvent,
    required this.text,
    required this.isPartial,
  });

  final String text;
  final bool isPartial;

  @override
  List<Object?> get props => [...super.props, text, isPartial];
}

/// A function call being executed by the agent (for status indicators)
class FunctionCallEvent extends CategorizedEvent {
  const FunctionCallEvent({
    required super.sourceEvent,
    required this.functionName,
    required this.args,
  });

  final String functionName;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [...super.props, functionName, args];
}

/// A function call result (mostly for logging/debugging)
class FunctionResponseEvent extends CategorizedEvent {
  const FunctionResponseEvent({
    required super.sourceEvent,
    required this.functionName,
    required this.response,
  });

  final String functionName;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [...super.props, functionName, response];
}

/// An authentication request from the agent (triggers OAuth flow)
class AuthenticationRequestEvent extends CategorizedEvent {
  const AuthenticationRequestEvent({
    required super.sourceEvent,
    required this.request,
  });

  final AuthenticationRequest request;

  @override
  List<Object?> get props => [...super.props, request];
}

/// An error occurred during agent execution
class AgentErrorEvent extends CategorizedEvent {
  const AgentErrorEvent({
    required super.sourceEvent,
    required this.errorMessage,
  });

  final String errorMessage;

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
```

#### 2. Create Get Chat Messages Use Case
**File**: `lib/features/agent_chat/domain/usecases/get_chat_messages_from_events_usecase.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for chat messages and function call indicators
/// 
/// This use case processes the raw event stream and yields:
/// - ChatMessageEvent for text content (complete and partial)
/// - FunctionCallEvent for "thinking..." indicators
/// - FunctionResponseEvent for function completion
/// - AgentErrorEvent for errors
@injectable
class GetChatMessagesFromEventsUseCase {
  const GetChatMessagesFromEventsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process event stream for a session, yielding chat-relevant events
  Stream<CategorizedEvent> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.i('Starting chat event stream for session: $sessionId');

      final eventStream = _repository.sendMessageStreaming(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      await for (final event in eventStream) {
        _logger.d('Processing event from ${event.author}');

        // Skip authentication requests (handled by auth use case)
        if (event.isAuthenticationRequest) {
          _logger.d('Skipping auth request in chat stream');
          continue;
        }

        // 1. Function calls (for "thinking..." status)
        if (event.functionCalls.isNotEmpty) {
          for (final call in event.functionCalls) {
            _logger.d('Function call: ${call.name}');
            yield FunctionCallEvent(
              sourceEvent: event,
              functionName: call.name,
              args: call.args,
            );
          }
        }

        // 2. Function responses (to clear "thinking..." status)
        for (final part in event.content.parts) {
          if (part.functionResponse != null) {
            _logger.d('Function response: ${part.functionResponse!.name}');
            yield FunctionResponseEvent(
              sourceEvent: event,
              functionName: part.functionResponse!.name,
              response: part.functionResponse!.response,
            );
          }
        }

        // 3. Text content (actual chat messages)
        final textContent = event.textContent;
        if (textContent != null && textContent.isNotEmpty) {
          _logger.d('Chat message (${event.partial ? "partial" : "complete"}): '
              '${textContent.substring(0, textContent.length > 50 ? 50 : textContent.length)}...');
          yield ChatMessageEvent(
            sourceEvent: event,
            text: textContent,
            isPartial: event.partial,
          );
        }
      }

      _logger.i('Chat event stream completed for session: $sessionId');
    } catch (e, stackTrace) {
      _logger.e('Error in chat event stream', error: e, stackTrace: stackTrace);
      yield AgentErrorEvent(
        sourceEvent: AdkEvent(
          id: '',
          invocationId: '',
          author: 'system',
          timestamp: DateTime.now(),
          content: const AdkContent(role: 'system', parts: []),
        ),
        errorMessage: e.toString(),
      );
    }
  }
}
```

#### 3. Create Get Authentication Requests Use Case
**File**: `lib/features/agent_chat/domain/usecases/get_authentication_requests_usecase.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case to filter ADK events for authentication requests
/// 
/// This use case processes the raw event stream and yields only
/// AuthenticationRequestEvent when the agent requests MCP tool authentication
@injectable
class GetAuthenticationRequestsUseCase {
  const GetAuthenticationRequestsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Process event stream for authentication requests
  Stream<AuthenticationRequestEvent> call({
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async* {
    try {
      _logger.i('Starting auth request stream for session: $sessionId');

      final eventStream = _repository.sendMessageStreaming(
        sessionId: sessionId,
        content: message,
        context: context,
      );

      await for (final event in eventStream) {
        // Only yield authentication request events
        if (event.isAuthenticationRequest) {
          final authRequest = event.authenticationRequest!;
          _logger.i('Authentication request for provider: ${authRequest.provider}');
          
          yield AuthenticationRequestEvent(
            sourceEvent: event,
            request: authRequest,
          );
        }
      }

      _logger.i('Auth request stream completed for session: $sessionId');
    } catch (e, stackTrace) {
      _logger.e('Error in auth request stream', error: e, stackTrace: stackTrace);
      // Don't yield errors here - let them propagate to chat use case
      rethrow;
    }
  }
}
```

#### 4. Create Send Authentication Credentials Use Case
**File**: `lib/features/agent_chat/domain/usecases/send_authentication_credentials_usecase.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

/// Use case to send authentication credentials back to the ADK agent
@injectable
class SendAuthenticationCredentialsUseCase {
  const SendAuthenticationCredentialsUseCase(
    this._repository,
    this._logger,
  );

  final AgentChatRepository _repository;
  final Logger _logger;

  /// Send credentials obtained from OAuth flow back to agent
  Future<void> call({
    required String sessionId,
    required String provider,
    required oauth2.Credentials credentials,
  }) async {
    try {
      _logger.i('Sending auth credentials for provider: $provider');

      await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        expiresAt: credentials.expiration,
      );

      _logger.i('Credentials sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to send credentials', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Send authentication error back to agent
  Future<void> sendError({
    required String sessionId,
    required String provider,
    required String errorMessage,
  }) async {
    try {
      _logger.w('Sending authentication error: $errorMessage');

      // Send error as credentials with ERROR token
      await _repository.sendAuthenticationCredentials(
        sessionId: sessionId,
        provider: provider,
        accessToken: 'ERROR',
        refreshToken: errorMessage,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to send auth error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [x] Categorized event types compile: `flutter analyze lib/features/agent_chat/domain/entities/categorized_event.dart`
- [x] Chat messages use case compiles: `flutter analyze lib/features/agent_chat/domain/usecases/get_chat_messages_from_events_usecase.dart`
- [x] Auth requests use case compiles: `flutter analyze lib/features/agent_chat/domain/usecases/get_authentication_requests_usecase.dart`
- [x] Send credentials use case compiles: `flutter analyze lib/features/agent_chat/domain/usecases/send_authentication_credentials_usecase.dart`
- [x] Regenerate DI code: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] No compilation errors: `flutter analyze`

#### Manual Verification:
- [ ] Review event filtering logic in each use case
- [ ] Verify use cases follow existing patterns in codebase
- [ ] Confirm each use case has single, clear responsibility

**Implementation Note**: After completing this phase and automated verification passes, proceed to integrate with presentation layer.

---

## Phase 4: Presentation Layer - Update Chat Bloc

### Overview
Refactor `ChatBloc` to use the `GetChatMessagesFromEventsUseCase` instead of calling the repository directly. The use case provides filtered, categorized events.

### Changes Required

#### 1. Update Chat State to Include Status
**File**: `lib/features/agent_chat/presentation/bloc/chat_state.dart`

Update the `ChatLoaded` class to add function call status tracking:

```dart
class ChatLoaded extends ChatState {
  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
    this.statusMessage,
    this.statusSubAgent,
    this.activeSessionId, // NEW: Track which session is actively streaming
  });

  final List<AgentChatMessage> messages;
  final String currentSessionId;
  final bool isSending;
  final String? statusMessage;
  final String? statusSubAgent;
  final String? activeSessionId; // NEW

  @override
  List<Object?> get props => [
        messages,
        currentSessionId,
        isSending,
        statusMessage,
        statusSubAgent,
        activeSessionId, // NEW
      ];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
    String? statusMessage,
    String? statusSubAgent,
    String? activeSessionId,
    bool clearStatus = false, // NEW: Allow clearing status
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      statusSubAgent: clearStatus ? null : (statusSubAgent ?? this.statusSubAgent),
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}
```

#### 2. Update Chat Bloc Implementation
**File**: `lib/features/agent_chat/presentation/bloc/chat_bloc.dart`

Replace entire implementation:

```dart
import 'dart:async';

import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/categorized_event.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/get_chat_messages_from_events_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(
    this._getChatMessagesUseCase,
    this._logger,
  ) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageStreaming>(_onSendMessageStreaming);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  final GetChatMessagesFromEventsUseCase _getChatMessagesUseCase;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  StreamSubscription<CategorizedEvent>? _eventSubscription;

  // Track streaming message accumulation
  String? _currentStreamingMessageId;
  final StringBuffer _streamingTextBuffer = StringBuffer();

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    // TODO: Load message history from backend/local storage
    emit(ChatLoaded(
      messages: const [],
      currentSessionId: event.sessionId,
    ));
  }

  Future<void> _onSendMessageStreaming(
    SendMessageStreaming event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Create user message
    final userMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: event.sessionId,
      role: MessageRole.user,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add to UI immediately
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isSending: true,
      activeSessionId: event.sessionId,
    ));

    // Reset streaming state
    _currentStreamingMessageId = null;
    _streamingTextBuffer.clear();

    // Start use case stream using emit.forEach pattern
    try {
      final eventStream = _getChatMessagesUseCase(
        sessionId: event.sessionId,
        message: event.content,
        context: event.context,
      );

      // Process each event using emit.forEach (no manual subscription!)
      await emit.forEach<CategorizedEvent>(
        eventStream,
        onData: (categorizedEvent) {
          // Handle each categorized event
          if (categorizedEvent is ChatMessageEvent) {
            return _handleChatMessage(categorizedEvent, currentState);
          } else if (categorizedEvent is FunctionCallEvent) {
            return _handleFunctionCall(categorizedEvent, currentState);
          } else if (categorizedEvent is FunctionResponseEvent) {
            return _handleFunctionResponse(categorizedEvent, currentState);
          } else if (categorizedEvent is AgentErrorEvent) {
            return _handleError(categorizedEvent, currentState);
          }
          return currentState; // Unknown event type
        },
        onError: (error, stackTrace) {
          _logger.e('Error in event stream', error: error, stackTrace: stackTrace);
          
          // Create error message
          final errorMessage = AgentChatMessage(
            id: _uuid.v4(),
            sessionId: event.sessionId,
            role: MessageRole.agent,
            content: '⚠️ Error: $error',
            timestamp: DateTime.now(),
            status: MessageStatus.error,
          );

          return ChatLoaded(
            messages: [...currentState.messages, errorMessage],
            currentSessionId: event.sessionId,
            isSending: false,
          );
        },
      );

      // Stream completed - mark user message as sent
      final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
      final updatedMessages = currentState.messages
          .map((m) => m.id == userMessage.id ? updatedUserMessage : m)
          .toList();

      emit(ChatLoaded(
        messages: updatedMessages,
        currentSessionId: event.sessionId,
        isSending: false,
      ));
    } catch (e) {
      _logger.e('Error starting session', error: e);

      // Update user message to error
      final errorMessage = userMessage.copyWith(status: MessageStatus.error);
      final updatedMessages = currentState.messages
          .map((m) => m.id == userMessage.id ? errorMessage : m)
          .toList();

      emit(ChatLoaded(
        messages: updatedMessages,
        currentSessionId: event.sessionId,
        isSending: false,
      ));
    }
  }

  /// Handle chat message events (returns new state)
  ChatState _handleChatMessage(ChatMessageEvent event, ChatLoaded currentState) {

    // Only process if this is for the active session
    if (currentState.activeSessionId != currentState.currentSessionId) return;

    if (event.isPartial) {
      // Accumulate partial text
      _streamingTextBuffer.write(event.text);

      // Create or update streaming message
      if (_currentStreamingMessageId == null) {
        _currentStreamingMessageId = _uuid.v4();
        
        final streamingMessage = AgentChatMessage(
          id: _currentStreamingMessageId!,
          sessionId: currentState.currentSessionId,
          role: MessageRole.agent,
          content: _streamingTextBuffer.toString(),
          timestamp: event.sourceEvent.timestamp,
          subAgentName: _extractSubAgentName(event.sourceEvent.author),
          subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
          metadata: {
            'invocationId': event.sourceEvent.invocationId,
            'author': event.sourceEvent.author,
          },
        );

        return currentState.copyWith(
          messages: [...currentState.messages, streamingMessage],
          clearStatus: true,
        );
      } else {
        // Update existing streaming message
        final updatedMessages = currentState.messages.map((m) {
          if (m.id == _currentStreamingMessageId) {
            return m.copyWith(content: _streamingTextBuffer.toString());
          }
          return m;
        }).toList();

        return currentState.copyWith(messages: updatedMessages);
      }
    } else {
      // Complete message
      if (_currentStreamingMessageId != null) {
        // Update final version of streaming message
        final updatedMessages = currentState.messages.map((m) {
          if (m.id == _currentStreamingMessageId) {
            return m.copyWith(content: event.text);
          }
          return m;
        }).toList();

        // Reset streaming state
        _currentStreamingMessageId = null;
        _streamingTextBuffer.clear();

        return currentState.copyWith(
          messages: updatedMessages,
          clearStatus: true,
        );
      } else {
        // Single complete message (non-streaming)
        final agentMessage = AgentChatMessage(
          id: event.sourceEvent.id,
          sessionId: currentState.currentSessionId,
          role: MessageRole.agent,
          content: event.text,
          timestamp: event.sourceEvent.timestamp,
          subAgentName: _extractSubAgentName(event.sourceEvent.author),
          subAgentIcon: _extractSubAgentIcon(event.sourceEvent.author),
          metadata: {
            'invocationId': event.sourceEvent.invocationId,
            'author': event.sourceEvent.author,
          },
        );

        return currentState.copyWith(
          messages: [...currentState.messages, agentMessage],
          clearStatus: true,
        );
      }
    }
  }

  /// Handle function call events (for "thinking..." indicators)
  ChatState _handleFunctionCall(FunctionCallEvent event, ChatLoaded currentState) {
    // Show "thinking..." status indicator
    final statusMessage = 'Calling ${event.functionName}...';
    final subAgent = _extractSubAgentName(event.sourceEvent.author);

    return currentState.copyWith(
      statusMessage: statusMessage,
      statusSubAgent: subAgent,
    );
  }

  /// Handle function response events (to clear "thinking..." indicator)
  ChatState _handleFunctionResponse(FunctionResponseEvent event, ChatLoaded currentState) {
    // Clear status indicator when function completes
    return currentState.copyWith(clearStatus: true);
  }

  /// Handle error events
  ChatState _handleError(AgentErrorEvent event, ChatLoaded currentState) {
    _logger.e('Agent error: ${event.errorMessage}');

    // Show error message in chat
    final errorMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: currentState.currentSessionId,
      role: MessageRole.agent,
      content: '⚠️ Error: ${event.errorMessage}',
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );

    return currentState.copyWith(
      messages: [...currentState.messages, errorMessage],
      isSending: false,
      clearStatus: true,
    );
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    // This event is now deprecated - messages come through coordinator
    _logger.w('MessageReceived event is deprecated, use coordinator instead');
  }

  Future<void> _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) async {
    _currentStreamingMessageId = null;
    _streamingTextBuffer.clear();
    emit(const ChatInitial());
  }

  /// Extract sub-agent name from author field
  String? _extractSubAgentName(String author) {
    if (author.contains('github')) {
      return 'GitHub Agent';
    } else if (author.contains('carbon')) {
      return 'Carbon Voice Agent';
    } else if (author.contains('market') || author.contains('analyzer')) {
      return 'Market Analyzer';
    }
    return null;
  }

  /// Extract sub-agent icon from author field
  String? _extractSubAgentIcon(String author) {
    if (author.contains('github')) {
      return 'github';
    } else if (author.contains('carbon')) {
      return 'chat';
    } else if (author.contains('market') || author.contains('analyzer')) {
      return 'chart_line';
    }
    return null;
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Chat state compiles: `flutter analyze lib/features/agent_chat/presentation/bloc/chat_state.dart`
- [ ] Chat bloc compiles: `flutter analyze lib/features/agent_chat/presentation/bloc/chat_bloc.dart`
- [ ] Regenerate DI: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No compilation errors: `flutter analyze`

#### Manual Verification:
- [ ] Test sending a message in chat UI
- [ ] Verify streaming text appears correctly
- [ ] Confirm function call status indicators appear
- [ ] Check that messages display in correct order

**Implementation Note**: After completing this phase and automated verification passes, test the chat functionality manually before proceeding.

---

## Phase 5: Authentication Flow - Create MCP Auth Bloc

### Overview
Create a dedicated Bloc to handle authentication request events using the `GetAuthenticationRequestsUseCase` and manage OAuth flows for MCP tools.

### Changes Required

#### 1. Create MCP Auth Bloc Events and States
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_event.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

sealed class McpAuthEvent extends Equatable {
  const McpAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening for authentication requests for a session
class StartAuthListening extends McpAuthEvent {
  const StartAuthListening({
    required this.sessionId,
    required this.message,
    this.context,
  });

  final String sessionId;
  final String message;
  final Map<String, dynamic>? context;

  @override
  List<Object?> get props => [sessionId, message, context];
}

/// User provided authorization code from OAuth flow
class AuthCodeProvided extends McpAuthEvent {
  const AuthCodeProvided({
    required this.authorizationCode,
    required this.request,
    required this.sessionId,
  });

  final String authorizationCode;
  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [authorizationCode, request, sessionId];
}

/// User cancelled authentication
class AuthCancelled extends McpAuthEvent {
  const AuthCancelled({
    required this.request,
    required this.sessionId,
  });

  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [request, sessionId];
}

/// Stop listening for authentication requests
class StopAuthListening extends McpAuthEvent {
  const StopAuthListening();
}
```

**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_state.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:equatable/equatable.dart';

sealed class McpAuthState extends Equatable {
  const McpAuthState();

  @override
  List<Object?> get props => [];
}

class McpAuthInitial extends McpAuthState {
  const McpAuthInitial();
}

class McpAuthListening extends McpAuthState {
  const McpAuthListening({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Authentication is required - show dialog
class McpAuthRequired extends McpAuthState {
  const McpAuthRequired({
    required this.request,
    required this.sessionId,
  });

  final AuthenticationRequest request;
  final String sessionId;

  @override
  List<Object?> get props => [request, sessionId];
}

/// Processing authentication (exchanging code for token)
class McpAuthProcessing extends McpAuthState {
  const McpAuthProcessing({
    required this.provider,
    required this.sessionId,
  });

  final String provider;
  final String sessionId;

  @override
  List<Object?> get props => [provider, sessionId];
}

/// Authentication completed successfully
class McpAuthSuccess extends McpAuthState {
  const McpAuthSuccess({
    required this.provider,
    required this.sessionId,
  });

  final String provider;
  final String sessionId;

  @override
  List<Object?> get props => [provider, sessionId];
}

/// Authentication failed
class McpAuthError extends McpAuthState {
  const McpAuthError({
    required this.message,
    required this.sessionId,
  });

  final String message;
  final String sessionId;

  @override
  List<Object?> get props => [message, sessionId];
}
```

#### 2. Create MCP Auth Bloc
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/get_authentication_requests_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/usecases/send_authentication_credentials_usecase.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

@injectable
class McpAuthBloc extends Bloc<McpAuthEvent, McpAuthState> {
  McpAuthBloc(
    this._getAuthRequestsUseCase,
    this._sendCredentialsUseCase,
    this._logger,
  ) : super(const McpAuthInitial()) {
    on<StartAuthListening>(_onStartAuthListening);
    on<AuthCodeProvided>(_onAuthCodeProvided);
    on<AuthCancelled>(_onAuthCancelled);
    on<StopAuthListening>(_onStopAuthListening);
  }

  final GetAuthenticationRequestsUseCase _getAuthRequestsUseCase;
  final SendAuthenticationCredentialsUseCase _sendCredentialsUseCase;
  final Logger _logger;

  Future<void> _onStartAuthListening(
    StartAuthListening event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('Starting auth listening for session: ${event.sessionId}');

    emit(McpAuthListening(sessionId: event.sessionId));

    try {
      final authStream = _getAuthRequestsUseCase(
        sessionId: event.sessionId,
        message: event.message,
        context: event.context,
      );

      // Use emit.forEach to automatically handle stream (no manual subscription!)
      await emit.forEach<AuthenticationRequestEvent>(
        authStream,
        onData: (authEvent) {
          _logger.i('Auth request for provider: ${authEvent.request.provider}');
          return McpAuthRequired(
            request: authEvent.request,
            sessionId: event.sessionId,
          );
        },
        onError: (error, stackTrace) {
          _logger.e('Error in auth stream', error: error, stackTrace: stackTrace);
          return McpAuthError(
            message: error.toString(),
            sessionId: event.sessionId,
          );
        },
      );

      _logger.d('Auth stream completed');
      // Return to listening state after stream completes
      emit(McpAuthListening(sessionId: event.sessionId));
    } catch (e, stackTrace) {
      _logger.e('Failed to start auth listening', error: e, stackTrace: stackTrace);
      emit(McpAuthError(
        message: e.toString(),
        sessionId: event.sessionId,
      ));
    }
  }

  Future<void> _onAuthCodeProvided(
    AuthCodeProvided event,
    Emitter<McpAuthState> emit,
  ) async {
    emit(McpAuthProcessing(
      provider: event.request.provider,
      sessionId: event.sessionId,
    ));

    try {
      // Exchange authorization code for credentials
      final credentials = await _completeOAuth2Flow(
        authorizationCode: event.authorizationCode,
        request: event.request,
      );

      if (credentials == null) {
        throw Exception('Failed to obtain credentials from OAuth provider');
      }

      // Send credentials back to agent
      await _sendCredentialsUseCase(
        sessionId: event.sessionId,
        provider: event.request.provider,
        credentials: credentials,
      );

      emit(McpAuthSuccess(
        provider: event.request.provider,
        sessionId: event.sessionId,
      ));

      // Return to listening state
      emit(McpAuthListening(sessionId: event.sessionId));
    } catch (e, stackTrace) {
      _logger.e('Authentication failed', error: e, stackTrace: stackTrace);

      // Send error to agent
      await _sendCredentialsUseCase.sendError(
        sessionId: event.sessionId,
        provider: event.request.provider,
        errorMessage: e.toString(),
      );

      emit(McpAuthError(
        message: e.toString(),
        sessionId: event.sessionId,
      ));
    }
  }

  Future<void> _onAuthCancelled(
    AuthCancelled event,
    Emitter<McpAuthState> emit,
  ) async {
    _logger.i('Authentication cancelled by user');

    // Send cancellation error to agent
    await _sendCredentialsUseCase.sendError(
      sessionId: event.sessionId,
      provider: event.request.provider,
      errorMessage: 'User cancelled authentication',
    );

    emit(McpAuthListening(sessionId: event.sessionId));
  }

  Future<void> _onStopAuthListening(
    StopAuthListening event,
    Emitter<McpAuthState> emit,
  ) async {
    // No need to cancel subscription - emit.forEach handles it automatically
    emit(const McpAuthInitial());
  }

  /// Complete OAuth2 authorization code flow
  Future<oauth2.Credentials?> _completeOAuth2Flow({
    required String authorizationCode,
    required AuthenticationRequest request,
  }) async {
    try {
      final authorizationEndpoint = Uri.parse(request.authorizationUrl);
      final tokenEndpoint = Uri.parse(request.tokenUrl);

      final grant = oauth2.AuthorizationCodeGrant(
        'agent-client-id', // TODO: Make configurable per provider
        authorizationEndpoint,
        tokenEndpoint,
        secret: null, // Public client
      );

      // Exchange code for token
      final client = await grant.handleAuthorizationResponse({
        'code': authorizationCode,
      });

      return client.credentials;
    } catch (e, stackTrace) {
      _logger.e('OAuth2 flow failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
```

#### 2. Create Authentication Dialog Widget
**File**: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/buttons/app_outlined_button.dart';
import 'package:carbon_voice_console/core/widgets/interactive/app_text_field.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog to handle MCP tool authentication requests
class McpAuthenticationDialog extends StatefulWidget {
  const McpAuthenticationDialog({
    required this.request,
    required this.onAuthenticate,
    required this.onCancel,
    super.key,
  });

  final AuthenticationRequest request;
  final void Function(String authCode) onAuthenticate;
  final VoidCallback onCancel;

  @override
  State<McpAuthenticationDialog> createState() => _McpAuthenticationDialogState();
}

class _McpAuthenticationDialogState extends State<McpAuthenticationDialog> {
  final _authCodeController = TextEditingController();
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _authCodeController.dispose();
    super.dispose();
  }

  void _handleAuthenticate() {
    final code = _authCodeController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the authorization code';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    widget.onAuthenticate(code);
  }

  void _copyUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.request.authorizationUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authorization URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Authentication Required',
              style: AppTextStyle.h3.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The agent needs to access ${widget.request.provider}. '
              'Please complete the authentication process.',
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Scopes
            if (widget.request.scopes.isNotEmpty) ...[
              Text(
                'Required Permissions:',
                style: AppTextStyle.labelMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...widget.request.scopes.map((scope) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scope,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Authorization URL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 1: Open this URL in your browser',
                          style: AppTextStyle.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: _copyUrlToClipboard,
                        tooltip: 'Copy URL',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.request.authorizationUrl,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Auth code input
            Text(
              'Step 2: Paste the authorization code here',
              style: AppTextStyle.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _authCodeController,
              placeholder: 'Enter authorization code...',
              enabled: !_isAuthenticating,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppOutlinedButton(
          text: 'Cancel',
          onPressed: _isAuthenticating ? null : widget.onCancel,
        ),
        AppButton(
          text: _isAuthenticating ? 'Authenticating...' : 'Authenticate',
          onPressed: _isAuthenticating ? null : _handleAuthenticate,
        ),
      ],
    );
  }
}
```

#### 3. Create MCP Auth Listener Widget
**File**: `lib/features/agent_chat/presentation/widgets/mcp_auth_listener.dart`

```dart
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_state.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget that listens to MCP auth state and shows authentication dialogs
class McpAuthListener extends StatelessWidget {
  const McpAuthListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<McpAuthBloc, McpAuthState>(
      listener: (context, state) {
        if (state is McpAuthRequired) {
          _showAuthenticationDialog(context, state);
        } else if (state is McpAuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully authenticated with ${state.provider}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is McpAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: child,
    );
  }

  void _showAuthenticationDialog(BuildContext context, McpAuthRequired state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => McpAuthenticationDialog(
        request: state.request,
        onAuthenticate: (authCode) {
          // Dispatch event to bloc
          context.read<McpAuthBloc>().add(
                AuthCodeProvided(
                  authorizationCode: authCode,
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
          Navigator.of(dialogContext).pop();
        },
        onCancel: () {
          // Dispatch cancel event to bloc
          context.read<McpAuthBloc>().add(
                AuthCancelled(
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}
```

#### 4. Integrate MCP Auth Bloc in Main Chat Screen
**File**: `lib/features/agent_chat/presentation/screens/agent_chat_screen.dart`

Update to provide `McpAuthBloc` and wrap with listener:

```dart
// Add imports
import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/mcp_auth_listener.dart';

// In the Widget build method:
@override
Widget build(BuildContext context) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => getIt<ChatBloc>(),
      ),
      BlocProvider(
        create: (context) => getIt<McpAuthBloc>(),
      ),
    ],
    child: McpAuthListener(
      child: Scaffold(
        // ... existing screen content
      ),
    ),
  );
}

// When sending a message, also start auth listening:
void _sendMessage(String sessionId, String content) {
  // Send message through chat bloc
  context.read<ChatBloc>().add(
        SendMessageStreaming(
          sessionId: sessionId,
          content: content,
        ),
      );

  // Start auth listening
  context.read<McpAuthBloc>().add(
        StartAuthListening(
          sessionId: sessionId,
          message: content,
        ),
      );
}
```

### Success Criteria

#### Automated Verification:
- [ ] MCP auth events compile: `flutter analyze lib/features/agent_chat/presentation/bloc/mcp_auth_event.dart`
- [ ] MCP auth states compile: `flutter analyze lib/features/agent_chat/presentation/bloc/mcp_auth_state.dart`
- [ ] MCP auth bloc compiles: `flutter analyze lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
- [ ] Auth listener widget compiles: `flutter analyze lib/features/agent_chat/presentation/widgets/mcp_auth_listener.dart`
- [ ] Dialog widget compiles: `flutter analyze lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
- [ ] Screen integration compiles: `flutter analyze lib/features/agent_chat/presentation/screens/agent_chat_screen.dart`
- [ ] Regenerate DI: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No linting errors: `flutter analyze`

#### Manual Verification:
- [ ] Trigger an authentication request from agent (e.g., ask to create GitHub issue)
- [ ] Verify dialog appears with correct provider and scopes
- [ ] Copy authorization URL to clipboard works
- [ ] Paste auth code and authenticate works
- [ ] Credentials are sent back to agent successfully
- [ ] Agent can then use authenticated tools
- [ ] Cancel authentication sends error to agent

**Implementation Note**: After completing this phase, thoroughly test the authentication flow end-to-end before finalizing.

---

## Phase 6: Cleanup and Documentation

### Overview
Remove deprecated code, update documentation, and ensure the new architecture is well-documented for future developers.

### Changes Required

#### 1. Mark Old Mapper as Deprecated
**File**: `lib/features/agent_chat/data/mappers/event_mapper.dart`

Add deprecation notice at top:

```dart
// @deprecated Use adk_event_mapper.dart instead
// This file is kept temporarily for reference only

import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

@Deprecated('Use AdkEventMapper instead')
extension EventDtoMapper on EventDto {
  // ... existing code ...
}
```

#### 2. Update Feature README
**File**: `lib/features/agent_chat/README.md`

Create new documentation file:

```markdown
# Agent Chat Feature

## Architecture Overview

This feature implements ADK (Agent Development Kit) chat functionality with support for:
- Text-based agent conversations
- MCP (Model Context Protocol) tool authentication
- Real-time streaming responses
- Multi-agent coordination

## Architecture Layers

### Data Layer
- **EventDto**: Raw DTOs from ADK API (SSE stream)
- **AdkApiService**: HTTP client for ADK backend
- **AgentChatRepositoryImpl**: Converts DTOs to domain events (NO FILTERING)

### Domain Layer

#### Entities
- **AdkEvent**: Complete representation of ADK event stream events
- **AuthenticationRequest**: Extracted auth request details
- **CategorizedEvent**: Base for typed events (ChatMessageEvent, AuthenticationRequestEvent, etc.)

#### Use Cases
- **GetChatMessagesFromEventsUseCase**: Filters event stream for chat-relevant events (text, function calls, errors)
- **GetAuthenticationRequestsUseCase**: Filters event stream for authentication requests only
- **SendAuthenticationCredentialsUseCase**: Sends OAuth credentials back to ADK agent

#### Repositories
- **AgentChatRepository**: Exposes `Stream<AdkEvent>` for raw event streaming

### Presentation Layer

#### Blocs
- **ChatBloc**: Uses `GetChatMessagesFromEventsUseCase`, manages chat UI state and "thinking" indicators
- **McpAuthBloc**: Uses `GetAuthenticationRequestsUseCase`, manages OAuth flows for MCP tools
- **SessionBloc**: Manages session list and selection

#### Widgets
- **McpAuthenticationDialog**: Modal for handling OAuth2 authentication requests
- **McpAuthListener**: BlocListener that shows auth dialogs based on `McpAuthBloc` state

## Event Flow

```
ADK Backend (SSE)
    ↓
AdkApiService (Data)
    ↓ Stream<EventDto>
AgentChatRepositoryImpl (Data)
    ↓ Stream<AdkEvent> (no filtering)
Domain Use Cases (Application Layer)
    ├─→ GetChatMessagesFromEventsUseCase → ChatBloc → Chat UI
    ├─→ GetAuthenticationRequestsUseCase → McpAuthBloc → Auth Dialog
    └─→ (function calls/responses → ChatBloc for "thinking" indicators)
```

## Key Design Principles

1. **Preserve Information**: Data layer never filters events
2. **Single Responsibility**: Each use case handles one type of event filtering
3. **Dependency Inversion**: Blocs depend on use cases, not repository directly
4. **Separation of Concerns**: Blocs receive typed event streams, not raw protocol
5. **Testability**: Use cases are easily mockable, no singleton dependencies
6. **Open/Closed**: Easy to add new use cases for different event types

## Adding New Event Types

To handle a new type of ADK event:

1. Create new categorized event type in `domain/entities/categorized_event.dart`
2. Create new use case in `domain/usecases/get_[event_type]_usecase.dart`
3. Implement filtering logic in the use case
4. Inject use case into relevant bloc
5. Handle the new event type in bloc logic

## Authentication Flow

When agent requests MCP tool authentication:

1. ADK sends `adk_request_credential` function call
2. Both `ChatBloc` and `McpAuthBloc` receive events from their respective use cases
3. `GetAuthenticationRequestsUseCase` filters and yields auth request to `McpAuthBloc`
4. `McpAuthBloc` emits `McpAuthRequired` state
5. `McpAuthListener` widget shows authentication dialog
6. User completes OAuth2 flow in browser, provides auth code
7. `McpAuthBloc` exchanges code for credentials via `SendAuthenticationCredentialsUseCase`
8. Credentials sent back to ADK via repository
9. Agent can now use authenticated MCP tools

## Testing

### Unit Tests
- Test event mapper preserves all fields
- Test coordinator categorization logic
- Test authentication service OAuth flow

### Integration Tests
- Test full message send flow
- Test authentication request handling
- Test error handling

### Manual Testing
- Send message, verify streaming works
- Trigger GitHub tool, verify auth dialog
- Complete OAuth, verify agent can use tool
- Cancel auth, verify error handling
```

#### 3. Add Inline Documentation
Add comprehensive dartdoc comments to all public APIs in:
- `adk_event.dart`
- `adk_event_coordinator.dart`
- `mcp_authentication_service.dart`

### Success Criteria

#### Automated Verification:
- [ ] All files compile: `flutter analyze`
- [ ] No warnings about deprecated code usage
- [ ] Documentation builds: `flutter pub run dartdoc`

#### Manual Verification:
- [ ] README accurately describes architecture
- [ ] All public APIs have dartdoc comments
- [ ] Code is ready for handoff to other developers

---

## Testing Strategy

### Unit Tests

**Test Files to Create:**

1. `test/features/agent_chat/data/mappers/adk_event_mapper_test.dart`
   - Test all DTO → Entity mappings preserve data
   - Test edge cases (null fields, empty arrays)

2. `test/features/agent_chat/domain/services/adk_event_coordinator_test.dart`
   - Test event categorization logic
   - Test stream broadcasting
   - Test session management

3. `test/features/agent_chat/domain/services/mcp_authentication_service_test.dart`
   - Test OAuth2 flow initiation
   - Test credential sending
   - Test error handling

### Integration Tests

**Test Files to Create:**

1. `integration_test/agent_chat_flow_test.dart`
   - Test complete message send and receive flow
   - Mock ADK backend responses
   - Verify UI updates correctly

2. `integration_test/authentication_flow_test.dart`
   - Test authentication request detection
   - Test dialog presentation
   - Test credential exchange

### Manual Testing Checklist

**Chat Functionality:**
- [ ] Send simple text message
- [ ] Verify streaming response displays correctly
- [ ] Send message that triggers function call
- [ ] Verify status indicator appears during function execution
- [ ] Verify chat history persists across sessions

**Authentication Functionality:**
- [ ] Send message that requires GitHub authentication
- [ ] Verify authentication dialog appears
- [ ] Copy authorization URL to clipboard
- [ ] Complete OAuth in browser
- [ ] Paste authorization code
- [ ] Verify credentials sent to agent
- [ ] Verify agent successfully uses GitHub tools
- [ ] Cancel authentication midway
- [ ] Verify error message sent to agent

**Error Handling:**
- [ ] Disconnect network during message send
- [ ] Verify error message appears in chat
- [ ] Send invalid authentication code
- [ ] Verify error handling
- [ ] Trigger ADK backend error
- [ ] Verify error propagates correctly

## Performance Considerations

1. **Stream Memory Management**:
   - Each use case creates a new stream per invocation
   - Blocs manage subscriptions and cancel on dispose
   - No global state or broadcast streams needed

2. **Event Processing**:
   - Use cases filter events efficiently using stream operators
   - Minimal overhead per event
   - Authentication dialog shown asynchronously

3. **Parallel Streams**:
   - Multiple use cases can process same repository stream
   - Each bloc gets filtered events independently
   - No contention or locking needed

4. **Message Accumulation**:
   - Streaming messages accumulated in-memory by bloc
   - Final messages replace streaming versions
   - Old messages should be paginated (future enhancement)

## Migration Notes

### For Existing Code

If you have existing code using the old `AgentChatRepository`:

**Old Pattern:**
```dart
final result = await repository.sendMessageStreaming(
  sessionId: sessionId,
  content: content,
  onStatus: (status, agent) { /* ... */ },
);

result.fold(
  onSuccess: (messages) { /* ... */ },
  onFailure: (failure) { /* ... */ },
);
```

**New Pattern:**
```dart
// In bloc, inject use case
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._getChatMessagesUseCase, this._logger);

  final GetChatMessagesFromEventsUseCase _getChatMessagesUseCase;
  
  // In event handler
  Future<void> _onSendMessage(SendMessage event, Emitter emit) async {
    // Use emit.forEach pattern (no manual subscription!)
    await emit.forEach<CategorizedEvent>(
      _getChatMessagesUseCase(
        sessionId: event.sessionId,
        message: event.content,
      ),
      onData: (categorizedEvent) {
        // Return new state for each event
        if (categorizedEvent is ChatMessageEvent) {
          return _handleChatMessage(categorizedEvent);
        }
        // ... handle other event types
        return state;
      },
    );
  }
}
```

### Breaking Changes

- `AgentChatRepository.sendMessageStreaming()` signature changed to return `Stream<AdkEvent>`
- `AgentChatMessage` no longer created in data layer
- Blocs now inject use cases instead of repository directly
- No more `onStatus` callback in repository - use `FunctionCallEvent` from use case
- No more accumulated `Future<Result<List<Message>>>` - use streaming `Stream<CategorizedEvent>`

## References

- [ADK Events Documentation](https://google.github.io/adk-docs/events/index.md)
- [ADK Authentication Documentation](https://google.github.io/adk-docs/tools-custom/authentication/index.md)
- [Clean Architecture Principles](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)

## Future Enhancements

- [ ] Automatic OAuth URL opening in browser (instead of copy-paste)
- [ ] Token refresh handling for expired MCP credentials
- [ ] Retry logic for failed authentication attempts
- [ ] Message history persistence and pagination
- [ ] Support for long-running tool execution tracking
- [ ] State delta processing for agent state management
- [ ] Artifact delta handling for file operations

