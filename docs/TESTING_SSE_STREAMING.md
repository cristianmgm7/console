# Testing SSE Streaming Implementation

## Overview

This guide helps you verify that the SSE (Server-Sent Events) streaming implementation is working correctly, allowing you to see messages being built in real-time.

## Prerequisites

### 1. ADK Server Running

Make sure your ADK server is running with the `/run_sse` endpoint:

```bash
# Navigate to your agent directory
cd agent

# Start the ADK server (usually on port 8000)
python -m agent.agent  # or however you start your ADK server
```

Verify the server is accessible:
```bash
curl http://localhost:8000/health
```

### 2. ADK Server Configuration

Ensure your ADK config points to the right server:

```dart
// lib/features/agent_chat/data/config/adk_config.dart
class AdkConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String appName = 'agent';
  static const int timeoutSeconds = 30;
}
```

## Setup Debug Overlay

### Option 1: Add Debug Overlay to Your App

1. Find your main chat screen (e.g., `chat_screen.dart` or wherever you display `ChatConversationArea`)

2. Wrap the screen with `StreamDebugOverlay`:

```dart
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/stream_debug_overlay.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamDebugOverlay(
      enabled: true, // Set to false to disable in production
      child: Scaffold(
        // ... your existing chat UI
      ),
    );
  }
}
```

3. Hook up the debug callback in your ChatBloc initialization:

```dart
// Wherever you initialize ChatBloc
final chatBloc = context.read<ChatBloc>();

// Set up debug event callback
chatBloc.onDebugEvent = (event) {
  StreamDebugOverlay.logEvent(context, event);
};
```

## Running the Test

### 1. Start the Flutter App

```bash
# Run the Flutter web app
./scripts/run_dev.sh

# Or manually:
flutter run -d chrome --web-port=3000
```

### 2. What You Should See

Once the app is running:

1. **Open the Debug Overlay**
   - Look for a black panel in the top-right corner labeled "Stream Events"
   - Click it to expand

2. **Send a Test Message**
   - Type a message in the chat input
   - Press send

3. **Watch the Stream in Real-Time**
   - The debug overlay will show events as they arrive:
     ```
     🌊 Stream started
     ⚙️ Function call: get_weather
     ✅ Function completed: get_weather
     💬 Chat message: The weather in NYC is...
     ✅ Stream completed
     ```

4. **Observe the Chat UI**
   - You should see items appear as events stream in:
     1. User message appears immediately
     2. "Calling get_weather..." status indicator appears
     3. Status indicator disappears when function completes
     4. Agent response appears

### Expected Streaming Behavior

For a typical agent interaction:

```
Time    Event                          UI Update
----    -----                          ---------
0ms     User sends message             User message bubble added
100ms   FunctionCallEvent             "Calling X..." status appears
500ms   FunctionResponseEvent         Status indicator removed
600ms   ChatMessageEvent              Agent response appears
```

## Debugging SSE Connection

### Check Console Logs

The Flutter console should show:

```
I/flutter: 🌊 Starting SSE stream for session: s_123
I/flutter: 📤 Sending message to /run_sse
I/flutter: 📥 Received event from agent
I/flutter: 📥 Processing categorized event: FunctionCallEvent
I/flutter: ⚙️ Function call: get_weather
I/flutter: ✅ Function completed: get_weather
I/flutter: 💬 Chat message: The weather...
I/flutter: ✅ Stream completed
```

### Test SSE Endpoint Manually

Use curl to verify the `/run_sse` endpoint works:

```bash
curl -X POST http://localhost:8000/run_sse \
  -H "Content-Type: application/json" \
  -d '{
    "appName": "agent",
    "userId": "test_user",
    "sessionId": "test_session",
    "newMessage": {
      "role": "user",
      "parts": [{"text": "Hello, what can you do?"}]
    },
    "streaming": false
  }'
```

You should see output like:
```
data: {"content":{"parts":[{"text":"..."}],"role":"model"},...}

data: {"content":{"parts":[{"text":"..."}],"role":"model"},...}
```

### Common Issues

#### 1. No Events Appearing

**Symptom:** Debug overlay shows "Stream started" but no events after

**Possible Causes:**
- ADK server not running → Check `http://localhost:8000/health`
- Wrong endpoint URL → Verify `AdkConfig.baseUrl`
- CORS issues (web only) → Check browser console for CORS errors

**Solution:**
```bash
# Verify server is responding
curl -X POST http://localhost:8000/run_sse \
  -H "Content-Type: application/json" \
  -d '{"appName":"agent","userId":"u","sessionId":"s","newMessage":{"role":"user","parts":[{"text":"hi"}]},"streaming":false}'
```

#### 2. Events Arrive But UI Doesn't Update

**Symptom:** Debug overlay shows events but chat UI doesn't change

**Possible Causes:**
- BlocBuilder not rebuilding
- State not being emitted properly

**Solution:**
Add debug prints in ChatBloc:
```dart
emit(latestState.copyWith(items: [...latestState.items, item]));
print('✅ Emitted state with ${latestState.items.length + 1} items');
```

#### 3. All Events Arrive At Once

**Symptom:** Nothing appears, then everything appears simultaneously

**Possible Causes:**
- Not using SSE endpoint (using `/run` instead)
- Buffering issue

**Solution:**
Verify in logs that `/run_sse` is being called:
```
I/flutter: 📤 Sending message to /run_sse  ← Should see this!
```

Not:
```
I/flutter: 📤 Sending message to /run  ← Wrong endpoint
```

## Testing Token-Level Streaming

To see even more granular streaming (partial messages):

```dart
// In ChatBloc
final eventStream = _getChatMessagesUseCase.call(
  sessionId: event.sessionId,
  message: event.content,
  context: event.context,
  streaming: true, // ← Enable token-level streaming!
);
```

This will stream text as it's generated, word by word or character by character.

## Verifying Real-Time Performance

### Test 1: Fast Function Calls

Send: "What's 2+2?"

Expected: Status indicator appears and disappears quickly

### Test 2: Slow Function Calls

Send: "Search for documentation on X"

Expected: 
- Status indicator appears immediately
- Stays visible for 1-3 seconds
- Disappears when function completes
- Response appears

### Test 3: Multiple Function Calls

Send: "What's the weather in NYC and London?"

Expected:
- "Calling get_weather..." appears
- "Calling get_weather..." appears again (or updates)
- Both statuses disappear
- Response appears

## Production Configuration

When deploying, disable the debug overlay:

```dart
StreamDebugOverlay(
  enabled: kDebugMode, // Only in debug builds
  child: YourApp(),
)
```

Or remove it entirely and keep only console logging.

## Summary

✅ **Working Streaming:**
- Events appear one by one in debug overlay
- Status indicators appear/disappear dynamically
- UI updates incrementally as events arrive
- Console shows "📥 Received event from..." multiple times

❌ **Not Streaming:**
- All events appear at once
- UI updates in one big batch
- Console shows events all at once
- Debug overlay shows everything simultaneously

## Next Steps

Once streaming is working:

1. Test with different agent capabilities
2. Try token-level streaming (`streaming: true`)
3. Test authentication requests
4. Test error scenarios
5. Measure streaming latency

Happy streaming! 🌊

