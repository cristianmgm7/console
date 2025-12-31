# SSE Streaming Implementation

## Overview

Successfully migrated the agent chat system from the `/run` endpoint (batch response) to the `/run_sse` endpoint (Server-Sent Events streaming) for real-time event processing.

## Changes Made

### 1. API Service Layer (`adk_api_service.dart`)

**Added: `sendMessageStream()` method**
- Consumes the `/run_sse` endpoint using SSE (Server-Sent Events)
- Returns a `Stream<EventDto>` instead of `Future<List<EventDto>>`
- Supports both message-level (`streaming: false`) and token-level (`streaming: true`) streaming
- Parses SSE format: `data: {json}`
- Properly handles HTTP streaming with `http.Request` and `send()`

**Kept: `sendMessage()` method**
- Marked as backward compatible
- Still uses the `/run` endpoint for batch responses
- Can be deprecated in the future

### 2. Repository Layer

**Updated: `agent_chat_repository.dart` (Interface)**
- Added `sendMessageStream()` method that returns `Stream<AdkEvent>`
- Marked the old `sendMessage()` as deprecated
- Updated documentation to explain streaming vs batch modes

**Updated: `agent_chat_repository_impl.dart` (Implementation)**
- Implemented `sendMessageStream()` using `async*` generator
- Transforms DTOs to domain events as they arrive from the API
- Yields events in real-time to the use case layer
- Includes error handling that yields error events instead of throwing

### 3. Use Case Layer (`get_chat_messages_from_events_usecase.dart`)

**Refactored: Main `call()` method**
- Now returns `Stream<CategorizedEvent>` instead of `Future<Result<List<CategorizedEvent>>>`
- Uses `StreamTransformer` to categorize events as they arrive
- Applies business logic filtering in the `handleData` callback:
  - Authentication requests → `AuthenticationRequestEvent`
  - Function calls → `FunctionCallEvent` (for "thinking..." status)
  - Function responses → `FunctionResponseEvent` (clears status)
  - Text content → `ChatMessageEvent` (can be partial)
  - Errors → `AgentErrorEvent`
- Internal events (state updates, etc.) are filtered out by not emitting them

**Added: `callBatch()` method**
- Legacy method for backward compatibility
- Uses the old batch processing approach
- Marked as deprecated

### 4. Presentation Layer (`chat_bloc.dart`)

**Updated: `_onSendMessageStreaming()` method**
- Now consumes the `Stream<CategorizedEvent>` from the use case
- Uses `await for` to process events as they arrive in real-time
- Updates UI state immediately for each event
- Batches authentication requests and forwards them after stream completes
- Properly handles partial messages (for future token-level streaming)
- Maintains the same UI behavior with improved real-time feedback

## Architecture Benefits

### Clean Architecture Pattern

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (ChatBloc consumes event stream)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Domain Layer                   │
│  (Use Case applies filtering logic)     │
│  Stream<AdkEvent> → Stream<CategorizedEvent>
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Data Layer                    │
│  (Repository transforms DTOs)           │
│  Stream<EventDto> → Stream<AdkEvent>    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│       Data Source (API)                 │
│  (Parses SSE from /run_sse endpoint)    │
└─────────────────────────────────────────┘
```

### Advantages

1. **Real-time Updates**: Events are processed as they arrive, not after completion
2. **Better UX**: Users see function calls, thinking status, and responses immediately
3. **Scalability**: Token-level streaming can be enabled by setting `streaming: true`
4. **Clean Separation**: Each layer has a clear responsibility:
   - API: Parse SSE format
   - Repository: Transform DTOs to domain entities
   - Use Case: Apply business logic and filtering
   - Bloc: Update UI state
5. **Error Handling**: Errors are treated as events, not exceptions
6. **Backward Compatible**: Old batch methods are kept as deprecated

## SSE Format

The `/run_sse` endpoint returns events in this format:

```
data: {"content":{"parts":[{"functionCall":{"id":"...","args":{},"name":"..."}}],"role":"model"},...}

data: {"content":{"parts":[{"functionResponse":{"id":"...","name":"...","response":{}}}],"role":"user"},...}

data: {"content":{"parts":[{"text":"Response text"}],"role":"model"},...}
```

Each line starting with `data: ` contains a complete JSON event object.

## Token-Level Streaming

To enable token-level streaming (for partial message updates):

```dart
final eventStream = _getChatMessagesUseCase.call(
  sessionId: sessionId,
  message: message,
  context: context,
  streaming: true, // Enable token-level streaming
);
```

With `streaming: true`:
- Text is sent in chunks as it's generated
- `ChatMessageEvent.isPartial` will be `true` until final event
- UI can show live typing effect

## Testing

To test the implementation:

1. Start the ADK server with the `/run_sse` endpoint
2. Send a message from the chat UI
3. Observe real-time updates:
   - Function calls show "thinking..." status immediately
   - Function responses clear the status
   - Text responses appear as they complete
   - Authentication requests trigger OAuth flow

## Future Enhancements

- [ ] Implement token-level streaming for live typing effect
- [ ] Add retry logic for failed SSE connections
- [ ] Implement connection health monitoring
- [ ] Add metrics for stream performance
- [ ] Support multiple concurrent streams (different sessions)

