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
  onStatus: (status, subAgent) { /* ... */ },
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
