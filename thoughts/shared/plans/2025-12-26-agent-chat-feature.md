# Agent Chat Feature Implementation Plan

## Overview

This plan outlines the implementation of a new AI Agent Chat feature in the Carbon Voice Console Flutter app. The feature will integrate with a Google ADK-based multi-agent system, providing users with an intelligent chat interface that can delegate tasks to specialized sub-agents (GitHub, Carbon Voice, Market Analyzer).

**Goals:**
- Add a third navigation button to the side navigation bar
- Create a new chat screen with session list sidebar and conversation area
- Integrate with ADK API Server (localhost:8000 for dev, Cloud Run for production)
- Support rich markdown content and agent status updates
- Enable session persistence and resumption
- Allow context sharing from existing messages

## Current State Analysis

### Existing Architecture
- **Navigation:** GoRouter with ShellRoute pattern, 80px left sidebar with 2 buttons (Dashboard, Voice Memos)
- **State Management:** BLoC/Cubit with Injectable/GetIt dependency injection
- **UI Library:** Glassmorphism components (GlassContainer, GlassCard), theme system with AppColors/AppTextStyle
- **Network Layer:** AuthenticatedHttpService with OAuth2, Repository pattern with Result<T>
- **Data Flow:** Clean Architecture (Domain ← Data ← Presentation)

### ADK Agent System
- **Python-based** multi-agent orchestration at `/Users/cristian/Documents/tech/agents/`
- **API Server:** FastAPI exposing RESTful endpoints on port 8000
- **Key Endpoints:**
  - `POST /run` - Single response (all events at once)
  - `POST /run_sse` - Server-Sent Events streaming
  - `GET /apps/{app_name}/users/{user_id}/sessions/{session_id}` - Get session
  - `POST /apps/{app_name}/users/{user_id}/sessions/{session_id}` - Create session
  - `DELETE /apps/{app_name}/users/{user_id}/sessions/{session_id}` - Delete session
- **Sub-agents:** GitHub, Carbon Voice, Market Analyzer (orchestrated by root agent)

### Key Discoveries:
- Existing HTTP service pattern uses `AuthenticatedHttpService` with OAuth2 - we'll need a separate service for ADK API (no OAuth required)
- Session management pattern exists in Messages feature - can follow similar BLoC structure
- UI component library provides all necessary widgets (GlassContainer, AppButton, AppTextField)
- Navigation uses GoRouter ShellRoute - new screen will fit naturally into existing pattern
- BLoC providers use MultiBlocProvider pattern - straightforward to add new BLoCs

## Desired End State

### Functionality
- Users can click "Agent Chat" button in side navigation
- New screen opens with:
  - **Left:** 250px sidebar showing list of chat sessions with timestamps and preview
  - **Right:** Main chat area displaying conversation messages with markdown support
  - **Bottom:** Input panel for typing messages to the agent
- Users can create new sessions, resume existing ones, and delete old sessions
- Agent responses show which sub-agent is responding with visual indicators
- Rich content display: code blocks, lists, formatting
- Status updates show agent activity ("Searching GitHub...", "Analyzing market data...")
- Selected messages from Dashboard can be passed as context to agent

### Technical Verification
After implementation, the feature should:
- Navigate to `/dashboard/agent-chat` route successfully
- Create and manage sessions via ADK API
- Display streaming responses from agent in real-time
- Persist sessions to local storage for resumption
- Show sub-agent attribution in messages
- Render markdown content correctly
- Handle errors gracefully with user-friendly messages

## What We're NOT Doing

- **Voice input/output** - Text-only chat for this phase
- **File uploads** - No support for sending files to agent (can be added later)
- **Multi-turn conversation editing** - No ability to edit or delete individual messages
- **Agent configuration UI** - Agent parameters are hardcoded (no user-facing settings)
- **Custom sub-agent selection** - Users can't manually choose which sub-agent to use (root agent delegates automatically)
- **Export chat history** - No download/export functionality (can be added later)
- **Collaborative sessions** - Sessions are per-user only (no sharing)
- **Mobile optimization** - Desktop-first, mobile responsive layout is out of scope

## Implementation Approach

We'll implement this feature in **6 phases**, following Clean Architecture and existing patterns in the codebase. Each phase builds incrementally and is independently testable.

**Strategy:**
1. Start with routing and navigation (foundation)
2. Build UI screens and components (presentation layer)
3. Implement state management (BLoC/Cubit)
4. Create data layer (API integration, repositories)
5. Add advanced features (markdown, streaming, context sharing)
6. Polish and error handling

**Key Patterns to Follow:**
- **Navigation:** Add route to `app_router.dart` within ShellRoute
- **State Management:** BLoC for async operations (API calls), Cubit for UI state
- **API Integration:** Create `AgentApiService` similar to existing remote data sources
- **Dependency Injection:** Register all components in `injection.config.dart` using `@injectable`
- **UI Components:** Reuse GlassContainer, AppButton, AppTextField from core widgets

---

## Phase 1: Navigation & Routing Setup

### Overview
Add the Agent Chat button to side navigation and configure routing to the new screen.

### Changes Required:

#### 1. Update Side Navigation Bar
**File:** `lib/core/routing/side_navigation_bar.dart`

**Changes:** Add third navigation item for Agent Chat

```dart
// After Voice Memos button (around line 40), add:
NavigationItem(
  icon: AppIcons.robot, // or AppIcons.chatCircle
  label: 'Agent Chat',
  isSelected: currentPath == AppRoutes.agentChat,
  onTap: () => context.go(AppRoutes.agentChat),
),
```

#### 2. Define Route Constant
**File:** `lib/core/routing/app_routes.dart`

**Changes:** Add static route path

```dart
// Add to AppRoutes class (around line 15):
static const String agentChat = '/dashboard/agent-chat';
```

#### 3. Configure Router
**File:** `lib/core/routing/app_router.dart`

**Changes:** Add route to ShellRoute

```dart
// Inside ShellRoute routes list (around line 91), add:
GoRoute(
  path: 'agent-chat',
  name: AppRoutes.agentChat,
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: BlocProviders.agentChatScreen(),
  ),
),
```

#### 4. Update Route Guard
**File:** `lib/core/routing/route_guard.dart`

**Changes:** Add agent-chat to valid routes list

```dart
// Add to _allValidRoutes list (around line 30):
AppRoutes.agentChat,
```

#### 5. Add Icon to Theme
**File:** `lib/core/theme/app_icons.dart`

**Changes:** Add robot icon if not already present

```dart
// Add to AppIcons class if needed:
static const IconData robot = PhosphorIconsBold.robot;
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] No linting errors: `flutter analyze`
- [ ] Route guard tests pass (if they exist)

#### Manual Verification:
- [ ] Agent Chat button appears in side navigation below Voice Memos
- [ ] Button shows robot icon and "Agent Chat" label
- [ ] Clicking button navigates to `/dashboard/agent-chat`
- [ ] Button highlights correctly when on agent chat screen
- [ ] No console errors when navigating

**Implementation Note:** After completing this phase and all automated verification passes, pause here for manual confirmation that the navigation works correctly before proceeding to Phase 2.

---

## Phase 2: Basic Screen Structure & UI Components

### Overview
Create the agent chat screen with three main sections: session list sidebar, chat message area, and input panel.

### Changes Required:

#### 1. Create Screen Entry Point
**File:** `lib/features/agent_chat/presentation/screens/agent_chat_screen.dart` (NEW)

**Changes:** Create StatefulWidget screen with layout structure

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({super.key});

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Session list sidebar (250px)
          const SessionListSidebar(),

          // Divider
          VerticalDivider(
            width: 1,
            color: AppColors.border,
          ),

          // Main chat area
          const Expanded(
            child: ChatConversationArea(),
          ),
        ],
      ),
    );
  }
}
```

#### 2. Session List Sidebar Component
**File:** `lib/features/agent_chat/presentation/components/session_list_sidebar.dart` (NEW)

**Changes:** Create sidebar with session list

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class SessionListSidebar extends StatelessWidget {
  const SessionListSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          // Header with "New Chat" button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppButton(
              onPressed: () {
                // TODO: Create new session
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.plus, size: 18),
                  const SizedBox(width: 8),
                  const Text('New Chat'),
                ],
              ),
            ),
          ),

          const Divider(),

          // Session list
          Expanded(
            child: ListView.builder(
              itemCount: 0, // TODO: Connect to BLoC state
              itemBuilder: (context, index) {
                return const SessionListItem(); // TODO: Implement
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Session List Item Widget
**File:** `lib/features/agent_chat/presentation/widgets/session_list_item.dart` (NEW)

**Changes:** Create individual session item widget

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class SessionListItem extends StatelessWidget {
  final String sessionId;
  final String title;
  final String preview;
  final DateTime lastMessageTime;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SessionListItem({
    required this.sessionId,
    required this.title,
    required this.preview,
    required this.lastMessageTime,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
      title: Text(
        title,
        style: AppTextStyle.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            preview,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(lastMessageTime),
            style: AppTextStyle.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(AppIcons.trash, size: 18),
        color: AppColors.error,
        onPressed: onDelete,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
```

#### 4. Chat Conversation Area
**File:** `lib/features/agent_chat/presentation/components/chat_conversation_area.dart` (NEW)

**Changes:** Create main chat display area

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';

class ChatConversationArea extends StatelessWidget {
  const ChatConversationArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message list
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 0, // TODO: Connect to BLoC state
              itemBuilder: (context, index) {
                return const ChatMessageBubble(); // TODO: Implement
              },
            ),
          ),
        ),

        // Input panel at bottom
        const ChatInputPanel(),
      ],
    );
  }
}
```

#### 5. Chat Message Bubble Widget
**File:** `lib/features/agent_chat/presentation/widgets/chat_message_bubble.dart` (NEW)

**Changes:** Create message bubble component

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

enum MessageRole { user, agent }

class ChatMessageBubble extends StatelessWidget {
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? subAgentName; // For agent messages
  final IconData? subAgentIcon; // For agent messages

  const ChatMessageBubble({
    required this.content,
    required this.role,
    required this.timestamp,
    this.subAgentName,
    this.subAgentIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Agent avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                subAgentIcon ?? AppIcons.robot,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Message content
          Flexible(
            child: GlassContainer(
              opacity: 0.3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser && subAgentName != null) ...[
                      Text(
                        subAgentName!,
                        style: AppTextStyle.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Message text (TODO: Add markdown support in Phase 5)
                    Text(
                      content,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Timestamp
                    Text(
                      _formatTimestamp(timestamp),
                      style: AppTextStyle.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                AppIcons.user,
                size: 20,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }
}
```

#### 6. Chat Input Panel
**File:** `lib/features/agent_chat/presentation/components/chat_input_panel.dart` (NEW)

**Changes:** Create input area with text field and send button

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class ChatInputPanel extends StatefulWidget {
  const ChatInputPanel({super.key});

  @override
  State<ChatInputPanel> createState() => _ChatInputPanelState();
}

class _ChatInputPanelState extends State<ChatInputPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // TODO: Send message via BLoC
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Ask the agent anything...',
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 12),

          AppButton(
            onPressed: _sendMessage,
            child: Icon(AppIcons.paperPlane, size: 20),
          ),
        ],
      ),
    );
  }
}
```

#### 7. Update BLoC Providers
**File:** `lib/core/providers/bloc_providers.dart`

**Changes:** Add method for agent chat screen BLoCs

```dart
// Add to BlocProviders class:
static Widget agentChatScreen() {
  return MultiBlocProvider(
    providers: [
      // TODO: Add BLoCs in Phase 3
      // BlocProvider<AgentChatBloc>(
      //   create: (_) => getIt<AgentChatBloc>(),
      // ),
    ],
    child: const AgentChatScreen(),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] No linting errors: `flutter analyze`
- [ ] All new widgets render without errors

#### Manual Verification:
- [ ] Agent Chat screen displays with correct layout
- [ ] 250px sidebar appears on left with "New Chat" button
- [ ] Main chat area displays in center with proper spacing
- [ ] Input panel appears at bottom with text field and send button
- [ ] Glassmorphism styling matches existing design language
- [ ] Typing in input field works correctly
- [ ] Send button shows paper plane icon

**Implementation Note:** After completing this phase, verify the UI structure is correct before proceeding to Phase 3.

---

## Phase 3: State Management (BLoC/Cubit)

### Overview
Implement state management for agent chat sessions and messages using BLoC/Cubit pattern.

### Changes Required:

#### 1. Agent Chat Session Entity
**File:** `lib/features/agent_chat/domain/entities/agent_chat_session.dart` (NEW)

**Changes:** Create domain entity for chat sessions

```dart
import 'package:equatable/equatable.dart';

class AgentChatSession extends Equatable {
  final String id;
  final String userId;
  final String appName;
  final DateTime createdAt;
  final DateTime lastUpdateTime;
  final Map<String, dynamic> state;
  final String? lastMessagePreview;

  const AgentChatSession({
    required this.id,
    required this.userId,
    required this.appName,
    required this.createdAt,
    required this.lastUpdateTime,
    this.state = const {},
    this.lastMessagePreview,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        appName,
        createdAt,
        lastUpdateTime,
        state,
        lastMessagePreview,
      ];

  AgentChatSession copyWith({
    String? id,
    String? userId,
    String? appName,
    DateTime? createdAt,
    DateTime? lastUpdateTime,
    Map<String, dynamic>? state,
    String? lastMessagePreview,
  }) {
    return AgentChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appName: appName ?? this.appName,
      createdAt: createdAt ?? this.createdAt,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      state: state ?? this.state,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
```

#### 2. Agent Chat Message Entity
**File:** `lib/features/agent_chat/domain/entities/agent_chat_message.dart` (NEW)

**Changes:** Create domain entity for chat messages

```dart
import 'package:equatable/equatable.dart';

enum MessageRole { user, agent }

enum MessageStatus { sending, sent, error }

class AgentChatMessage extends Equatable {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? subAgentName;
  final String? subAgentIcon;
  final Map<String, dynamic>? metadata;

  const AgentChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.subAgentName,
    this.subAgentIcon,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        role,
        content,
        timestamp,
        status,
        subAgentName,
        subAgentIcon,
        metadata,
      ];

  AgentChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? subAgentName,
    String? subAgentIcon,
    Map<String, dynamic>? metadata,
  }) {
    return AgentChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      subAgentName: subAgentName ?? this.subAgentName,
      subAgentIcon: subAgentIcon ?? this.subAgentIcon,
      metadata: metadata ?? this.metadata,
    );
  }
}
```

#### 3. Session BLoC Events
**File:** `lib/features/agent_chat/presentation/bloc/session_event.dart` (NEW)

**Changes:** Define events for session management

```dart
import 'package:equatable/equatable.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends SessionEvent {
  const LoadSessions();
}

class CreateNewSession extends SessionEvent {
  const CreateNewSession();
}

class SelectSession extends SessionEvent {
  final String sessionId;

  const SelectSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class DeleteSession extends SessionEvent {
  final String sessionId;

  const DeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class UpdateSessionPreview extends SessionEvent {
  final String sessionId;
  final String preview;

  const UpdateSessionPreview(this.sessionId, this.preview);

  @override
  List<Object?> get props => [sessionId, preview];
}
```

#### 4. Session BLoC State
**File:** `lib/features/agent_chat/presentation/bloc/session_state.dart` (NEW)

**Changes:** Define states for session management

```dart
import 'package:equatable/equatable.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionLoaded extends SessionState {
  final List<AgentChatSession> sessions;
  final String? selectedSessionId;

  const SessionLoaded({
    required this.sessions,
    this.selectedSessionId,
  });

  @override
  List<Object?> get props => [sessions, selectedSessionId];

  SessionLoaded copyWith({
    List<AgentChatSession>? sessions,
    String? selectedSessionId,
  }) {
    return SessionLoaded(
      sessions: sessions ?? this.sessions,
      selectedSessionId: selectedSessionId ?? this.selectedSessionId,
    );
  }

  AgentChatSession? get selectedSession {
    if (selectedSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == selectedSessionId);
    } catch (e) {
      return null;
    }
  }
}

class SessionError extends SessionState {
  final String message;

  const SessionError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### 5. Session BLoC
**File:** `lib/features/agent_chat/presentation/bloc/session_bloc.dart` (NEW)

**Changes:** Implement BLoC for session management

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'session_event.dart';
import 'session_state.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_session_repository.dart';

@injectable
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final AgentSessionRepository _repository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  SessionBloc(this._repository, this._logger) : super(const SessionInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateNewSession>(_onCreateNewSession);
    on<SelectSession>(_onSelectSession);
    on<DeleteSession>(_onDeleteSession);
    on<UpdateSessionPreview>(_onUpdateSessionPreview);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await _repository.loadSessions();

    result.fold(
      onSuccess: (sessions) {
        emit(SessionLoaded(sessions: sessions));
      },
      onFailure: (failure) {
        _logger.e('Failed to load sessions', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to load sessions'));
      },
    );
  }

  Future<void> _onCreateNewSession(
    CreateNewSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final sessionId = _uuid.v4();

    final result = await _repository.createSession(sessionId);

    result.fold(
      onSuccess: (newSession) {
        final updatedSessions = [newSession, ...currentState.sessions];
        emit(SessionLoaded(
          sessions: updatedSessions,
          selectedSessionId: sessionId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to create session', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to create session'));
        // Restore previous state
        emit(currentState);
      },
    );
  }

  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    emit(currentState.copyWith(selectedSessionId: event.sessionId));
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final result = await _repository.deleteSession(event.sessionId);

    result.fold(
      onSuccess: (_) {
        final updatedSessions = currentState.sessions
            .where((s) => s.id != event.sessionId)
            .toList();

        String? newSelectedId = currentState.selectedSessionId;
        if (newSelectedId == event.sessionId) {
          newSelectedId = updatedSessions.isNotEmpty ? updatedSessions.first.id : null;
        }

        emit(SessionLoaded(
          sessions: updatedSessions,
          selectedSessionId: newSelectedId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to delete session', error: failure);
        emit(SessionError(failure.failure.details ?? 'Failed to delete session'));
        emit(currentState);
      },
    );
  }

  Future<void> _onUpdateSessionPreview(
    UpdateSessionPreview event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SessionLoaded) return;

    final updatedSessions = currentState.sessions.map((session) {
      if (session.id == event.sessionId) {
        return session.copyWith(
          lastMessagePreview: event.preview,
          lastUpdateTime: DateTime.now(),
        );
      }
      return session;
    }).toList();

    // Sort by last update time (most recent first)
    updatedSessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));

    emit(currentState.copyWith(sessions: updatedSessions));
  }
}
```

#### 6. Chat BLoC Events
**File:** `lib/features/agent_chat/presentation/bloc/chat_event.dart` (NEW)

**Changes:** Define events for chat messages

```dart
import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String sessionId;

  const LoadMessages(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class SendMessage extends ChatEvent {
  final String sessionId;
  final String content;
  final Map<String, dynamic>? context;

  const SendMessage({
    required this.sessionId,
    required this.content,
    this.context,
  });

  @override
  List<Object?> get props => [sessionId, content, context];
}

class MessageReceived extends ChatEvent {
  final String messageId;
  final String content;
  final String? subAgentName;
  final String? subAgentIcon;

  const MessageReceived({
    required this.messageId,
    required this.content,
    this.subAgentName,
    this.subAgentIcon,
  });

  @override
  List<Object?> get props => [messageId, content, subAgentName, subAgentIcon];
}

class ClearMessages extends ChatEvent {
  const ClearMessages();
}
```

#### 7. Chat BLoC State
**File:** `lib/features/agent_chat/presentation/bloc/chat_state.dart` (NEW)

**Changes:** Define states for chat messages

```dart
import 'package:equatable/equatable.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<AgentChatMessage> messages;
  final String currentSessionId;
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
  });

  @override
  List<Object?> get props => [messages, currentSessionId, isSending];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### 8. Chat BLoC
**File:** `lib/features/agent_chat/presentation/bloc/chat_bloc.dart` (NEW)

**Changes:** Implement BLoC for chat messages

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AgentChatRepository _repository;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  ChatBloc(this._repository, this._logger) : super(const ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<ClearMessages>(_onClearMessages);
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    final result = await _repository.loadMessages(event.sessionId);

    result.fold(
      onSuccess: (messages) {
        emit(ChatLoaded(
          messages: messages,
          currentSessionId: event.sessionId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to load messages', error: failure);
        emit(ChatError(failure.failure.details ?? 'Failed to load messages'));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Create user message
    final userMessage = AgentChatMessage(
      id: _uuid.v4(),
      sessionId: event.sessionId,
      role: MessageRole.user,
      content: event.content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add to UI immediately
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isSending: true,
    ));

    // Send to agent
    final result = await _repository.sendMessage(
      sessionId: event.sessionId,
      content: event.content,
      context: event.context,
    );

    result.fold(
      onSuccess: (agentMessages) {
        // Update user message to sent
        final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
        final allMessages = [
          ...currentState.messages.where((m) => m.id != userMessage.id),
          updatedUserMessage,
          ...agentMessages,
        ];

        emit(currentState.copyWith(
          messages: allMessages,
          isSending: false,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to send message', error: failure);

        // Update user message to error
        final errorMessage = userMessage.copyWith(status: MessageStatus.error);
        final updatedMessages = currentState.messages
            .map((m) => m.id == userMessage.id ? errorMessage : m)
            .toList();

        emit(currentState.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
    );
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    final agentMessage = AgentChatMessage(
      id: event.messageId,
      sessionId: currentState.currentSessionId,
      role: MessageRole.agent,
      content: event.content,
      timestamp: DateTime.now(),
      subAgentName: event.subAgentName,
      subAgentIcon: event.subAgentIcon,
    );

    emit(currentState.copyWith(
      messages: [...currentState.messages, agentMessage],
    ));
  }

  Future<void> _onClearMessages(
    ClearMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatInitial());
  }
}
```

#### 9. Update BLoC Providers
**File:** `lib/core/providers/bloc_providers.dart`

**Changes:** Register BLoCs for agent chat screen

```dart
// Update agentChatScreen method:
static Widget agentChatScreen() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SessionBloc>(
        create: (_) => getIt<SessionBloc>()..add(const LoadSessions()),
      ),
      BlocProvider<ChatBloc>(
        create: (_) => getIt<ChatBloc>(),
      ),
    ],
    child: const AgentChatScreen(),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] No linting errors: `flutter analyze`
- [ ] BLoC transitions work correctly (can verify with BLoC observer)

#### Manual Verification:
- [ ] Sessions load on screen open
- [ ] Creating new session updates the session list
- [ ] Selecting session changes UI state
- [ ] Deleting session removes it from list
- [ ] Messages load when session selected
- [ ] Sending message updates chat area
- [ ] BLoC state transitions are smooth without flickering

**Implementation Note:** After completing this phase, verify state management works correctly before implementing API integration in Phase 4.

---

## Phase 4: Data Layer & API Integration

### Overview
Implement repositories, data sources, and DTOs to integrate with the ADK API Server.

### Changes Required:

#### 1. ADK Configuration
**File:** `lib/features/agent_chat/data/config/adk_config.dart` (NEW)

**Changes:** Define ADK API configuration

```dart
class AdkConfig {
  static const String baseUrl = String.fromEnvironment(
    'ADK_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String appName = 'root_agent';
  static const int timeoutSeconds = 30;

  // For production: 'https://your-cloud-run-url.run.app'
  // Set via: flutter run --dart-define=ADK_API_URL=https://...
}
```

#### 2. ADK API Service
**File:** `lib/features/agent_chat/data/datasources/adk_api_service.dart` (NEW)

**Changes:** Create HTTP client for ADK API

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:carbon_voice_console/features/agent_chat/data/config/adk_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';

@lazySingleton
class AdkApiService {
  final http.Client _client;
  final Logger _logger;

  AdkApiService(this._client, this._logger);

  /// Create a new session
  Future<Map<String, dynamic>> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? initialState,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Creating session: $url');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(initialState ?? {}),
          )
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to create session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error creating session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to create session: $e');
    }
  }

  /// Get session details
  Future<Map<String, dynamic>> getSession({
    required String userId,
    required String sessionId,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Getting session: $url');

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to get session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error getting session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to get session: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession({
    required String userId,
    required String sessionId,
  }) async {
    final url = Uri.parse(
      '${AdkConfig.baseUrl}/apps/${AdkConfig.appName}/users/$userId/sessions/$sessionId',
    );

    _logger.d('Deleting session: $url');

    try {
      final response = await _client
          .delete(url)
          .timeout(const Duration(seconds: AdkConfig.timeoutSeconds));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to delete session: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error deleting session', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to delete session: $e');
    }
  }

  /// Send message to agent (non-streaming)
  Future<List<Map<String, dynamic>>> sendMessage({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final url = Uri.parse('${AdkConfig.baseUrl}/run');

    final requestBody = {
      'appName': AdkConfig.appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message},
          if (context != null) {'metadata': context},
        ],
      },
    };

    _logger.d('Sending message: $url');
    _logger.d('Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60)); // Longer timeout for agent responses

      if (response.statusCode == 200) {
        final events = jsonDecode(response.body) as List;
        return events.cast<Map<String, dynamic>>();
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to send message: ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error sending message', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to send message: $e');
    }
  }

  /// Send message to agent (streaming with SSE)
  /// Returns a stream of events
  Stream<Map<String, dynamic>> sendMessageStreaming({
    required String userId,
    required String sessionId,
    required String message,
    Map<String, dynamic>? context,
    bool enableTokenStreaming = false,
  }) async* {
    final url = Uri.parse('${AdkConfig.baseUrl}/run_sse');

    final requestBody = {
      'appName': AdkConfig.appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message},
          if (context != null) {'metadata': context},
        ],
      },
      'streaming': enableTokenStreaming,
    };

    _logger.d('Sending streaming message: $url');

    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw ServerException(
          statusCode: streamedResponse.statusCode,
          message: 'Failed to send streaming message',
        );
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // SSE format: "data: {...}\n\n"
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6); // Remove "data: " prefix
            try {
              final event = jsonDecode(jsonData) as Map<String, dynamic>;
              yield event;
            } catch (e) {
              _logger.w('Failed to parse SSE event: $line', error: e);
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error in streaming message', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException(message: 'Failed to stream message: $e');
    }
  }
}
```

#### 3. Session DTO
**File:** `lib/features/agent_chat/data/models/session_dto.dart` (NEW)

**Changes:** Create DTO for session data

```dart
import 'package:json_annotation/json_annotation.dart';

part 'session_dto.g.dart';

@JsonSerializable()
class SessionDto {
  final String id;
  final String appName;
  final String userId;
  final Map<String, dynamic> state;
  final List<dynamic> events;
  final double lastUpdateTime;

  SessionDto({
    required this.id,
    required this.appName,
    required this.userId,
    required this.state,
    required this.events,
    required this.lastUpdateTime,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);
}
```

#### 4. Event DTO
**File:** `lib/features/agent_chat/data/models/event_dto.dart` (NEW)

**Changes:** Create DTO for ADK events

```dart
import 'package:json_annotation/json_annotation.dart';

part 'event_dto.g.dart';

@JsonSerializable()
class EventDto {
  final String id;
  final String invocationId;
  final String author;
  final double timestamp;
  final ContentDto content;
  final ActionsDto? actions;

  EventDto({
    required this.id,
    required this.invocationId,
    required this.author,
    required this.timestamp,
    required this.content,
    this.actions,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
}

@JsonSerializable()
class ContentDto {
  final String role;
  final List<PartDto> parts;

  ContentDto({
    required this.role,
    required this.parts,
  });

  factory ContentDto.fromJson(Map<String, dynamic> json) =>
      _$ContentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDtoToJson(this);
}

@JsonSerializable()
class PartDto {
  final String? text;
  final FunctionCallDto? functionCall;
  final FunctionResponseDto? functionResponse;

  PartDto({
    this.text,
    this.functionCall,
    this.functionResponse,
  });

  factory PartDto.fromJson(Map<String, dynamic> json) =>
      _$PartDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PartDtoToJson(this);
}

@JsonSerializable()
class FunctionCallDto {
  final String id;
  final String name;
  final Map<String, dynamic> args;

  FunctionCallDto({
    required this.id,
    required this.name,
    required this.args,
  });

  factory FunctionCallDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionCallDtoToJson(this);
}

@JsonSerializable()
class FunctionResponseDto {
  final String id;
  final String name;
  final Map<String, dynamic> response;

  FunctionResponseDto({
    required this.id,
    required this.name,
    required this.response,
  });

  factory FunctionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseDtoToJson(this);
}

@JsonSerializable()
class ActionsDto {
  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;

  ActionsDto({
    this.stateDelta,
    this.artifactDelta,
  });

  factory ActionsDto.fromJson(Map<String, dynamic> json) =>
      _$ActionsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ActionsDtoToJson(this);
}
```

#### 5. DTO Mappers
**File:** `lib/features/agent_chat/data/mappers/session_mapper.dart` (NEW)

**Changes:** Map SessionDto to AgentChatSession entity

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/session_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

extension SessionDtoMapper on SessionDto {
  AgentChatSession toDomain() {
    final lastUpdateDateTime = DateTime.fromMillisecondsSinceEpoch(
      (lastUpdateTime * 1000).toInt(),
    );

    // Extract last message preview from events if available
    String? preview;
    if (events.isNotEmpty) {
      try {
        final lastEvent = events.last as Map<String, dynamic>;
        final content = lastEvent['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final firstPart = parts.first as Map<String, dynamic>;
          preview = firstPart['text'] as String?;
          if (preview != null && preview.length > 50) {
            preview = '${preview.substring(0, 50)}...';
          }
        }
      } catch (e) {
        // Ignore parsing errors for preview
      }
    }

    return AgentChatSession(
      id: id,
      userId: userId,
      appName: appName,
      createdAt: lastUpdateDateTime, // ADK doesn't provide createdAt, use lastUpdate
      lastUpdateTime: lastUpdateDateTime,
      state: state,
      lastMessagePreview: preview,
    );
  }
}
```

**File:** `lib/features/agent_chat/data/mappers/event_mapper.dart` (NEW)

**Changes:** Map EventDto to AgentChatMessage entity

```dart
import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:uuid/uuid.dart';

extension EventDtoMapper on EventDto {
  AgentChatMessage? toDomain(String sessionId) {
    // Only convert events with text content
    if (content.role != 'model') return null;

    final textParts = content.parts.where((p) => p.text != null).toList();
    if (textParts.isEmpty) return null;

    final combinedText = textParts.map((p) => p.text!).join('\n');

    // Determine sub-agent from author field
    String? subAgentName;
    String? subAgentIcon;

    if (author.contains('github')) {
      subAgentName = 'GitHub Agent';
      subAgentIcon = 'github_logo';
    } else if (author.contains('carbon')) {
      subAgentName = 'Carbon Voice Agent';
      subAgentIcon = 'chat';
    } else if (author.contains('market')) {
      subAgentName = 'Market Analyzer';
      subAgentIcon = 'chart_line';
    }

    return AgentChatMessage(
      id: id,
      sessionId: sessionId,
      role: MessageRole.agent,
      content: combinedText,
      timestamp: DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt()),
      subAgentName: subAgentName,
      subAgentIcon: subAgentIcon,
      metadata: {
        'invocationId': invocationId,
        'author': author,
      },
    );
  }

  /// Extract status message for function calls
  String? getStatusMessage() {
    final functionCalls = content.parts.where((p) => p.functionCall != null).toList();

    if (functionCalls.isNotEmpty) {
      final call = functionCalls.first.functionCall!;
      return 'Calling ${call.name}...';
    }

    return null;
  }
}
```

#### 6. Session Repository Interface
**File:** `lib/features/agent_chat/domain/repositories/agent_session_repository.dart` (NEW)

**Changes:** Define repository interface

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';

abstract class AgentSessionRepository {
  Future<Result<List<AgentChatSession>>> loadSessions();
  Future<Result<AgentChatSession>> createSession(String sessionId);
  Future<Result<AgentChatSession>> getSession(String sessionId);
  Future<Result<void>> deleteSession(String sessionId);
  Future<Result<void>> saveSessionLocally(AgentChatSession session);
}
```

#### 7. Session Repository Implementation
**File:** `lib/features/agent_chat/data/repositories/agent_session_repository_impl.dart` (NEW)

**Changes:** Implement repository with local storage and API calls

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/session_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/session_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_session.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_session_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

@LazySingleton(as: AgentSessionRepository)
class AgentSessionRepositoryImpl implements AgentSessionRepository {
  final AdkApiService _apiService;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  static const _sessionsKey = 'agent_chat_sessions';

  AgentSessionRepositoryImpl(
    this._apiService,
    this._storage,
    this._logger,
  );

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'u_123'; // Placeholder
  }

  @override
  Future<Result<List<AgentChatSession>>> loadSessions() async {
    try {
      // Load from local storage
      final sessionsJson = await _storage.read(key: _sessionsKey);

      if (sessionsJson == null) {
        return success([]);
      }

      final sessionsList = jsonDecode(sessionsJson) as List;
      final sessions = sessionsList
          .map((json) => SessionDto.fromJson(json as Map<String, dynamic>).toDomain())
          .toList();

      // Sort by last update time
      sessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));

      return success(sessions);
    } catch (e) {
      _logger.e('Error loading sessions', error: e);
      return failure(const StorageFailure(details: 'Failed to load sessions'));
    }
  }

  @override
  Future<Result<AgentChatSession>> createSession(String sessionId) async {
    try {
      final sessionData = await _apiService.createSession(
        userId: _userId,
        sessionId: sessionId,
      );

      final sessionDto = SessionDto.fromJson(sessionData);
      final session = sessionDto.toDomain();

      // Save to local storage
      await saveSessionLocally(session);

      return success(session);
    } on ServerException catch (e) {
      _logger.e('Server error creating session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error creating session', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error creating session', error: e);
      return failure(const UnknownFailure(details: 'Failed to create session'));
    }
  }

  @override
  Future<Result<AgentChatSession>> getSession(String sessionId) async {
    try {
      final sessionData = await _apiService.getSession(
        userId: _userId,
        sessionId: sessionId,
      );

      final sessionDto = SessionDto.fromJson(sessionData);
      final session = sessionDto.toDomain();

      return success(session);
    } on ServerException catch (e) {
      _logger.e('Server error getting session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error getting session', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error getting session', error: e);
      return failure(const UnknownFailure(details: 'Failed to get session'));
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _apiService.deleteSession(
        userId: _userId,
        sessionId: sessionId,
      );

      // Remove from local storage
      final sessionsResult = await loadSessions();
      final sessions = sessionsResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => <AgentChatSession>[],
      );

      final updatedSessions = sessions.where((s) => s.id != sessionId).toList();

      final sessionsJson = jsonEncode(
        updatedSessions.map((s) => {
          'id': s.id,
          'appName': s.appName,
          'userId': s.userId,
          'state': s.state,
          'events': [],
          'lastUpdateTime': s.lastUpdateTime.millisecondsSinceEpoch / 1000,
        }).toList(),
      );

      await _storage.write(key: _sessionsKey, value: sessionsJson);

      return success(null);
    } on ServerException catch (e) {
      _logger.e('Server error deleting session', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error deleting session', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error deleting session', error: e);
      return failure(const UnknownFailure(details: 'Failed to delete session'));
    }
  }

  @override
  Future<Result<void>> saveSessionLocally(AgentChatSession session) async {
    try {
      final sessionsResult = await loadSessions();
      final sessions = sessionsResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => <AgentChatSession>[],
      );

      // Add or update session
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      final sessionsJson = jsonEncode(
        sessions.map((s) => {
          'id': s.id,
          'appName': s.appName,
          'userId': s.userId,
          'state': s.state,
          'events': [],
          'lastUpdateTime': s.lastUpdateTime.millisecondsSinceEpoch / 1000,
        }).toList(),
      );

      await _storage.write(key: _sessionsKey, value: sessionsJson);

      return success(null);
    } catch (e) {
      _logger.e('Error saving session locally', error: e);
      return failure(const StorageFailure(details: 'Failed to save session'));
    }
  }
}
```

#### 8. Chat Repository Interface
**File:** `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart` (NEW)

**Changes:** Define chat repository interface

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

abstract class AgentChatRepository {
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId);
  Future<Result<List<AgentChatMessage>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  });
  Future<Result<void>> saveMessagesLocally(String sessionId, List<AgentChatMessage> messages);
}
```

#### 9. Chat Repository Implementation
**File:** `lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart` (NEW)

**Changes:** Implement chat repository

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/adk_api_service.dart';
import 'package:carbon_voice_console/features/agent_chat/data/mappers/event_mapper.dart';
import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {
  final AdkApiService _apiService;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  AgentChatRepositoryImpl(
    this._apiService,
    this._storage,
    this._logger,
  );

  String get _userId {
    // TODO: Get from UserProfileCubit or auth service
    return 'u_123'; // Placeholder
  }

  String _getMessagesKey(String sessionId) => 'agent_chat_messages_$sessionId';

  @override
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId) async {
    try {
      final messagesJson = await _storage.read(key: _getMessagesKey(sessionId));

      if (messagesJson == null) {
        return success([]);
      }

      final messagesList = jsonDecode(messagesJson) as List;
      final messages = messagesList
          .map((json) => _messageFromJson(json as Map<String, dynamic>))
          .toList();

      return success(messages);
    } catch (e) {
      _logger.e('Error loading messages', error: e);
      return failure(const StorageFailure(details: 'Failed to load messages'));
    }
  }

  @override
  Future<Result<List<AgentChatMessage>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async {
    try {
      final events = await _apiService.sendMessage(
        userId: _userId,
        sessionId: sessionId,
        message: content,
        context: context,
      );

      final agentMessages = <AgentChatMessage>[];

      for (final eventJson in events) {
        final eventDto = EventDto.fromJson(eventJson);
        final message = eventDto.toDomain(sessionId);

        if (message != null) {
          agentMessages.add(message);
        }
      }

      // Save messages locally
      if (agentMessages.isNotEmpty) {
        final existingMessages = await loadMessages(sessionId);
        final allMessages = [
          ...existingMessages.fold(onSuccess: (m) => m, onFailure: (_) => <AgentChatMessage>[]),
          ...agentMessages,
        ];
        await saveMessagesLocally(sessionId, allMessages);
      }

      return success(agentMessages);
    } on ServerException catch (e) {
      _logger.e('Server error sending message', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error sending message', error: e);
      return failure(NetworkFailure(details: e.message));
    } catch (e) {
      _logger.e('Unexpected error sending message', error: e);
      return failure(const UnknownFailure(details: 'Failed to send message'));
    }
  }

  @override
  Future<Result<void>> saveMessagesLocally(
    String sessionId,
    List<AgentChatMessage> messages,
  ) async {
    try {
      final messagesJson = jsonEncode(
        messages.map((m) => _messageToJson(m)).toList(),
      );

      await _storage.write(key: _getMessagesKey(sessionId), value: messagesJson);

      return success(null);
    } catch (e) {
      _logger.e('Error saving messages locally', error: e);
      return failure(const StorageFailure(details: 'Failed to save messages'));
    }
  }

  Map<String, dynamic> _messageToJson(AgentChatMessage message) {
    return {
      'id': message.id,
      'sessionId': message.sessionId,
      'role': message.role.name,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'status': message.status.name,
      'subAgentName': message.subAgentName,
      'subAgentIcon': message.subAgentIcon,
      'metadata': message.metadata,
    };
  }

  AgentChatMessage _messageFromJson(Map<String, dynamic> json) {
    return AgentChatMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: MessageRole.values.firstWhere((r) => r.name == json['role']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere((s) => s.name == json['status']),
      subAgentName: json['subAgentName'] as String?,
      subAgentIcon: json['subAgentIcon'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
```

#### 10. Register in DI
**File:** `lib/core/di/register_module.dart`

**Changes:** Register http.Client for ADK API

```dart
// Add to RegisterModule class:
@lazySingleton
http.Client get httpClient => http.Client();
```

#### 11. Update pubspec.yaml
**File:** `pubspec.yaml`

**Changes:** Add required dependencies

```yaml
dependencies:
  # Existing dependencies...

  # For UUID generation
  uuid: ^4.0.0

  # For JSON serialization (if not already present)
  json_annotation: ^4.8.0

  # For HTTP client (if not already present)
  http: ^1.1.0

dev_dependencies:
  # Existing dev dependencies...

  # For JSON code generation (if not already present)
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] Code generation completes: `flutter pub run build_runner build`
- [ ] No linting errors: `flutter analyze`
- [ ] Dependency injection registration succeeds

#### Manual Verification:
- [ ] Start ADK API server: `cd /Users/cristian/Documents/tech/agents && adk api_server`
- [ ] Verify server running at http://localhost:8000
- [ ] Create new session in app - check that session appears in API
- [ ] Send message - verify request reaches ADK server
- [ ] Check response appears in Flutter app
- [ ] Delete session - verify session removed from API
- [ ] Sessions persist after app restart (loaded from local storage)

**Implementation Note:** After completing this phase, verify end-to-end API integration works before adding advanced features in Phase 5.

---

## Phase 5: Advanced Features (Markdown, Streaming, Context)

### Overview
Enhance the chat feature with markdown rendering, streaming responses, and context sharing from messages.

### Changes Required:

#### 1. Add Markdown Support
**File:** `pubspec.yaml`

**Changes:** Add flutter_markdown package

```yaml
dependencies:
  # Existing dependencies...

  flutter_markdown: ^0.7.0
```

#### 2. Update Chat Message Bubble for Markdown
**File:** `lib/features/agent_chat/presentation/widgets/chat_message_bubble.dart`

**Changes:** Replace Text widget with MarkdownBody

```dart
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

// ... existing code ...

// Replace the Text widget for message content with:
MarkdownBody(
  data: content,
  styleSheet: MarkdownStyleSheet(
    p: AppTextStyle.bodyMedium.copyWith(
      color: AppColors.textPrimary,
    ),
    code: AppTextStyle.bodySmall.copyWith(
      fontFamily: 'monospace',
      backgroundColor: AppColors.surface,
      color: AppColors.accent,
    ),
    codeblockDecoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    blockquote: AppTextStyle.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      fontStyle: FontStyle.italic,
    ),
    h1: AppTextStyle.headlineLarge,
    h2: AppTextStyle.headlineMedium,
    h3: AppTextStyle.headlineSmall,
    listBullet: AppTextStyle.bodyMedium.copyWith(color: AppColors.primary),
  ),
  onTapLink: (text, href, title) {
    if (href != null) {
      launchUrl(Uri.parse(href));
    }
  },
),
```

#### 3. Add Status Indicator Widget
**File:** `lib/features/agent_chat/presentation/widgets/agent_status_indicator.dart` (NEW)

**Changes:** Create widget to show agent activity

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';

class AgentStatusIndicator extends StatelessWidget {
  final String message;
  final String? subAgentName;

  const AgentStatusIndicator({
    required this.message,
    this.subAgentName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Animated dots indicator
          SizedBox(
            width: 60,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Loop animation (will be handled by parent rebuild)
                  },
                );
              }),
            ),
          ),

          const SizedBox(width: 12),

          // Status message
          Flexible(
            child: GlassContainer(
              opacity: 0.2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subAgentName != null) ...[
                      Text(
                        subAgentName!,
                        style: AppTextStyle.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 4. Update Chat BLoC State for Status
**File:** `lib/features/agent_chat/presentation/bloc/chat_state.dart`

**Changes:** Add status message field

```dart
// Add to ChatLoaded class:
class ChatLoaded extends ChatState {
  final List<AgentChatMessage> messages;
  final String currentSessionId;
  final bool isSending;
  final String? statusMessage; // NEW
  final String? statusSubAgent; // NEW

  const ChatLoaded({
    required this.messages,
    required this.currentSessionId,
    this.isSending = false,
    this.statusMessage, // NEW
    this.statusSubAgent, // NEW
  });

  @override
  List<Object?> get props => [
        messages,
        currentSessionId,
        isSending,
        statusMessage, // NEW
        statusSubAgent, // NEW
      ];

  ChatLoaded copyWith({
    List<AgentChatMessage>? messages,
    String? currentSessionId,
    bool? isSending,
    String? statusMessage,
    String? statusSubAgent,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      isSending: isSending ?? this.isSending,
      statusMessage: statusMessage ?? this.statusMessage,
      statusSubAgent: statusSubAgent ?? this.statusSubAgent,
    );
  }
}
```

#### 5. Update Chat Conversation Area to Show Status
**File:** `lib/features/agent_chat/presentation/components/chat_conversation_area.dart`

**Changes:** Display status indicator when agent is working

```dart
// Update build method:
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Message list
      Expanded(
        child: Container(
          color: AppColors.background,
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatLoaded) {
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.messages.length + (state.statusMessage != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show status indicator as last item
                    if (state.statusMessage != null &&
                        index == state.messages.length) {
                      return AgentStatusIndicator(
                        message: state.statusMessage!,
                        subAgentName: state.statusSubAgent,
                      );
                    }

                    final message = state.messages[index];
                    return ChatMessageBubble(
                      content: message.content,
                      role: message.role,
                      timestamp: message.timestamp,
                      subAgentName: message.subAgentName,
                      subAgentIcon: message.subAgentIcon,
                    );
                  },
                );
              }

              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),

      // Input panel at bottom
      const ChatInputPanel(),
    ],
  );
}
```

#### 6. Add Streaming Support to Chat BLoC
**File:** `lib/features/agent_chat/presentation/bloc/chat_bloc.dart`

**Changes:** Add streaming message handling

```dart
// Add new event:
class SendMessageStreaming extends ChatEvent {
  final String sessionId;
  final String content;
  final Map<String, dynamic>? context;

  const SendMessageStreaming({
    required this.sessionId,
    required this.content,
    this.context,
  });

  @override
  List<Object?> get props => [sessionId, content, context];
}

// In ChatBloc constructor, register handler:
on<SendMessageStreaming>(_onSendMessageStreaming);

// Add handler method:
Future<void> _onSendMessageStreaming(
  SendMessageStreaming event,
  Emitter<ChatState> emit,
) async {
  final currentState = state;
  if (currentState is! ChatLoaded) return;

  // Create user message
  final userMessage = AgentChatMessage(
    id: _uuid.v4(),
    sessionId: event.sessionId,
    role: MessageRole.user,
    content: event.content,
    timestamp: DateTime.now(),
    status: MessageStatus.sending,
  );

  // Add to UI
  emit(currentState.copyWith(
    messages: [...currentState.messages, userMessage],
    isSending: true,
  ));

  try {
    // Use streaming repository method
    final result = await _repository.sendMessageStreaming(
      sessionId: event.sessionId,
      content: event.content,
      context: event.context,
      onStatus: (status, subAgent) {
        // Update status in real-time
        final currentState = state;
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(
            statusMessage: status,
            statusSubAgent: subAgent,
          ));
        }
      },
      onMessageChunk: (chunk) {
        // Handle streaming text chunks if needed
        // For now, we'll wait for complete messages
      },
    );

    result.fold(
      onSuccess: (agentMessages) {
        final updatedUserMessage = userMessage.copyWith(status: MessageStatus.sent);
        final allMessages = [
          ...currentState.messages.where((m) => m.id != userMessage.id),
          updatedUserMessage,
          ...agentMessages,
        ];

        emit(ChatLoaded(
          messages: allMessages,
          currentSessionId: event.sessionId,
          isSending: false,
          statusMessage: null,
          statusSubAgent: null,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to send streaming message', error: failure);

        final errorMessage = userMessage.copyWith(status: MessageStatus.error);
        final updatedMessages = currentState.messages
            .map((m) => m.id == userMessage.id ? errorMessage : m)
            .toList();

        emit(ChatLoaded(
          messages: updatedMessages,
          currentSessionId: event.sessionId,
          isSending: false,
          statusMessage: null,
          statusSubAgent: null,
        ));
      },
    );
  } catch (e) {
    _logger.e('Error in streaming', error: e);
  }
}
```

#### 7. Add Streaming to Chat Repository
**File:** `lib/features/agent_chat/domain/repositories/agent_chat_repository.dart`

**Changes:** Add streaming method signature

```dart
Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
  required String sessionId,
  required String content,
  Map<String, dynamic>? context,
  required void Function(String status, String? subAgent) onStatus,
  void Function(String chunk)? onMessageChunk,
});
```

**File:** `lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`

**Changes:** Implement streaming method

```dart
@override
Future<Result<List<AgentChatMessage>>> sendMessageStreaming({
  required String sessionId,
  required String content,
  Map<String, dynamic>? context,
  required void Function(String status, String? subAgent) onStatus,
  void Function(String chunk)? onMessageChunk,
}) async {
  try {
    final agentMessages = <AgentChatMessage>[];

    await for (final eventJson in _apiService.sendMessageStreaming(
      userId: _userId,
      sessionId: sessionId,
      message: content,
      context: context,
      enableTokenStreaming: false,
    )) {
      final eventDto = EventDto.fromJson(eventJson);

      // Check for status updates (function calls)
      final statusMsg = eventDto.getStatusMessage();
      if (statusMsg != null) {
        String? subAgent;
        if (eventDto.author.contains('github')) {
          subAgent = 'GitHub Agent';
        } else if (eventDto.author.contains('carbon')) {
          subAgent = 'Carbon Voice Agent';
        } else if (eventDto.author.contains('market')) {
          subAgent = 'Market Analyzer';
        }

        onStatus(statusMsg, subAgent);
      }

      // Convert to message
      final message = eventDto.toDomain(sessionId);
      if (message != null) {
        agentMessages.add(message);
      }
    }

    // Save messages locally
    if (agentMessages.isNotEmpty) {
      final existingMessages = await loadMessages(sessionId);
      final allMessages = [
        ...existingMessages.fold(onSuccess: (m) => m, onFailure: (_) => <AgentChatMessage>[]),
        ...agentMessages,
      ];
      await saveMessagesLocally(sessionId, allMessages);
    }

    return success(agentMessages);
  } on ServerException catch (e) {
    _logger.e('Server error streaming message', error: e);
    return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
  } on NetworkException catch (e) {
    _logger.e('Network error streaming message', error: e);
    return failure(NetworkFailure(details: e.message));
  } catch (e) {
    _logger.e('Unexpected error streaming message', error: e);
    return failure(const UnknownFailure(details: 'Failed to stream message'));
  }
}
```

#### 8. Update Input Panel to Use Streaming
**File:** `lib/features/agent_chat/presentation/components/chat_input_panel.dart`

**Changes:** Send messages with streaming

```dart
void _sendMessage() {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  final sessionState = context.read<SessionBloc>().state;
  if (sessionState is! SessionLoaded || sessionState.selectedSessionId == null) {
    return;
  }

  // Send with streaming
  context.read<ChatBloc>().add(SendMessageStreaming(
    sessionId: sessionState.selectedSessionId!,
    content: text,
  ));

  _controller.clear();
}
```

#### 9. Add Context Sharing Feature
**File:** `lib/features/agent_chat/presentation/components/context_selector_dialog.dart` (NEW)

**Changes:** Create dialog to select messages as context

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';

class ContextSelectorDialog extends StatefulWidget {
  final Function(Map<String, dynamic> context) onContextSelected;

  const ContextSelectorDialog({
    required this.onContextSelected,
    super.key,
  });

  @override
  State<ContextSelectorDialog> createState() => _ContextSelectorDialogState();
}

class _ContextSelectorDialogState extends State<ContextSelectorDialog> {
  final Set<String> _selectedMessageIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Messages for Context',
        style: AppTextStyle.headlineSmall,
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            if (state is MessageLoaded) {
              return ListView.builder(
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  final isSelected = _selectedMessageIds.contains(message.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedMessageIds.add(message.id);
                        } else {
                          _selectedMessageIds.remove(message.id);
                        }
                      });
                    },
                    title: Text(
                      'Message ${index + 1}',
                      style: AppTextStyle.bodyMedium,
                    ),
                    subtitle: Text(
                      message.createdAt.toString(),
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      actions: [
        AppTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          onPressed: () {
            if (_selectedMessageIds.isNotEmpty) {
              widget.onContextSelected({
                'selectedMessageIds': _selectedMessageIds.toList(),
              });
              Navigator.of(context).pop();
            }
          },
          child: Text('Add Context (${_selectedMessageIds.length})'),
        ),
      ],
    );
  }
}
```

#### 10. Update Input Panel with Context Button
**File:** `lib/features/agent_chat/presentation/components/chat_input_panel.dart`

**Changes:** Add button to attach context

```dart
class _ChatInputPanelState extends State<ChatInputPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, dynamic>? _context;

  // ... existing code ...

  void _showContextSelector() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MessageBloc>(),
        child: ContextSelectorDialog(
          onContextSelected: (context) {
            setState(() {
              _context = context;
            });
          },
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is! SessionLoaded || sessionState.selectedSessionId == null) {
      return;
    }

    context.read<ChatBloc>().add(SendMessageStreaming(
      sessionId: sessionState.selectedSessionId!,
      content: text,
      context: _context,
    ));

    _controller.clear();
    setState(() {
      _context = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context indicator
          if (_context != null) ...[
            GlassContainer(
              opacity: 0.2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(AppIcons.paperclip, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${(_context!['selectedMessageIds'] as List).length} messages attached',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(AppIcons.close, size: 16),
                      onPressed: () => setState(() => _context = null),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input row
          Row(
            children: [
              // Context button
              AppIconButton(
                onPressed: _showContextSelector,
                icon: Icon(AppIcons.paperclip, size: 20),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: AppTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: 'Ask the agent anything...',
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 12),

              AppButton(
                onPressed: _sendMessage,
                child: Icon(AppIcons.paperPlane, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] No linting errors: `flutter analyze`
- [ ] Markdown rendering tests pass (if written)

#### Manual Verification:
- [ ] Markdown formatting displays correctly (bold, italic, code blocks, lists)
- [ ] Code blocks show syntax highlighting
- [ ] Links in messages are clickable
- [ ] Agent status indicator appears when agent is processing
- [ ] Status messages update in real-time during streaming
- [ ] Different sub-agents show correct names/icons
- [ ] Context selector dialog opens and allows message selection
- [ ] Selected messages attach to next agent query
- [ ] Context indicator shows number of attached messages
- [ ] Removing context works correctly

**Implementation Note:** After completing this phase, thoroughly test all advanced features before moving to final polish in Phase 6.

---

## Phase 6: Error Handling & Polish

### Overview
Add comprehensive error handling, loading states, empty states, and UI polish.

### Changes Required:

#### 1. Error Display Widget
**File:** `lib/features/agent_chat/presentation/widgets/error_message_widget.dart` (NEW)

**Changes:** Create widget for displaying errors

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessageWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassContainer(
        opacity: 0.3,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.warningCircle,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: AppTextStyle.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                AppButton(
                  onPressed: onRetry,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.arrowClockwise, size: 18),
                      const SizedBox(width: 8),
                      const Text('Try Again'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 2. Empty State Widget
**File:** `lib/features/agent_chat/presentation/widgets/empty_chat_state.dart` (NEW)

**Changes:** Create widget for empty chat

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.robot,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: AppTextStyle.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask the agent anything to get started',
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _SuggestionChip(
                label: 'Analyze my GitHub repos',
                icon: AppIcons.githubLogo,
              ),
              _SuggestionChip(
                label: 'Check market trends',
                icon: AppIcons.chartLine,
              ),
              _SuggestionChip(
                label: 'Review my messages',
                icon: AppIcons.chatCircle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SuggestionChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
}
```

#### 3. Update Conversation Area with Error/Empty States
**File:** `lib/features/agent_chat/presentation/components/chat_conversation_area.dart`

**Changes:** Handle all states properly

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Message list
      Expanded(
        child: Container(
          color: AppColors.background,
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              // Loading state
              if (state is ChatLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Error state
              if (state is ChatError) {
                return ErrorMessageWidget(
                  message: state.message,
                  onRetry: () {
                    final sessionState = context.read<SessionBloc>().state;
                    if (sessionState is SessionLoaded &&
                        sessionState.selectedSessionId != null) {
                      context.read<ChatBloc>().add(
                        LoadMessages(sessionState.selectedSessionId!),
                      );
                    }
                  },
                );
              }

              // Loaded state
              if (state is ChatLoaded) {
                // Empty state
                if (state.messages.isEmpty && state.statusMessage == null) {
                  return const EmptyChatState();
                }

                // Messages list
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.messages.length +
                      (state.statusMessage != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show status indicator as last item
                    if (state.statusMessage != null &&
                        index == state.messages.length) {
                      return AgentStatusIndicator(
                        message: state.statusMessage!,
                        subAgentName: state.statusSubAgent,
                      );
                    }

                    final message = state.messages[index];
                    return ChatMessageBubble(
                      content: message.content,
                      role: message.role,
                      timestamp: message.timestamp,
                      subAgentName: message.subAgentName,
                      subAgentIcon: message.subAgentIcon,
                    );
                  },
                );
              }

              // Initial state
              return const EmptyChatState();
            },
          ),
        ),
      ),

      // Input panel at bottom
      const ChatInputPanel(),
    ],
  );
}
```

#### 4. Update Session List with Error/Empty States
**File:** `lib/features/agent_chat/presentation/components/session_list_sidebar.dart`

**Changes:** Handle loading, error, and empty states

```dart
@override
Widget build(BuildContext context) {
  return Container(
    width: 250,
    color: AppColors.surface,
    child: Column(
      children: [
        // Header with "New Chat" button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton(
            onPressed: () {
              context.read<SessionBloc>().add(const CreateNewSession());
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.plus, size: 18),
                const SizedBox(width: 8),
                const Text('New Chat'),
              ],
            ),
          ),
        ),

        const Divider(),

        // Session list
        Expanded(
          child: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              // Loading state
              if (state is SessionLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Error state
              if (state is SessionError) {
                return ErrorMessageWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<SessionBloc>().add(const LoadSessions());
                  },
                );
              }

              // Loaded state
              if (state is SessionLoaded) {
                if (state.sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No sessions yet.\nClick "New Chat" to start.',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.sessions.length,
                  itemBuilder: (context, index) {
                    final session = state.sessions[index];
                    return SessionListItem(
                      sessionId: session.id,
                      title: 'Session ${session.id.substring(0, 8)}',
                      preview: session.lastMessagePreview ?? 'New conversation',
                      lastMessageTime: session.lastUpdateTime,
                      isSelected: session.id == state.selectedSessionId,
                      onTap: () {
                        context.read<SessionBloc>().add(
                          SelectSession(session.id),
                        );
                        context.read<ChatBloc>().add(
                          LoadMessages(session.id),
                        );
                      },
                      onDelete: () {
                        context.read<SessionBloc>().add(
                          DeleteSession(session.id),
                        );
                      },
                    );
                  },
                );
              }

              // Initial state
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    ),
  );
}
```

#### 5. Add Loading Indicator to Input Panel
**File:** `lib/features/agent_chat/presentation/components/chat_input_panel.dart`

**Changes:** Disable input while sending

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<ChatBloc, ChatState>(
    builder: (context, state) {
      final isSending = state is ChatLoaded && state.isSending;

      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Context indicator (if any)
            if (_context != null) ...[
              // ... existing context indicator code ...
            ],

            // Input row
            Row(
              children: [
                // Context button
                AppIconButton(
                  onPressed: isSending ? null : _showContextSelector,
                  icon: Icon(AppIcons.paperclip, size: 20),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: AppTextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isSending,
                    hintText: isSending
                        ? 'Sending...'
                        : 'Ask the agent anything...',
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: isSending ? null : (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: 12),

                AppButton(
                  onPressed: isSending ? null : _sendMessage,
                  isLoading: isSending,
                  child: Icon(AppIcons.paperPlane, size: 20),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
```

#### 6. Add Snackbar Notifications
**File:** `lib/features/agent_chat/presentation/screens/agent_chat_screen.dart`

**Changes:** Show notifications for errors and success

```dart
@override
Widget build(BuildContext context) {
  return MultiBlocListener(
    listeners: [
      // Session error listener
      BlocListener<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<SessionBloc>().add(const LoadSessions());
                  },
                ),
              ),
            );
          }
        },
      ),

      // Chat error listener
      BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    ],
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const SessionListSidebar(),
          VerticalDivider(
            width: 1,
            color: AppColors.border,
          ),
          const Expanded(
            child: ChatConversationArea(),
          ),
        ],
      ),
    ),
  );
}
```

#### 7. Add Connection Status Indicator
**File:** `lib/features/agent_chat/presentation/widgets/connection_status_banner.dart` (NEW)

**Changes:** Show banner when ADK server is unreachable

```dart
import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onRetry;

  const ConnectionStatusBanner({
    required this.isConnected,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: AppColors.warning,
      child: Row(
        children: [
          Icon(
            AppIcons.wifiSlash,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cannot connect to agent server. Make sure the ADK server is running.',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyle.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 8. Add Health Check to API Service
**File:** `lib/features/agent_chat/data/datasources/adk_api_service.dart`

**Changes:** Add health check method

```dart
/// Check if ADK server is reachable
Future<bool> healthCheck() async {
  try {
    final url = Uri.parse('${AdkConfig.baseUrl}/list-apps');
    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 5));

    return response.statusCode == 200;
  } catch (e) {
    _logger.w('Health check failed', error: e);
    return false;
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] App compiles without errors: `flutter run`
- [ ] No linting errors: `flutter analyze`
- [ ] All error paths are covered

#### Manual Verification:
- [ ] Error messages display clearly with retry option
- [ ] Empty state shows when no sessions exist
- [ ] Empty chat state shows helpful suggestions
- [ ] Loading indicators appear during operations
- [ ] Snackbar notifications show for errors
- [ ] Connection status banner appears when server is down
- [ ] Input is disabled while sending message
- [ ] Send button shows loading state
- [ ] All error scenarios handled gracefully:
  - Network timeout
  - Server error (500)
  - Session not found (404)
  - Invalid request (400)
  - ADK server not running

**Implementation Note:** After completing this phase, perform comprehensive testing of all features and error scenarios. The implementation is now complete!

---

## Testing Strategy

### Unit Tests

**State Management:**
- SessionBloc event handling (create, select, delete sessions)
- ChatBloc event handling (load, send messages)
- State transitions and edge cases
- Repository error handling

**Data Layer:**
- DTO to Entity mapping
- API service request/response handling
- Local storage operations

### Integration Tests

**End-to-End Scenarios:**
1. Create new session → Send message → Receive response → Session appears in list
2. Select existing session → Load messages → Messages display correctly
3. Delete session → Session removed from list and storage
4. Send message with context → Context included in API request
5. Streaming response → Status updates appear → Final message displays
6. Network error → Error message displays → Retry succeeds

### Manual Testing Steps

**Session Management:**
1. Open Agent Chat screen
2. Click "New Chat" - verify new session created
3. Verify session appears in sidebar with timestamp
4. Click session - verify selection highlights
5. Delete session - verify confirmation and removal
6. Close and reopen app - verify sessions persist

**Messaging:**
1. Select session
2. Type message and send
3. Verify user message appears immediately
4. Verify status indicator shows during processing
5. Verify agent response appears with correct sub-agent info
6. Verify markdown formatting renders correctly
7. Verify code blocks display with syntax highlighting

**Context Sharing:**
1. Go to Messages Dashboard
2. Select messages
3. Open Agent Chat
4. Click context button
5. Select messages from dialog
6. Verify context indicator shows
7. Send message - verify context sent to agent

**Error Handling:**
1. Stop ADK server
2. Try to send message - verify error message and retry option
3. Try to create session - verify error handling
4. Restart server and retry - verify recovery
5. Simulate network timeout - verify appropriate error message

## Performance Considerations

**Optimizations:**
- **Lazy Loading:** Messages loaded per session, not all at once
- **Local Caching:** Sessions and messages cached in secure storage for fast access
- **Debouncing:** Input field changes debounced to prevent excessive updates
- **ListView.builder:** Efficient rendering of long message lists
- **BLoC Pattern:** Selective rebuilds with BlocBuilder prevent unnecessary widget rebuilds

**Potential Issues:**
- Large message history could slow down initial load - consider pagination in future
- Streaming responses consume memory - implement message limits per session
- Local storage could grow large - add cleanup policy for old sessions

## Migration Notes

**Database/Storage:**
- Uses FlutterSecureStorage for session persistence (encrypted on device)
- No database migration needed - fresh install for all users
- Data format: JSON-serialized sessions and messages

**Configuration:**
- Development: `ADK_API_URL=http://localhost:8000` (default)
- Production: Set via `--dart-define=ADK_API_URL=https://your-cloud-run-url`

**Deployment:**
1. Deploy ADK agent to Cloud Run
2. Update `AdkConfig.baseUrl` with production URL
3. Build Flutter app with production config
4. Test end-to-end before release

## References

- ADK Documentation: `mcp__adk-docs` (available via MCP tools)
- Existing message feature: `lib/features/messages/`
- Navigation pattern: `lib/core/routing/`
- State management examples: `lib/features/users/presentation/cubit/`
- API integration pattern: `lib/features/messages/data/datasources/message_remote_datasource_impl.dart`

---

## Summary

This implementation plan provides a complete, production-ready Agent Chat feature for the Carbon Voice Console. By following the 6 phases sequentially, we ensure:

✅ Clean Architecture with clear layer separation
✅ BLoC/Cubit state management following existing patterns
✅ Robust API integration with ADK server
✅ Rich UI with markdown, streaming, and context sharing
✅ Comprehensive error handling and polish
✅ Session persistence and resumption
✅ Seamless integration with existing features

Each phase is independently testable and builds on the previous foundation, making implementation predictable and maintainable.
