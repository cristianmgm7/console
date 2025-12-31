# Visual Guide: Testing SSE Streaming

## What You'll See

### 1. Debug Overlay Location

```
┌────────────────────────────────────────────────────┐
│  Carbon Voice Console                              │
│                                                    │
│  ┌──────────┐                  ┌──────────────┐  │
│  │Sessions  │                  │ Stream Events│  │ ← Debug Overlay
│  │          │                  │     (3)      │  │   (Top Right)
│  │ Chat 1   │                  └──────────────┘  │
│  │ Chat 2   │                                    │
│  │          │  Chat Messages Here                │
│  │          │                                    │
│  └──────────┘                                    │
│                                                    │
│  [Type your message here...]                      │
└────────────────────────────────────────────────────┘
```

### 2. Expanded Debug Overlay

```
┌──────────────────────────────────┐
│ 🌊 Stream Events (5)        ▼   │
├──────────────────────────────────┤
│ 🌊 Stream started                │
│    12:34:56                      │
│                                  │
│ ⚙️ Function call: get_weather   │
│    12:34:57                      │
│                                  │
│ ✅ Function completed: get_we... │
│    12:34:58                      │
│                                  │
│ 💬 Chat message: The weather ... │
│    12:34:59                      │
│                                  │
│ ✅ Stream completed              │
│    12:35:00                      │
├──────────────────────────────────┤
│           Clear                  │
└──────────────────────────────────┘
```

## Real-Time Streaming Flow

### Scenario: "What's the weather in NYC?"

#### Timeline View

```
Time    Event                   Debug Overlay               Chat UI
────────────────────────────────────────────────────────────────────
0ms     User sends             🌊 Stream started           [User] What's the weather?
        message                                            

100ms   Function call          ⚙️ Function call:           [Status] Calling get_weather...
        received               get_weather                 ⏳

500ms   Function               ✅ Function completed:      [Status removed]
        completes              get_weather                 

600ms   Agent response         💬 Chat message:            [Agent] The weather in NYC is
        received               The weather in NYC...       sunny, 72°F

650ms   Stream ends            ✅ Stream completed         [Complete]
```

### Visual Representation

```
Step 1: User Message
┌────────────────────────────────┐
│                                │
│                                │
│         [User Message]         │
│    What's the weather in NYC?  │
│                                │
└────────────────────────────────┘

Step 2: Function Call (100ms later)
┌────────────────────────────────┐
│         [User Message]         │
│    What's the weather in NYC?  │
│                                │
│    ⏳ Calling get_weather...   │ ← Status appears!
│                                │
└────────────────────────────────┘

Step 3: Function Complete (500ms later)
┌────────────────────────────────┐
│         [User Message]         │
│    What's the weather in NYC?  │
│                                │
│    [Status removed]            │ ← Status disappears!
│                                │
└────────────────────────────────┘

Step 4: Agent Response (600ms later)
┌────────────────────────────────┐
│         [User Message]         │
│    What's the weather in NYC?  │
│                                │
│        [Agent Message]         │ ← Response appears!
│  The weather in NYC is sunny,  │
│  72°F with clear skies.        │
└────────────────────────────────┘
```

## Event Types & Colors

### In Debug Overlay

```
🌊 Stream started          [Cyan background]
⚙️ Function call: X        [Purple background]
✅ Function completed: X   [Green background]
💬 Chat message: ...       [Blue background]
🔐 Auth request: ...       [Amber background]
❌ Error: ...              [Red background]
```

### In Chat UI

```
[User Message]             [Blue bubble, right-aligned]
  Your message here

⏳ Calling function...     [Purple pill, centered]

[Agent Message]            [Gray bubble, left-aligned]
  Agent response here

🔐 Authentication Required [Amber card, centered]
   [Authenticate Button]
```

## Success vs Failure

### ✅ Streaming Working

```
Debug Overlay:
  Event 1 appears
  ↓ (delay)
  Event 2 appears
  ↓ (delay)
  Event 3 appears

Chat UI:
  Item 1 appears
  ↓ (delay)
  Item 2 appears
  ↓ (delay)
  Item 3 appears
```

### ❌ Not Streaming (Batch)

```
Debug Overlay:
  (nothing)
  (nothing)
  (nothing)
  ↓ (all at once)
  Event 1, 2, 3 appear simultaneously

Chat UI:
  (nothing)
  (nothing)
  (nothing)
  ↓ (all at once)
  All items appear at once
```

## Console Output

### Streaming Working

```
I/flutter: 🌊 Starting SSE stream for session: s_abc123
I/flutter: 📤 Sending message to /run_sse: http://localhost:8000/run_sse
I/flutter: 📥 Received event from agent
I/flutter: 📥 Event: FunctionCallEvent
I/flutter: ⚙️ Function call: get_weather
I/flutter: 📥 Received event from agent
I/flutter: 📥 Event: FunctionResponseEvent
I/flutter: ✅ Function completed: get_weather
I/flutter: 📥 Received event from agent
I/flutter: 📥 Event: ChatMessageEvent
I/flutter: 💬 Chat message: The weather in NYC is...
I/flutter: ✅ Stream completed
```

### Not Streaming (Problem)

```
I/flutter: 📤 Sending message to /run: http://localhost:8000/run  ← Wrong endpoint!
I/flutter: ✅ Received 3 events from agent                         ← All at once!
I/flutter: Processing event from agent
I/flutter: Processing event from agent
I/flutter: Processing event from agent
```

## Testing Checklist

### Before Testing

- [ ] ADK server running (`curl http://localhost:8000/health`)
- [ ] Flutter app running
- [ ] Debug overlay visible in top-right
- [ ] Console open to see logs

### During Test

- [ ] Send a test message
- [ ] Click debug overlay to expand
- [ ] Watch for events appearing one by one
- [ ] Observe UI updating incrementally
- [ ] Check console for "📥 Received event" messages

### Verify Streaming

- [ ] Events appear with delays between them (not all at once)
- [ ] Status indicators appear and disappear dynamically
- [ ] Console shows multiple "📥 Received event" logs
- [ ] Debug overlay shows timestamps with gaps

## Quick Test Messages

### Simple (1-2 events)
```
"Hello"
"What can you do?"
```

### With Function Call (3-4 events)
```
"What's the weather?"
"What time is it?"
```

### Multiple Functions (5+ events)
```
"Weather in NYC and London"
"Search for X and Y"
```

### With Authentication (auth event)
```
"Create a GitHub issue"
"Access my calendar"
```

## Troubleshooting Visual Guide

### Problem: Nothing Happens

```
You type → [Send] → ... (nothing) ...

Check:
1. Is ADK server running?
   → curl http://localhost:8000/health
   
2. Check console for errors
   → Look for red error messages
   
3. Check network tab (F12)
   → Look for failed requests
```

### Problem: All At Once

```
You type → [Send] → ... (wait) ... → BOOM! Everything appears

Check:
1. Using /run_sse endpoint?
   → Console should say "Sending message to /run_sse"
   
2. Using correct method?
   → Should use sendMessageStream(), not sendMessage()
```

### Problem: Overlay Not Showing

```
You type → [Send] → Events happen but no overlay

Check:
1. StreamDebugOverlay added?
   → Wrap your screen with it
   
2. Callback connected?
   → chatBloc.onDebugEvent = (event) => ...
   
3. In debug mode?
   → enabled: kDebugMode should be true
```

## Next Steps

Once streaming is confirmed working:

1. ✅ Test different message types
2. ✅ Try token-level streaming (`streaming: true`)
3. ✅ Test error scenarios
4. ✅ Measure performance
5. ✅ Remove debug overlay for production

---

**Happy streaming! 🎉**

