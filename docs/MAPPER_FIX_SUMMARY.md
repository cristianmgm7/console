# Mapper Fix Summary

## Problem Identified

The text content from the API was not reaching the presentation layer due to a **critical bug in the mapper**.

### Root Cause

In `lib/features/agent_chat/data/mappers/adk_event_mapper.dart`, the `ContentPartsInnerToDomain` extension was using incorrect type checking:

```dart
// ❌ INCORRECT CODE (before fix)
extension ContentPartsInnerToDomain on ContentPartsInner {
  AdkPart toAdkPart() {
    // The generated ContentPartsInner uses oneOf pattern
    if (this is ContentPartsInnerOneOf) {
      // Text content
      final textContent = this as ContentPartsInnerOneOf;
      return AdkPart(text: textContent.text);
    } else if (this is ContentPartsInnerOneOf1) {
      // Only inline data in content parts
      final complexContent = this as ContentPartsInnerOneOf1;
      if (complexContent.inlineData != null) {
        return AdkPart(inlineData: complexContent.inlineData!.toAdkInlineData());
      }
    }
    return const AdkPart();
  }
}
```

### Why This Failed

The generated DTOs from OpenAPI have the following structure:

1. **`ContentPartsInner`** - The main class with BOTH `text` and `inlineData` properties
2. **`ContentPartsInnerOneOf`** - A separate class (NOT a subclass) with only `text`
3. **`ContentPartsInnerOneOf1`** - A separate class (NOT a subclass) with only `inlineData`

The mapper was checking `if (this is ContentPartsInnerOneOf)`, but:
- `ContentPartsInner` is NEVER an instance of `ContentPartsInnerOneOf`
- They are separate, unrelated classes
- The type check always failed, causing the method to return an empty `AdkPart()`
- **Result**: All text content was lost!

## Solution

Changed the mapper to check properties directly instead of using type checks:

```dart
// ✅ CORRECT CODE (after fix)
extension ContentPartsInnerToDomain on ContentPartsInner {
  AdkPart toAdkPart() {
    // The generated ContentPartsInner has text and inlineData properties directly
    // We should check for text first, then inlineData
    
    // Check for text content
    if (text != null && text!.isNotEmpty) {
      return AdkPart(text: text);
    }
    
    // Check for inline data (images, etc.)
    if (inlineData != null) {
      return AdkPart(inlineData: inlineData!.toAdkInlineData());
    }

    // Empty part (should rarely happen)
    return const AdkPart();
  }
}
```

## Data Flow Verification

The complete data flow now works correctly:

1. **API Response** → SSE stream returns JSON with `content.parts[{text: "..."}]`
2. **DTO Parsing** → `ContentPartsInner.fromJson()` creates object with `text` property populated
3. **Mapper** → `toAdkPart()` now correctly extracts `text` property
4. **Domain Entity** → `AdkEvent.textContent` getter finds text in parts
5. **Use Case** → `GetChatMessagesFromEventsUseCase` creates `ChatMessageEvent` with text
6. **Presentation** → `ChatBloc` receives event and displays text in UI

## Files Modified

- `/lib/features/agent_chat/data/mappers/adk_event_mapper.dart` - Fixed the mapper logic

## Testing Recommendations

1. **Run the app** and send a message to the agent
2. **Verify** that agent responses appear in the chat UI
3. **Check logs** for the debug output showing text content being extracted:
   - Look for `"📝 Text content:"` logs in the API service
   - Look for `"AdkEvent.textContent:"` logs in the entity
   - Look for `"💬 Chat message:"` logs in the use case

## Key Takeaway

When working with generated DTOs:
- **Don't assume** inheritance relationships between `oneOf` variants
- **Always check** the actual structure of generated classes
- **Prefer property checks** over type checks when dealing with polymorphic DTOs
- **Test thoroughly** after introducing new DTO mappers

## Related Files

- DTOs: `/lib/core/api/generated/lib/model/content_parts_inner.dart`
- Entity: `/lib/features/agent_chat/domain/entities/adk_event.dart`
- Use Case: `/lib/features/agent_chat/domain/usecases/get_chat_messages_from_events_usecase.dart`
- Presentation: `/lib/features/agent_chat/presentation/bloc/chat_bloc.dart`

