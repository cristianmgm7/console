# Quick Test: SSE Streaming

## 🚀 Quick Setup (5 minutes)

### Step 1: Replace Your Chat Screen

Open your router file (where you define routes) and change:

```dart
// Before:
import 'package:carbon_voice_console/features/agent_chat/presentation/screens/agent_chat_screen.dart';

// After:
import 'package:carbon_voice_console/features/agent_chat/presentation/screens/agent_chat_screen_with_debug.dart';

// In your routes:
// Before:
GoRoute(path: '/chat', builder: (context, state) => const AgentChatScreen()),

// After:
GoRoute(path: '/chat', builder: (context, state) => const AgentChatScreenWithDebug()),
```

**OR** manually add the debug overlay to your existing `agent_chat_screen.dart`:

```dart
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/stream_debug_overlay.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _AgentChatScreenState extends State<AgentChatScreen> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatBloc = context.read<ChatBloc>();
      chatBloc.onDebugEvent = (event) {
        if (mounted) {
          StreamDebugOverlay.logEvent(context, event);
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamDebugOverlay(
      enabled: kDebugMode,
      child: const Scaffold(
        // ... rest of your existing code
      ),
    );
  }
}
```

### Step 2: Start ADK Server

```bash
cd agent
python -m agent.agent  # or however you start your server
```

Verify it's running:
```bash
curl http://localhost:8000/health
```

### Step 3: Run Flutter App

```bash
./scripts/run_dev.sh
# or
flutter run -d chrome
```

### Step 4: Test Streaming!

1. **Look for the debug overlay** in the top-right corner (black panel)
2. **Click to expand it**
3. **Send a message** in the chat
4. **Watch events stream in real-time!**

## 🎯 What You Should See

### In the Debug Overlay:

```
🌊 Stream started
⚙️ Function call: get_weather
✅ Function completed: get_weather
💬 Chat message: The weather in NYC is...
✅ Stream completed
```

### In the Chat UI:

1. Your message appears immediately
2. "Calling get_weather..." status appears
3. Status disappears
4. Agent response appears

### In the Console:

```
I/flutter: 🌊 Starting SSE stream for session: s_123
I/flutter: 📥 Received event from agent
I/flutter: ⚙️ Function call: get_weather
I/flutter: ✅ Function completed: get_weather
I/flutter: 💬 Chat message: The weather...
```

## ✅ Success Indicators

- ✅ Events appear **one by one** in the debug overlay
- ✅ Status indicators **appear and disappear** dynamically
- ✅ Console shows **multiple "📥 Received event"** messages
- ✅ UI updates **incrementally** as events arrive

## ❌ Not Working?

### All events appear at once?

Check that you're using `/run_sse` endpoint:
```dart
// lib/features/agent_chat/data/datasources/adk_api_service.dart
// Should see:
final url = Uri.parse('${AdkConfig.baseUrl}/run_sse');
```

### No events appearing?

1. Check ADK server is running: `curl http://localhost:8000/health`
2. Check console for errors
3. Verify `AdkConfig.baseUrl` is correct

### Debug overlay not showing?

Make sure you:
1. Added the `StreamDebugOverlay` widget
2. Connected the callback: `chatBloc.onDebugEvent = ...`
3. Are in debug mode (`kDebugMode = true`)

## 🎨 Customize Debug Overlay

The overlay shows different colors for different event types:

- 🔵 Blue = Chat messages
- 🟣 Purple = Function calls
- 🟢 Green = Function completed
- 🟡 Amber = Authentication
- 🔴 Red = Errors
- 🔷 Cyan = Stream events

## 📊 Test Different Scenarios

### Test 1: Simple Question
```
You: "Hello"
Expected: 1-2 events, fast response
```

### Test 2: Function Call
```
You: "What's the weather?"
Expected: Function call → Response → Completion
```

### Test 3: Multiple Functions
```
You: "Weather in NYC and London?"
Expected: Multiple function calls, multiple completions
```

### Test 4: Authentication
```
You: "Create a GitHub issue"
Expected: Auth request event appears
```

## 🔧 Advanced: Token-Level Streaming

To see even finer-grained streaming (word by word):

```dart
// In chat_bloc.dart, change:
streaming: false, // Message-level

// To:
streaming: true, // Token-level (word by word!)
```

This will show partial messages being built character by character!

## 📖 Full Documentation

See `docs/TESTING_SSE_STREAMING.md` for complete testing guide.

---

**Happy streaming! 🌊**

