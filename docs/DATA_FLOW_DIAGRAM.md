# Data Flow: API Response → Presentation Layer

## Complete Flow (After Fix)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. API RESPONSE (SSE Stream)                                    │
│    JSON: { "content": { "parts": [{ "text": "Hello!" }] } }    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. DTO LAYER (Generated from OpenAPI)                           │
│    ContentPartsInner.fromJson() → ContentPartsInner             │
│    Properties: { text: "Hello!", inlineData: null }             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. MAPPER LAYER (adk_event_mapper.dart)                         │
│    ✅ FIXED: ContentPartsInner.toAdkPart()                      │
│    - Checks: if (text != null && text!.isNotEmpty)              │
│    - Returns: AdkPart(text: "Hello!")                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. DOMAIN ENTITY (adk_event.dart)                               │
│    AdkEvent.textContent getter                                  │
│    - Extracts text from all parts                               │
│    - Returns: "Hello!"                                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. USE CASE (get_chat_messages_from_events_usecase.dart)        │
│    Categorizes event → ChatMessageEvent                         │
│    - text: "Hello!"                                             │
│    - isPartial: false                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. PRESENTATION (chat_bloc.dart)                                │
│    Creates TextMessageItem for UI                               │
│    - Displays: "Hello!" in chat                                 │
└─────────────────────────────────────────────────────────────────┘
```

## The Bug (Before Fix)

```
┌─────────────────────────────────────────────────────────────────┐
│ MAPPER LAYER - BROKEN CODE                                      │
│                                                                  │
│ extension ContentPartsInnerToDomain on ContentPartsInner {      │
│   AdkPart toAdkPart() {                                         │
│     if (this is ContentPartsInnerOneOf) {  ❌ ALWAYS FALSE     │
│       return AdkPart(text: text);                               │
│     }                                                            │
│     return const AdkPart();  ⚠️ RETURNS EMPTY PART             │
│   }                                                              │
│ }                                                                │
│                                                                  │
│ Why it failed:                                                   │
│ - ContentPartsInner is NOT an instance of ContentPartsInnerOneOf│
│ - They are separate, unrelated classes                          │
│ - Type check always fails → empty part returned                 │
│ - Text content is lost! 💥                                      │
└─────────────────────────────────────────────────────────────────┘
```

## DTO Structure (OpenAPI Generated)

```
ContentPartsInner
├── text: String?           ← Has BOTH properties directly
└── inlineData: ContentPartsInnerOneOf1InlineData?

ContentPartsInnerOneOf      ← Separate class (NOT a subclass)
└── text: String?

ContentPartsInnerOneOf1     ← Separate class (NOT a subclass)
└── inlineData: ContentPartsInnerOneOf1InlineData?
```

## The Fix

```dart
// ✅ Check properties directly, not types
extension ContentPartsInnerToDomain on ContentPartsInner {
  AdkPart toAdkPart() {
    // Check for text content
    if (text != null && text!.isNotEmpty) {
      return AdkPart(text: text);  // ✅ Extracts text correctly
    }
    
    // Check for inline data
    if (inlineData != null) {
      return AdkPart(inlineData: inlineData!.toAdkInlineData());
    }

    return const AdkPart();
  }
}
```

## Key Insight

**OpenAPI `oneOf` doesn't generate inheritance!**

- `oneOf` in OpenAPI spec → Separate classes in Dart
- Not: `ContentPartsInnerOneOf extends ContentPartsInner`
- But: `ContentPartsInner` has all properties, separate classes for variants
- **Solution**: Check properties, not types

## Testing the Fix

### 1. Check API logs
```
📥 Received event from agent
📄 Event content: role=model, parts=1, partial=false
📋 Part type: text=true, inlineData=false
📝 Text content: "Hello, how can I help you?"
```

### 2. Check Entity logs
```
AdkEvent.textContent: parts=1, textParts=1
  Part: text="Hello, how can I help you?", hasText=true
```

### 3. Check Use Case logs
```
Text content check: textContent="Hello, how can I help you?", partial=false
💬 Chat message: Hello, how can I help you?
```

### 4. Check Presentation logs
```
📥 Processing categorized event: ChatMessageEvent
📝 Chat message: "Hello, how can I help you?" (partial: false)
```

If you see all these logs, the fix is working! ✅

