# Dashboard Bloc Refactoring Implementation Plan

## Overview

Refactor the monolithic `DashboardBloc` (428 lines) into three focused, independent blocs that can load data progressively and provide better error isolation. This will improve UX by showing partial data immediately and make the codebase more maintainable.

## Current State Analysis

The current `DashboardBloc` handles everything sequentially:
- **428 lines** of complex logic in a single file
- **Sequential loading**: Workspaces → Conversations → Messages → Users
- **All-or-nothing loading**: Users wait for everything before seeing any content
- **Tight coupling**: One state manages workspaces, conversations, messages, AND users
- **Complex state transitions**: `DashboardLoaded` has 9 fields that change together
- **Single point of failure**: If any repository fails, the whole dashboard breaks

### Key Issues Identified:
- **File**: `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart:40-152`
  - Sequential `_onDashboardLoaded` method with nested folds
  - Complex state management with many interdependent fields
- **File**: `lib/features/dashboard/presentation/bloc/dashboard_state.dart:25-83`
  - Massive `DashboardLoaded` state with 9 properties
  - Complex `copyWith` method for partial updates

## Desired End State

Three independent blocs that can load progressively:
- **WorkspaceBloc**: Manages workspace list and selection
- **ConversationBloc**: Manages conversations for selected workspace
- **MessageBloc**: Manages messages and users for selected conversations

UI shows content as soon as each bloc has data, dramatically improving perceived performance.

### Key Discoveries:
- **Repository Pattern**: All blocs can inject their respective repositories independently
- **Dependency Chain**: ConversationBloc → WorkspaceBloc, MessageBloc → ConversationBloc
- **Bloc Communication**: Blocs communicate via event streams (Bloc-to-Bloc events)
- **UI Pattern**: `MultiBlocProvider` + `BlocSelector` for granular updates

## What We're NOT Doing

- Changing repository interfaces or data models
- Modifying the API layer or network calls
- Changing the overall UI design or user experience flow
- Removing existing features (multi-select, pagination, refresh)
- Breaking existing authentication or routing logic

## Implementation Approach

Replace single `DashboardBloc` with three specialized blocs that communicate through event streams. Each bloc manages its own loading state and can fail independently.

### Communication Pattern:
```dart
// WorkspaceBloc emits events that ConversationBloc listens to
workspaceBloc.stream.listen((state) {
  if (state is WorkspaceSelected) {
    conversationBloc.add(LoadConversations(state.workspaceId));
  }
});
```

## Phase 1: Create WorkspaceBloc

### Overview
Extract workspace management logic from DashboardBloc into a focused bloc.

### Changes Required:

#### 1. Create Workspace Event Class
**File**: `lib/features/workspaces/presentation/bloc/workspace_event.dart`
```dart
sealed class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();
}

class LoadWorkspaces extends WorkspaceEvent {
  const LoadWorkspaces();
}

class SelectWorkspace extends WorkspaceEvent {
  const SelectWorkspace(this.workspaceId);
  final String workspaceId;
}
```

#### 2. Create Workspace State Class
**File**: `lib/features/workspaces/presentation/bloc/workspace_state.dart`
```dart
sealed class WorkspaceState extends Equatable {
  const WorkspaceState();
}

class WorkspaceInitial extends WorkspaceState {
  const WorkspaceInitial();
}

class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

class WorkspaceLoaded extends WorkspaceState {
  const WorkspaceLoaded(this.workspaces, this.selectedWorkspace);
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
}

class WorkspaceError extends WorkspaceState {
  const WorkspaceError(this.message);
  final String message;
}
```

#### 3. Create WorkspaceBloc Class
**File**: `lib/features/workspaces/presentation/bloc/workspace_bloc.dart`
```dart
@injectable
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc(this._workspaceRepository) : super(const WorkspaceInitial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<SelectWorkspace>(_onSelectWorkspace);
  }

  final WorkspaceRepository _workspaceRepository;

  Future<void> _onLoadWorkspaces(event, emit) async {
    emit(const WorkspaceLoading());
    final result = await _workspaceRepository.getWorkspaces();
    result.fold(
      onSuccess: (workspaces) {
        if (workspaces.isEmpty) {
          emit(const WorkspaceError('No workspaces found'));
          return;
        }
        final selected = workspaces.first;
        emit(WorkspaceLoaded(workspaces, selected));
        // Emit event for other blocs to react
        add(WorkspaceSelectedEvent(selected.id));
      },
      onFailure: (failure) => emit(WorkspaceError(failure.failure.message)),
    );
  }

  Future<void> _onSelectWorkspace(SelectWorkspace event, emit) async {
    final currentState = state;
    if (currentState is! WorkspaceLoaded) return;

    final selected = currentState.workspaces.firstWhere((w) => w.id == event.workspaceId);
    emit(WorkspaceLoaded(currentState.workspaces, selected));
    add(WorkspaceSelectedEvent(event.workspaceId));
  }
}
```

#### 4. Update Dependency Injection
**File**: Update injection configuration to include WorkspaceBloc
```dart
// Add to lib/core/di/modules/bloc_module.dart or equivalent
@module
abstract class BlocModule {
  @singleton
  WorkspaceBloc get workspaceBloc => WorkspaceBloc(getIt<WorkspaceRepository>());
}
```

### Success Criteria:

#### Automated Verification:
- [ ] WorkspaceBloc compiles without errors: `flutter build`
- [ ] Unit tests pass for WorkspaceBloc: `flutter test lib/features/workspaces/presentation/bloc/`
- [ ] Dependency injection resolves WorkspaceBloc: `flutter test integration_test/di_test.dart`

#### Manual Verification:
- [ ] WorkspaceBloc can load workspaces independently
- [ ] Workspace selection works correctly
- [ ] Bloc emits events when workspace changes

## Phase 2: Create ConversationBloc

### Overview
Extract conversation management logic, making it dependent on WorkspaceBloc.

### Changes Required:

#### 1. Create Conversation Event Class
**File**: `lib/features/conversations/presentation/bloc/conversation_event.dart`
```dart
sealed class ConversationEvent extends Equatable {
  const ConversationEvent();
}

class LoadConversations extends ConversationEvent {
  const LoadConversations(this.workspaceId);
  final String workspaceId;
}

class ToggleConversation extends ConversationEvent {
  const ToggleConversation(this.conversationId);
  final String conversationId;
}

class SelectMultipleConversations extends ConversationEvent {
  const SelectMultipleConversations(this.conversationIds);
  final Set<String> conversationIds;
}

class ClearConversationSelection extends ConversationEvent {
  const ClearConversationSelection();
}

// Internal event for reacting to workspace changes
class WorkspaceSelectedEvent extends ConversationEvent {
  const WorkspaceSelectedEvent(this.workspaceId);
  final String workspaceId;
}
```

#### 2. Create Conversation State Class
**File**: `lib/features/conversations/presentation/bloc/conversation_state.dart`
```dart
sealed class ConversationState extends Equatable {
  const ConversationState();
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationLoaded extends ConversationState {
  const ConversationLoaded({
    required this.conversations,
    required this.selectedConversationIds,
    required this.conversationColorMap,
  });
  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;
}

class ConversationError extends ConversationState {
  const ConversationError(this.message);
  final String message;
}
```

#### 3. Create ConversationBloc Class
**File**: `lib/features/conversations/presentation/bloc/conversation_bloc.dart`
```dart
@injectable
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc(this._conversationRepository) : super(const ConversationInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<ToggleConversation>(_onToggleConversation);
    on<SelectMultipleConversations>(_onSelectMultipleConversations);
    on<ClearConversationSelection>(_onClearConversationSelection);
    on<WorkspaceSelectedEvent>(_onWorkspaceSelected);
  }

  final ConversationRepository _conversationRepository;

  Future<void> _onWorkspaceSelected(WorkspaceSelectedEvent event, emit) async {
    add(LoadConversations(event.workspaceId));
  }

  Future<void> _onLoadConversations(LoadConversations event, emit) async {
    emit(const ConversationLoading());
    final result = await _conversationRepository.getConversations(event.workspaceId);
    result.fold(
      onSuccess: (conversations) {
        if (conversations.isEmpty) {
          emit(const ConversationLoaded(
            conversations: [],
            selectedConversationIds: {},
            conversationColorMap: {},
          ));
          return;
        }
        final selected = conversations.first;
        final colorMap = <String, int>{};
        for (final conversation in conversations) {
          if (conversation.colorIndex != null) {
            colorMap[conversation.id] = conversation.colorIndex!;
          }
        }
        emit(ConversationLoaded(
          conversations: conversations,
          selectedConversationIds: {selected.id},
          conversationColorMap: colorMap,
        ));
        add(ConversationSelectedEvent({selected.id}));
      },
      onFailure: (failure) => emit(ConversationError(failure.failure.message)),
    );
  }

  // ... rest of conversation selection logic
}
```

#### 4. Update Dependency Injection
Add ConversationBloc to DI configuration.

### Success Criteria:

#### Automated Verification:
- [ ] ConversationBloc compiles without errors: `flutter build`
- [ ] Unit tests pass for ConversationBloc: `flutter test lib/features/conversations/presentation/bloc/`
- [ ] Multi-select logic works correctly
- [ ] Color mapping is preserved

#### Manual Verification:
- [ ] Conversations load when workspace changes
- [ ] Multi-select conversation toggling works
- [ ] Bloc emits events when conversations change

## Phase 3: Create MessageBloc

### Overview
Extract message and user management logic, making it dependent on ConversationBloc.

### Changes Required:

#### 1. Create Message Event Class
**File**: `lib/features/messages/presentation/bloc/message_event.dart`
```dart
sealed class MessageEvent extends Equatable {
  const MessageEvent();
}

class LoadMessages extends MessageEvent {
  const LoadMessages(this.conversationIds);
  final Set<String> conversationIds;
}

class LoadMoreMessages extends MessageEvent {
  const LoadMoreMessages();
}

class RefreshMessages extends MessageEvent {
  const RefreshMessages();
}

// Internal event for reacting to conversation changes
class ConversationSelectedEvent extends MessageEvent {
  const ConversationSelectedEvent(this.conversationIds);
  final Set<String> conversationIds;
}
```

#### 2. Create Message State Class
**File**: `lib/features/messages/presentation/bloc/message_state.dart`
```dart
sealed class MessageState extends Equatable {
  const MessageState();
}

class MessageInitial extends MessageState {
  const MessageInitial();
}

class MessageLoading extends MessageState {
  const MessageLoading();
}

class MessageLoaded extends MessageState {
  const MessageLoaded({
    required this.messages,
    required this.users,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
  });
  final List<Message> messages;
  final Map<String, User> users;
  final bool isLoadingMore;
  final bool hasMoreMessages;
}

class MessageError extends MessageState {
  const MessageError(this.message);
  final String message;
}
```

#### 3. Create MessageBloc Class
**File**: `lib/features/messages/presentation/bloc/message_bloc.dart`
```dart
@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc(
    this._messageRepository,
    this._userRepository,
  ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConversationSelectedEvent>(_onConversationSelected);
  }

  final MessageRepository _messageRepository;
  final UserRepository _userRepository;
  final int _messagesPerPage = 50;
  int _currentMessageStart = 0;

  Future<void> _onConversationSelected(ConversationSelectedEvent event, emit) async {
    if (event.conversationIds.isEmpty) {
      emit(const MessageLoaded(messages: [], users: {}));
      return;
    }
    add(LoadMessages(event.conversationIds));
  }

  Future<void> _onLoadMessages(LoadMessages event, emit) async {
    emit(const MessageLoading());
    _currentMessageStart = 0;

    final result = await _messageRepository.getMessagesFromConversations(
      conversationIds: event.conversationIds,
    );

    result.fold(
      onSuccess: (messages) async => await _loadUsersAndEmit(messages, emit),
      onFailure: (failure) => emit(MessageError(failure.failure.message)),
    );
  }

  Future<void> _loadUsersAndEmit(List<Message> messages, Emitter<MessageState> emit) async {
    final userIds = messages.map((m) => m.userId).toSet().toList();
    final userResult = await _userRepository.getUsers(userIds);

    userResult.fold(
      onSuccess: (users) {
        final userMap = {for (final u in users) u.id: u};
        emit(MessageLoaded(
          messages: messages,
          users: userMap,
          hasMoreMessages: messages.length == _messagesPerPage,
        ));
      },
      onFailure: (_) => emit(MessageLoaded(
        messages: messages,
        users: {},
        hasMoreMessages: messages.length == _messagesPerPage,
      )),
    );
  }

  // ... pagination and refresh logic
}
```

#### 4. Update Dependency Injection
Add MessageBloc to DI configuration.

### Success Criteria:

#### Automated Verification:
- [ ] MessageBloc compiles without errors: `flutter build`
- [ ] Unit tests pass for MessageBloc: `flutter test lib/features/messages/presentation/bloc/`
- [ ] Pagination logic works correctly
- [ ] User loading is properly handled

#### Manual Verification:
- [ ] Messages load when conversations change
- [ ] Pagination works with infinite scroll
- [ ] User data is loaded and displayed correctly

## Phase 4: Refactor Dashboard Screen

### Overview
Replace single BlocConsumer with MultiBlocProvider and multiple BlocSelectors for progressive loading.

### Changes Required:

#### 1. Update Dashboard Screen Provider
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
```dart
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkspaceBloc>(
          create: (_) => getIt<WorkspaceBloc>()..add(const LoadWorkspaces()),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => getIt<ConversationBloc>(),
        ),
        BlocProvider<MessageBloc>(
          create: (_) => getIt<MessageBloc>(),
        ),
      ],
      child: const _DashboardScreenContent(),
    );
  }
}
```

#### 2. Setup Bloc Communication
**File**: `lib/features/dashboard/presentation/dashboard_screen.dart`
```dart
class _DashboardScreenContentState extends State<_DashboardScreenContent> {
  late final StreamSubscription<WorkspaceState> _workspaceSubscription;
  late final StreamSubscription<ConversationState> _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _setupBlocCommunication();
  }

  void _setupBlocCommunication() {
    // WorkspaceBloc -> ConversationBloc
    _workspaceSubscription = context.read<WorkspaceBloc>().stream.listen((state) {
      if (state is WorkspaceLoaded && state.selectedWorkspace != null) {
        context.read<ConversationBloc>().add(
          WorkspaceSelectedEvent(state.selectedWorkspace!.id),
        );
      }
    });

    // ConversationBloc -> MessageBloc
    _conversationSubscription = context.read<ConversationBloc>().stream.listen((state) {
      if (state is ConversationLoaded) {
        context.read<MessageBloc>().add(
          ConversationSelectedEvent(state.selectedConversationIds),
        );
      }
    });
  }

  @override
  void dispose() {
    _workspaceSubscription.cancel();
    _conversationSubscription.cancel();
    super.dispose();
  }
}
```

#### 3. Update UI Builders
Replace single BlocConsumer with multiple BlocSelectors:

```dart
Widget _buildWorkspaceDropdown() {
  return BlocSelector<WorkspaceBloc, WorkspaceState, WorkspaceLoaded?>(
    selector: (state) => state is WorkspaceLoaded ? state : null,
    builder: (context, workspaceState) {
      if (workspaceState == null) return const CircularProgressIndicator();
      // Build dropdown with workspaceState.workspaces
    },
  );
}

Widget _buildConversationDisplay() {
  return BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
    selector: (state) => state is ConversationLoaded ? state : null,
    builder: (context, conversationState) {
      if (conversationState == null) return const SizedBox.shrink();
      // Build conversation display with conversationState.selectedConversationIds
    },
  );
}

Widget _buildMessageList() {
  return BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
    selector: (state) => state is MessageLoaded ? state : null,
    builder: (context, messageState) {
      if (messageState == null) return const CircularProgressIndicator();
      // Build message list with messageState.messages and messageState.users
    },
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Dashboard screen compiles without errors: `flutter build`
- [ ] No breaking changes to existing UI behavior
- [ ] All existing event handlers still work

#### Manual Verification:
- [ ] Progressive loading works (workspaces show first, then conversations, then messages)
- [ ] All existing functionality works (workspace selection, conversation toggling, pagination)
- [ ] Error states are handled gracefully per bloc
- [ ] UI updates correctly when any bloc state changes

## Phase 5: Remove Old DashboardBloc

### Overview
Clean up the old monolithic bloc and update any remaining references.

### Changes Required:

#### 1. Remove DashboardBloc Files
**Files to delete**:
- `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`
- `lib/features/dashboard/presentation/bloc/dashboard_event.dart`
- `lib/features/dashboard/presentation/bloc/dashboard_state.dart`

#### 2. Update Dependency Injection
Remove DashboardBloc from DI configuration.

#### 3. Update Imports
Remove any remaining imports of the old DashboardBloc in the dashboard screen.

### Success Criteria:

#### Automated Verification:
- [ ] Project compiles without DashboardBloc references: `flutter build`
- [ ] All tests pass: `flutter test`
- [ ] Dependency injection works without DashboardBloc

#### Manual Verification:
- [ ] App starts and dashboard loads correctly
- [ ] All functionality works as before
- [ ] No runtime errors or missing dependencies

## Testing Strategy

### Unit Tests:
- Test each bloc in isolation with mocked repositories
- Test state transitions for each bloc
- Test event handling and error states
- Test bloc-to-bloc communication streams

### Integration Tests:
- Test the complete dashboard flow with real repositories
- Test progressive loading behavior
- Test error recovery when individual blocs fail
- Test that UI updates correctly with multiple blocs

### Manual Testing Steps:
1. Launch app and verify workspaces load immediately
2. Verify conversations load when workspace is selected
3. Verify messages load when conversations are selected
4. Test multi-select conversation functionality
5. Test pagination with "load more" functionality
6. Test error scenarios (network failures, empty data)
7. Test refresh functionality
8. Verify message selection and action panel work

## Performance Considerations

- **Progressive Loading**: UI becomes interactive faster
- **Independent Caching**: Each bloc can cache its data independently
- **Reduced Memory Pressure**: Smaller state objects per bloc
- **Better Error Recovery**: One bloc failure doesn't break others

## Migration Notes

- **Backwards Compatibility**: UI behavior remains identical to users
- **Gradual Rollout**: Can deploy bloc-by-bloc if needed
- **Data Consistency**: All blocs use same repositories, so data remains consistent
- **State Migration**: No user data migration needed (stateless UI)

## References

- Current DashboardBloc: `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`
- Repository interfaces: `lib/features/*/domain/repositories/`
- Current UI implementation: `lib/features/dashboard/presentation/dashboard_screen.dart`
