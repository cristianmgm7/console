# Duplicate API Call Fix

## Problem

Previously, the app was making **2 separate API calls** to `/run` for every user message:
1. `ChatBloc` → `sendMessage()` → `/run` (for chat messages)
2. `McpAuthBloc` → `sendMessage()` → `/run` (for auth detection)

This was:
- ❌ Wasteful (duplicate network calls, duplicate processing)
- ❌ Error-prone (agent might generate different responses)
- ❌ Slower (two round-trips instead of one)

## Solution

Implemented a **single-call architecture** with event forwarding:

```
User Input
    ↓
ChatBloc.sendMessage() → /run (SINGLE API CALL)
    ↓
Process ALL events once
    ├─ Text events → Display in chat
    ├─ Function calls → "Thinking..." status
    ├─ Auth events → Forward to McpAuthBloc via callback
    └─ Errors → Error handling
```

## Changes Made

### 1. **ChatBloc** - Added auth forwarding callback
```dart
// New callback property
void Function(String sessionId, List<AuthenticationRequest> requests)? onAuthenticationRequired;

// In _onSendMessageStreaming:
// Check for auth events and forward them
if (authRequests.isNotEmpty && onAuthenticationRequired != null) {
  onAuthenticationRequired!(event.sessionId, authRequests);
}
```

### 2. **GetChatMessagesFromEventsUseCase** - Include auth events
```dart
// Changed from skipping auth events to including them
if (event.isAuthenticationRequest) {
  categorizedEvents.add(AuthenticationRequestEvent(
    sourceEvent: event,
    request: authRequest,
  ));
}
```

### 3. **McpAuthEvent** - New event type
```dart
// New event to receive auth requests from ChatBloc
class AuthRequestDetected extends McpAuthEvent {
  final String sessionId;
  final List<AuthenticationRequest> requests;
}
```

### 4. **McpAuthBloc** - New handler
```dart
// New handler that receives forwarded auth requests (no API call!)
Future<void> _onAuthRequestDetected(
  AuthRequestDetected event,
  Emitter<McpAuthState> emit,
) async {
  // Process auth requests without making another API call
  for (final request in event.requests) {
    emit(McpAuthRequired(request: request, sessionId: event.sessionId));
  }
}
```

### 5. **ChatInputPanel** - Wire up the callback
```dart
@override
void initState() {
  super.initState();
  // Set up callback to forward auth requests
  context.read<ChatBloc>().onAuthenticationRequired = (sessionId, requests) {
    context.read<McpAuthBloc>().add(AuthRequestDetected(
      sessionId: sessionId,
      requests: requests,
    ));
  };
}

// Removed the duplicate StartAuthListening call
```

## Migration Notes

### Deprecated
- `StartAuthListening` event - marked as deprecated
- `_onStartAuthListening` handler - still works but deprecated

### New Approach
Use `AuthRequestDetected` which receives auth requests forwarded from `ChatBloc`.

## Benefits

✅ **50% fewer API calls** - One `/run` call instead of two
✅ **Consistent responses** - Same event list processed by both blocs
✅ **Faster** - Single network round-trip
✅ **Cleaner architecture** - Single source of truth for API calls
✅ **Better separation of concerns** - ChatBloc owns API calls, McpAuthBloc handles auth UI

## Testing

To verify the fix:
1. Send a message that requires authentication
2. Check logs - should see only ONE `/run` call
3. Auth dialog should still appear correctly
4. Complete OAuth flow should work as before

## Future Improvements

Consider:
- Remove deprecated `StartAuthListening` after migration is complete
- Add streaming support (`/stream` endpoint) for real-time updates
- Implement retry logic after successful authentication

