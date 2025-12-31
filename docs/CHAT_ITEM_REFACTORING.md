# Chat Item Polymorphic Architecture

## Overview

Refactored the chat system to use a **polymorphic sealed class hierarchy** for chat items instead of a monolithic `AgentChatMessage` class. This provides better type safety, cleaner separation of concerns, and more maintainable code.

## Benefits

### 1. Type Safety with Pattern Matching

Dart's sealed classes provide **compile-time exhaustiveness checking** when using switch expressions:

```dart
return switch (item) {
  TextMessageItem() => _buildTextMessage(item),
  AuthRequestItem() => _buildAuthRequest(item),
  SystemStatusItem() => _buildSystemStatus(item),
  // Compiler ensures all cases are handled!
};
```

### 2. Separation of Concerns

Each chat item type has its own purpose:
- **TextMessageItem**: User/agent text messages
- **AuthRequestItem**: Interactive OAuth requests
- **SystemStatusItem**: Status indicators (thinking, tool calls, errors)

### 3. Cleaner UI Code

Instead of checking flags and types in the UI:

```dart
// ❌ Old approach - brittle and error-prone
if (message.metadata?['isAuthRequest'] == true) {
  return AuthCard(...);
} else if (message.status == MessageStatus.error) {
  return ErrorIndicator(...);
} else {
  return TextBubble(...);
}

// ✅ New approach - type-safe and exhaustive
return switch (item) {
  TextMessageItem() => TextBubble(message: item),
  AuthRequestItem() => AuthCard(request: item.request),
  SystemStatusItem() => StatusIndicator(status: item),
};
```

## Architecture

### Domain Layer

**`chat_item.dart`** - Sealed class hierarchy:

```dart
sealed class ChatItem extends Equatable {
  final String id;
  final DateTime timestamp;
  final String? subAgentName;
  final String? subAgentIcon;
}

class TextMessageItem extends ChatItem {
  final String text;
  final MessageRole role; // user, agent, system
  final bool isPartial; // For streaming
}

class AuthRequestItem extends ChatItem {
  final AuthenticationRequest request;
}

class SystemStatusItem extends ChatItem {
  final String status;
  final StatusType type; // thinking, toolCall, handoff, error, complete
  final Map<String, dynamic>? metadata;
}
```

### Presentation Layer

**`chat_state.dart`** - Simplified state:

```dart
class ChatLoaded extends ChatState {
  final List<ChatItem> items; // Polymorphic list!
  final String currentSessionId;
  final bool isSending;
  final String? activeStatus; // Optional global status bar
}
```

**`chat_bloc.dart`** - Event-driven item creation:

```dart
await for (final categorizedEvent in eventStream) {
  if (categorizedEvent is ChatMessageEvent) {
    final item = TextMessageItem(
      id: event.sourceEvent.id,
      text: event.text,
      role: MessageRole.agent,
      timestamp: event.timestamp,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }
  
  else if (categorizedEvent is AuthenticationRequestEvent) {
    final item = AuthRequestItem(
      id: event.sourceEvent.id,
      request: event.request,
      timestamp: event.timestamp,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }
  
  else if (categorizedEvent is FunctionCallEvent) {
    final item = SystemStatusItem(
      id: 'status_${event.functionName}',
      status: 'Calling ${event.functionName}...',
      type: StatusType.toolCall,
      timestamp: event.timestamp,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }
  
  else if (categorizedEvent is FunctionResponseEvent) {
    // Remove the status item
    final updatedItems = state.items
      .where((item) => item.id != 'status_${event.functionName}')
      .toList();
    emit(state.copyWith(items: updatedItems));
  }
}
```

## UI Implementation

### Example ListView

```dart
ListView.builder(
  itemCount: state.items.length,
  itemBuilder: (context, index) {
    final item = state.items[index];

    return switch (item) {
      TextMessageItem() => TextBubble(
          message: item,
          isUser: item.role == MessageRole.user,
        ),
        
      AuthRequestItem() => AuthActionCard(
          request: item.request,
          onPressed: () => context.read<McpAuthBloc>()
            .add(StartAuth(item.request)),
        ),
        
      SystemStatusItem() => StatusIndicator(
          status: item.status,
          type: item.type,
          icon: _getIconForType(item.type),
        ),
    };
  },
)
```

### Status Types and Icons

```dart
final (icon, color) = switch (item.type) {
  StatusType.thinking => (Icons.psychology, Colors.blue),
  StatusType.toolCall => (Icons.build, Colors.purple),
  StatusType.handoff => (Icons.swap_horiz, Colors.orange),
  StatusType.error => (Icons.error, Colors.red),
  StatusType.complete => (Icons.check_circle, Colors.green),
};
```

## Migration from Old System

### Before (AgentChatMessage)

```dart
class AgentChatMessage {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final MessageStatus status; // sending, sent, error
  final String? subAgentName;
  final Map<String, dynamic>? metadata; // Used for everything!
}
```

**Problems:**
- ❌ Metadata bag for different types of data
- ❌ No type safety for auth requests or status indicators
- ❌ UI had to inspect metadata to determine rendering
- ❌ Easy to introduce bugs with wrong metadata keys

### After (ChatItem Hierarchy)

```dart
sealed class ChatItem {
  // Base properties
}

class TextMessageItem extends ChatItem { ... }
class AuthRequestItem extends ChatItem { ... }
class SystemStatusItem extends ChatItem { ... }
```

**Benefits:**
- ✅ Type-safe representation of different item types
- ✅ Compile-time exhaustiveness checking
- ✅ Clear separation of concerns
- ✅ Self-documenting code
- ✅ Impossible to create invalid states

## Status Item Lifecycle

### Function Call Flow

1. **FunctionCallEvent** → Create `SystemStatusItem` with `StatusType.toolCall`
   ```dart
   SystemStatusItem(
     id: 'status_get_weather',
     status: 'Calling get_weather...',
     type: StatusType.toolCall,
   )
   ```

2. **FunctionResponseEvent** → Remove the corresponding status item
   ```dart
   items.where((item) => item.id != 'status_get_weather')
   ```

3. **ChatMessageEvent** → Add `TextMessageItem` with the result
   ```dart
   TextMessageItem(
     text: 'The weather in NYC is...',
     role: MessageRole.agent,
   )
   ```

## Testing

The sealed class pattern makes testing easier:

```dart
test('should handle all ChatItem types', () {
  final items = [
    TextMessageItem(...),
    AuthRequestItem(...),
    SystemStatusItem(...),
  ];

  for (final item in items) {
    final widget = switch (item) {
      TextMessageItem() => TextBubble(message: item),
      AuthRequestItem() => AuthCard(request: item.request),
      SystemStatusItem() => StatusIndicator(status: item),
    };
    
    expect(widget, isNotNull);
  }
});
```

## Future Enhancements

Easily extensible for new item types:

```dart
// Add new item type
class FileAttachmentItem extends ChatItem {
  final String fileName;
  final String fileUrl;
  final int fileSize;
}

// Compiler will force you to handle it in all switch expressions!
return switch (item) {
  TextMessageItem() => ...,
  AuthRequestItem() => ...,
  SystemStatusItem() => ...,
  FileAttachmentItem() => FilePreview(item: item), // Must add!
};
```

## Summary

| Aspect | Old System | New System |
|--------|-----------|-----------|
| Type Safety | ❌ Runtime checks | ✅ Compile-time |
| Extensibility | ❌ Metadata bag | ✅ New classes |
| UI Logic | ❌ Complex conditions | ✅ Pattern matching |
| Maintainability | ❌ Error-prone | ✅ Self-documenting |
| Testing | ❌ Mock metadata | ✅ Type-safe mocks |

The polymorphic `ChatItem` architecture provides a solid foundation for building a scalable, maintainable, and type-safe chat UI! 🎉

