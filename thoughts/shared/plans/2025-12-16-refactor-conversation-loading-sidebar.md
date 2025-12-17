# Refactor Conversation Loading with Recent Channels API and Sidebar Layout

## Overview

Refactor the conversation loading mechanism to use the `/channels/recent` endpoint instead of `/channels/{workspaceId}` to handle users with many conversations. Additionally, restructure the dashboard layout to follow a Slack-like sidebar pattern, moving workspace selector and conversation list from the app bar to a left sidebar.

## Current State Analysis

**Current Conversation Loading:**
- Uses `/channels/{workspaceId}` endpoint in `lib/features/conversations/data/datasources/conversation_remote_datasource_impl.dart:22`
- Loads ALL conversations for a workspace, causing performance issues for users with many conversations
- Has workspace-based in-memory cache in `lib/features/conversations/data/repositories/conversation_repository_impl.dart:19`
- BLoC triggers load when workspace is selected via `WorkspaceSelectedEvent` in `lib/features/conversations/presentation/bloc/conversation_bloc.dart:45-50`

**Current UI Structure:**
- App bar (`lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart`) contains:
  - Dashboard Title
  - Workspace Section (dropdown selector)
  - Conversation Selector Section (multi-select dropdown)
  - Selected Conversations Section
  - Action buttons (Preview, Send Message, Search)
- Dashboard content is a Stack with message list and various overlays
- No sidebar currently exists

**Key Discoveries:**
- Messages already use cursor-based pagination with `beforeTimestamp` parameter (`lib/features/messages/data/datasources/message_remote_datasource.dart:15-20`)
- Pagination controls already exist for messages (`lib/features/messages/presentation_messages_dashboard/widgets/dashboard_content/pagination_controls_wrapper.dart`)
- ConversationDto has `workspace_guid` field, allowing client-side filtering
- The `/channels/recent` endpoint returns the same DTO structure, so no DTO changes needed

## Desired End State

**After implementation:**
1. Conversations load via `/channels/recent` endpoint with pagination support
2. Client-side filtering by selected workspace
3. Slack-like layout with left sidebar containing:
   - Workspace selector at top
   - Paginated conversation list below
   - "Load More" button at bottom when more conversations exist
4. App bar simplified to show only:
   - Dashboard title
   - Selected conversations display
   - Action buttons
5. Workspace selection triggers fresh load of recent channels filtered to that workspace

**Verification:**
- Users with 100+ conversations can load and navigate smoothly
- Pagination loads next batch of conversations
- Switching workspaces properly filters conversation list
- UI matches Slack-style sidebar layout

## What We're NOT Doing

- Infinite scroll (initially using "Load More" button only)
- Real-time conversation updates via WebSocket
- Conversation search/filtering within the sidebar (keeping existing search panel)
- Persisting conversation list state across app restarts
- Optimizing the cache strategy (keeping simple in-memory cache)

## Implementation Approach

Use a phased approach to minimize risk:
1. First, add new API method while keeping old one working
2. Update data layer with pagination support
3. Restructure UI to sidebar layout
4. Wire up pagination in conversation list
5. Remove old endpoint usage and clean up

This allows testing each layer independently and makes rollback easier if needed.

---

## Phase 1: Add Recent Channels API Support

### Overview
Add support for the `/channels/recent` endpoint in the data layer while keeping the existing endpoint functional.

### Changes Required:

#### 1. Update Remote Data Source Interface
**File**: `lib/features/conversations/data/datasources/conversation_remote_datasource.dart`

**Changes**: Add new method for recent channels

```dart
abstract class ConversationRemoteDataSource {
  /// Fetches all conversations for a workspace from the API
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getConversations(String workspaceId);

  /// Fetches recent channels using cursor-based pagination
  /// [limit] - Number of channels to fetch
  /// [direction] - "older" or "newer"
  /// [date] - ISO8601 timestamp for pagination cursor
  /// [includeDeleted] - Whether to include deleted channels
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<List<ConversationDto>> getRecentChannels({
    required int limit,
    String direction = 'older',
    required String date,
    bool includeDeleted = false,
  });

  /// Fetches a single conversation by ID
  /// Throws [ServerException] on API errors
  /// Throws [NetworkException] on network errors
  Future<ConversationDto> getConversation(String conversationId);
}
```

#### 2. Implement Recent Channels API Call
**File**: `lib/features/conversations/data/datasources/conversation_remote_datasource_impl.dart`

**Changes**: Add implementation of `getRecentChannels`

```dart
@override
Future<List<ConversationDto>> getRecentChannels({
  required int limit,
  String direction = 'older',
  required String date,
  bool includeDeleted = false,
}) async {
  try {
    final response = await _httpService.post(
      '${OAuthConfig.apiBaseUrl}/channels/recent',
      body: jsonEncode({
        'limit': limit,
        'direction': direction,
        'date': date,
        'includeDeleted': includeDeleted,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // API might return {channels: [...]} or just [...]
      final List<dynamic> conversationsJson;
      if (data is List) {
        conversationsJson = data;
      } else if (data is Map<String, dynamic>) {
        conversationsJson = data['channels'] as List<dynamic>? ??
                          data['data'] as List<dynamic>? ?? [];
      } else {
        throw const FormatException('Unexpected response format');
      }

      final conversations = conversationsJson
          .map((json) => ConversationDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return conversations;
    } else {
      _logger.e('Failed to fetch recent channels: ${response.statusCode}');
      throw ServerException(
        statusCode: response.statusCode,
        message: 'Failed to fetch recent channels',
      );
    }
  } on ServerException {
    rethrow;
  } on Exception catch (e, stack) {
    _logger.e('Network error fetching recent channels', error: e, stackTrace: stack);
    throw NetworkException(message: 'Failed to fetch recent channels: $e');
  }
}
```

#### 3. Update Repository Interface
**File**: `lib/features/conversations/domain/repositories/conversation_repository.dart`

**Changes**: Add method for recent channels with workspace filtering

```dart
/// Repository interface for conversation operations
abstract class ConversationRepository {
  /// Fetches all conversations for a workspace
  Future<Result<List<Conversation>>> getConversations(String workspaceId);

  /// Fetches recent channels with pagination and workspace filtering
  /// [workspaceId] - Filter conversations by this workspace (client-side)
  /// [limit] - Number of conversations to fetch
  /// [beforeDate] - ISO8601 timestamp to fetch conversations before (for pagination)
  Future<Result<List<Conversation>>> getRecentConversations({
    required String workspaceId,
    required int limit,
    String? beforeDate,
  });

  /// Fetches a single conversation by ID
  Future<Result<Conversation>> getConversation(String conversationId);
}
```

#### 4. Implement Repository Method with Client-Side Filtering
**File**: `lib/features/conversations/data/repositories/conversation_repository_impl.dart`

**Changes**: Add implementation with workspace filtering

```dart
// Add new cache for recent conversations (not workspace-specific)
final List<Conversation> _recentConversationsCache = [];
String? _lastFetchedDate;

@override
Future<Result<List<Conversation>>> getRecentConversations({
  required String workspaceId,
  required int limit,
  String? beforeDate,
}) async {
  try {
    // Use provided beforeDate or current timestamp for first load
    final dateToUse = beforeDate ?? DateTime.now().toIso8601String();

    final conversationDtos = await _remoteDataSource.getRecentChannels(
      limit: limit,
      direction: 'older',
      date: dateToUse,
      includeDeleted: false,
    );

    // Convert DTOs to domain entities
    final conversations = conversationDtos.map((dto) => dto.toDomain()).toList();

    // If this is a fresh load (no beforeDate), replace cache
    if (beforeDate == null) {
      _recentConversationsCache.clear();
      _recentConversationsCache.addAll(conversations);
      _lastFetchedDate = dateToUse;
    } else {
      // Pagination: append to cache
      _recentConversationsCache.addAll(conversations);
      _lastFetchedDate = dateToUse;
    }

    // Filter by workspace on client-side
    final filteredConversations = conversations
        .where((conv) => conv.workspaceGuid == workspaceId)
        .toList();

    return success(filteredConversations);
  } on ServerException catch (e) {
    _logger.e('Server error fetching recent conversations', error: e);
    return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
  } on NetworkException catch (e) {
    _logger.e('Network error fetching recent conversations', error: e);
    return failure(NetworkFailure(details: e.message));
  } on Exception catch (e, stack) {
    _logger.e('Unknown error fetching recent conversations', error: e, stackTrace: stack);
    return failure(UnknownFailure(details: e.toString()));
  }
}

/// Clears the recent conversations cache
void clearRecentConversationsCache() {
  _recentConversationsCache.clear();
  _lastFetchedDate = null;
}
```

### Success Criteria:

#### Automated Verification:
- [x] Build succeeds: `flutter pub run build_runner build`
- [x] No analyzer errors: `flutter analyze`
- [ ] Unit tests pass (if any exist for data layer)

#### Manual Verification:
- [ ] Can call `getRecentConversations` without errors
- [ ] Response properly filters by workspace
- [ ] Pagination works by passing `beforeDate` from last result
- [ ] Cache properly stores conversations across calls

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Update BLoC with Pagination Support

### Overview
Extend the ConversationBloc to support loading recent conversations with pagination and workspace filtering.

### Changes Required:

#### 1. Add New Events
**File**: `lib/features/conversations/presentation/bloc/conversation_event.dart`

**Changes**: Add events for recent conversation loading

```dart
// Add these new events to the existing file

/// Event to load recent conversations with pagination
class LoadRecentConversations extends ConversationEvent {
  const LoadRecentConversations({
    required this.workspaceId,
    this.beforeDate,
  });

  final String workspaceId;
  final String? beforeDate; // For pagination

  @override
  List<Object?> get props => [workspaceId, beforeDate];
}

/// Event to load more recent conversations (pagination)
class LoadMoreRecentConversations extends ConversationEvent {
  const LoadMoreRecentConversations();

  @override
  List<Object?> get props => [];
}
```

#### 2. Update State to Track Pagination
**File**: `lib/features/conversations/presentation/bloc/conversation_state.dart`

**Changes**: Add pagination tracking to `ConversationLoaded` state

```dart
/// State when conversations are loaded successfully
class ConversationLoaded extends ConversationState {
  const ConversationLoaded({
    required this.conversations,
    required this.selectedConversationIds,
    required this.conversationColorMap,
    this.isSearchOpen = false,
    this.searchQuery = '',
    this.searchMode = ConversationSearchMode.name,
    this.hasMoreConversations = false,  // NEW: Track if more conversations exist
    this.isLoadingMore = false,         // NEW: Track pagination loading state
    this.lastFetchedDate,                // NEW: Track last pagination cursor
  });

  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;
  final bool isSearchOpen;
  final String searchQuery;
  final ConversationSearchMode searchMode;
  final bool hasMoreConversations;     // NEW
  final bool isLoadingMore;            // NEW
  final String? lastFetchedDate;       // NEW

  @override
  List<Object?> get props => [
    conversations,
    selectedConversationIds,
    conversationColorMap,
    isSearchOpen,
    searchQuery,
    searchMode,
    hasMoreConversations,    // NEW
    isLoadingMore,           // NEW
    lastFetchedDate,         // NEW
  ];

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    Map<String, int>? conversationColorMap,
    bool? isSearchOpen,
    String? searchQuery,
    ConversationSearchMode? searchMode,
    bool? hasMoreConversations,     // NEW
    bool? isLoadingMore,            // NEW
    String? lastFetchedDate,        // NEW
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      searchQuery: searchQuery ?? this.searchQuery,
      searchMode: searchMode ?? this.searchMode,
      hasMoreConversations: hasMoreConversations ?? this.hasMoreConversations,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastFetchedDate: lastFetchedDate ?? this.lastFetchedDate,
    );
  }
}
```

#### 3. Add Event Handlers in BLoC
**File**: `lib/features/conversations/presentation/bloc/conversation_bloc.dart`

**Changes**: Register and implement new event handlers

```dart
// In the constructor, add these handlers:
@injectable
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc(
    this._conversationRepository,
    this._logger,
  ) : super(const ConversationInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadRecentConversations>(_onLoadRecentConversations);        // NEW
    on<LoadMoreRecentConversations>(_onLoadMoreRecentConversations); // NEW
    on<ToggleConversation>(_onToggleConversation);
    on<SelectMultipleConversations>(_onSelectMultipleConversations);
    on<ClearConversationSelection>(_onClearConversationSelection);
    on<WorkspaceSelectedEvent>(_onWorkspaceSelected);
    on<OpenConversationSearch>(_onOpenConversationSearch);
    on<CloseConversationSearch>(_onCloseConversationSearch);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<ToggleSearchMode>(_onToggleSearchMode);
    on<SelectConversationFromSearch>(_onSelectConversationFromSearch);
  }

  final ConversationRepository _conversationRepository;
  final Logger _logger;

  // Configuration
  static const int _conversationsPerPage = 20;

  // ... existing helper methods ...

  /// Update WorkspaceSelectedEvent to use new endpoint
  Future<void> _onWorkspaceSelected(
    WorkspaceSelectedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    // Use new recent conversations endpoint instead
    add(LoadRecentConversations(workspaceId: event.workspaceGuid));
  }

  /// Handler for loading recent conversations (initial load)
  Future<void> _onLoadRecentConversations(
    LoadRecentConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());

    final result = await _conversationRepository.getRecentConversations(
      workspaceId: event.workspaceId,
      limit: _conversationsPerPage,
      beforeDate: event.beforeDate,
    );

    result.fold(
      onSuccess: (conversations) {
        if (conversations.isEmpty) {
          emit(const ConversationLoaded(
            conversations: [],
            selectedConversationIds: {},
            conversationColorMap: {},
            hasMoreConversations: false,
          ));
          return;
        }

        final sortedConversations = _sortConversationsByRecency(conversations);

        final colorMap = <String, int>{};
        for (var i = 0; i < sortedConversations.length; i++) {
          colorMap[sortedConversations[i].channelGuid!] = i % 10;
        }

        final selected = sortedConversations.first;

        // Determine if there are more conversations
        // If we received exactly the limit, assume there might be more
        final hasMore = conversations.length == _conversationsPerPage;

        // Get the last conversation's timestamp for pagination
        String? lastDate;
        if (hasMore && sortedConversations.isNotEmpty) {
          final lastConv = sortedConversations.last;
          final timestamp = lastConv.lastUpdatedTs ?? lastConv.createdTs;
          if (timestamp != null) {
            lastDate = DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
          }
        }

        emit(ConversationLoaded(
          conversations: sortedConversations,
          selectedConversationIds: {selected.channelGuid!},
          conversationColorMap: colorMap,
          hasMoreConversations: hasMore,
          lastFetchedDate: lastDate,
        ));
      },
      onFailure: (failure) {
        emit(ConversationError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  /// Handler for loading more conversations (pagination)
  Future<void> _onLoadMoreRecentConversations(
    LoadMoreRecentConversations event,
    Emitter<ConversationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationLoaded) {
      _logger.w('Cannot load more: current state is not ConversationLoaded');
      return;
    }

    if (currentState.isLoadingMore) {
      _logger.d('Already loading more conversations, ignoring request');
      return;
    }

    if (!currentState.hasMoreConversations) {
      _logger.d('No more conversations to load');
      return;
    }

    // Mark as loading more
    emit(currentState.copyWith(isLoadingMore: true));

    // Extract workspace ID from existing conversations
    final workspaceId = currentState.conversations.first.workspaceGuid;
    if (workspaceId == null) {
      _logger.e('Cannot load more: workspace ID not found in current conversations');
      emit(currentState.copyWith(isLoadingMore: false));
      return;
    }

    final result = await _conversationRepository.getRecentConversations(
      workspaceId: workspaceId,
      limit: _conversationsPerPage,
      beforeDate: currentState.lastFetchedDate,
    );

    result.fold(
      onSuccess: (newConversations) {
        if (newConversations.isEmpty) {
          emit(currentState.copyWith(
            hasMoreConversations: false,
            isLoadingMore: false,
          ));
          return;
        }

        // Merge with existing conversations
        final allConversations = [
          ...currentState.conversations,
          ...newConversations,
        ];

        final sortedConversations = _sortConversationsByRecency(allConversations);

        // Update color map for new conversations
        final colorMap = Map<String, int>.from(currentState.conversationColorMap);
        for (var i = 0; i < sortedConversations.length; i++) {
          colorMap[sortedConversations[i].channelGuid!] = i % 10;
        }

        // Determine if there are more
        final hasMore = newConversations.length == _conversationsPerPage;

        // Get the last conversation's timestamp
        String? lastDate;
        if (hasMore && sortedConversations.isNotEmpty) {
          final lastConv = sortedConversations.last;
          final timestamp = lastConv.lastUpdatedTs ?? lastConv.createdTs;
          if (timestamp != null) {
            lastDate = DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
          }
        }

        emit(currentState.copyWith(
          conversations: sortedConversations,
          conversationColorMap: colorMap,
          hasMoreConversations: hasMore,
          isLoadingMore: false,
          lastFetchedDate: lastDate,
        ));
      },
      onFailure: (failure) {
        // On error, just stop loading more but keep current state
        _logger.e('Failed to load more conversations: ${FailureMapper.mapToMessage(failure.failure)}');
        emit(currentState.copyWith(isLoadingMore: false));
      },
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Build succeeds: `flutter pub run build_runner build`
- [x] No analyzer errors: `flutter analyze`
- [x] App builds successfully: `flutter build web`

#### Manual Verification:
- [ ] Initial load fetches first 20 conversations filtered by workspace
- [ ] LoadMoreRecentConversations event appends next batch
- [ ] hasMoreConversations correctly indicates when to show "Load More"
- [ ] isLoadingMore prevents duplicate requests
- [ ] Switching workspaces clears and reloads conversation list

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Create Sidebar Layout Structure

### Overview
Restructure the dashboard to have a Slack-like layout with a left sidebar containing workspace selector and conversation list.

### Changes Required:

#### 1. Create Sidebar Widget
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/dashboard_sidebar.dart` (NEW)

**Changes**: Create new sidebar widget

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_workspace_section.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_conversation_list.dart';
import 'package:flutter/material.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  static const double sidebarWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sidebarWidth,
      child: AppContainer(
        backgroundColor: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: const Border(
          right: BorderSide(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            // Workspace selector at top
            const SidebarWorkspaceSection(),

            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),

            // Conversation list fills remaining space
            const Expanded(
              child: SidebarConversationList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2. Create Sidebar Workspace Section
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_workspace_section.dart` (NEW)

**Changes**: Move workspace selector to sidebar

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/widgets/workspace_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarWorkspaceSection extends StatelessWidget {
  const SidebarWorkspaceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Workspace',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<WorkspaceBloc, WorkspaceState>(
            builder: (context, workspaceState) {
              return BlocBuilder<UserProfileCubit, UserProfileState>(
                builder: (context, userProfileState) {
                  return switch (workspaceState) {
                    WorkspaceInitial() => const SizedBox.shrink(),
                    WorkspaceLoading() => const SizedBox(
                      height: 40,
                      child: Center(child: AppProgressIndicator()),
                    ),
                    WorkspaceLoaded() => _buildWorkspaceSelector(
                      workspaceState,
                      userProfileState,
                    ),
                    WorkspaceError() => const SizedBox.shrink(),
                  };
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSelector(
    WorkspaceLoaded loadedState,
    UserProfileState userProfileState,
  ) {
    final currentUserId = userProfileState is UserProfileLoaded
        ? userProfileState.user.id
        : loadedState.currentUserId ?? '';

    return WorkspaceSelector(
      currentUserId: currentUserId,
      workspaceState: loadedState,
    );
  }
}
```

#### 3. Create Sidebar Conversation List
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_conversation_list.dart` (NEW)

**Changes**: Create scrollable conversation list with pagination

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_conversation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarConversationList extends StatelessWidget {
  const SidebarConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, state) {
        return switch (state) {
          ConversationInitial() => _buildInitialState(),
          ConversationLoading() => _buildLoadingState(),
          ConversationLoaded() => _buildLoadedState(context, state),
          ConversationError() => _buildErrorState(state),
        };
      },
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Text(
        'Select a workspace',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: AppProgressIndicator(),
    );
  }

  Widget _buildErrorState(ConversationError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          state.message,
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, ConversationLoaded state) {
    if (state.conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No conversations in this workspace',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Conversations header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Conversations',
                style: AppTextStyle.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${state.conversations.length}',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Scrollable list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              final isSelected = state.selectedConversationIds.contains(
                conversation.channelGuid,
              );
              final colorIndex = state.conversationColorMap[conversation.channelGuid] ?? 0;

              return SidebarConversationItem(
                conversation: conversation,
                isSelected: isSelected,
                colorIndex: colorIndex,
                onTap: () {
                  context.read<ConversationBloc>().add(
                    ToggleConversation(conversation.channelGuid!),
                  );
                },
              );
            },
          ),
        ),

        // Load More button
        if (state.hasMoreConversations)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () {
                        context.read<ConversationBloc>().add(
                          const LoadMoreRecentConversations(),
                        );
                      },
                text: state.isLoadingMore ? 'Loading...' : 'Load More',
                type: AppButtonType.secondary,
              ),
            ),
          ),
      ],
    );
  }
}
```

#### 4. Create Conversation Item Widget
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_conversation_item.dart` (NEW)

**Changes**: Create individual conversation item

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';

class SidebarConversationItem extends StatelessWidget {
  const SidebarConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.colorIndex,
    required this.onTap,
    super.key,
  });

  final Conversation conversation;
  final bool isSelected;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: isSelected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
        onTap: onTap,
        child: Row(
          children: [
            // Selection indicator
            Icon(
              isSelected ? AppIcons.check : AppIcons.circle,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),

            // Conversation name
            Expanded(
              child: Text(
                conversation.channelName ?? 'Unknown',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Unread count badge (if any)
            if (conversation.unreadCnt != null && conversation.unreadCnt! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCnt}',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### 5. Update Dashboard Content to Include Sidebar
**File**: `lib/features/messages/presentation_messages_dashboard/screens/content_dashboard.dart`

**Changes**: Modify to use Row layout with sidebar

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/audio_mini_player_positioned.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/download_progress_indicator.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/message_composition_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_action_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_content_container.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/pagination_controls_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_search_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/dashboard_sidebar.dart';
import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    super.key,
  });

  final bool Function(BuildContext context) isAnyBlocLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left sidebar
        const DashboardSidebar(),

        // Main content area
        Expanded(
          child: AppContainer(
            backgroundColor: AppColors.surface,
            child: Stack(
              children: [
                MessagesContentContainer(isAnyBlocLoading: isAnyBlocLoading),
                const DownloadProgressIndicator(),
                const ConversationSearchPanelWrapper(),
                const MessagesActionPanelWrapper(),
                const PaginationControlsWrapper(),
                const AudioMiniPlayerPositioned(),
                const MessageCompositionPanelWrapper(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

#### 6. Simplify App Bar
**File**: `lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart`

**Changes**: Remove workspace and conversation selector sections

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_search_button.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/dashboard_title.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/preview_button.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/selected_conversations_section.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/send_message_button.dart';
import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.zero,
      border: Border(
        bottom: BorderSide(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          DashboardTitle(),
          SizedBox(width: 16),
          // Workspace and Conversation selector REMOVED - now in sidebar
          SelectedConversationsSection(),
          ConversationSearchButton(),
          PreviewButton(),
          SendMessageButton(),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] Build succeeds: `flutter build web`
- [x] No analyzer errors: `flutter analyze`
- [ ] No formatting issues: `dart format lib/`

#### Manual Verification:
- [ ] Sidebar appears on left side of dashboard
- [ ] Workspace selector appears at top of sidebar
- [ ] Conversation list displays below workspace selector
- [ ] Conversation items are clickable and toggle selection
- [ ] "Load More" button appears when hasMoreConversations is true
- [ ] App bar no longer shows workspace/conversation selectors
- [ ] Layout resembles Slack's sidebar structure

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Wire Up Complete Flow and Clean Up

### Overview
Connect all the pieces together and remove old code that's no longer needed.

### Changes Required:

#### 1. Update Dashboard Screen Communication
**File**: `lib/features/messages/presentation_messages_dashboard/screens/dashboard_screen.dart`

**Changes**: Update bloc communication to use new events (no changes needed, WorkspaceSelectedEvent already triggers the right flow)

Note: The existing `_setupBlocCommunication` already listens to WorkspaceBloc and triggers ConversationBloc events. Since we updated `_onWorkspaceSelected` in Phase 2 to dispatch `LoadRecentConversations`, the flow already works correctly.

#### 2. Update Conversation Search Panel (if needed)
**File**: `lib/features/messages/presentation_messages_dashboard/components/conversation_search_panel.dart`

**Changes**: Verify search panel still works with new conversation loading

Read the file and ensure it doesn't break with the new loading mechanism. The search functionality should continue to work on the loaded conversations list.

#### 3. Remove Old Endpoint Usage (Optional - Keep as Fallback)
**File**: `lib/features/conversations/presentation/bloc/conversation_bloc.dart`

**Changes**: Keep the old `_onLoadConversations` handler but add a deprecation comment

```dart
/// DEPRECATED: Use LoadRecentConversations instead
/// This handler remains for backward compatibility but should not be used
Future<void> _onLoadConversations(
  LoadConversations event,
  Emitter<ConversationState> emit,
) async {
  // Keep existing implementation as fallback
  // ...existing code...
}
```

#### 4. Add Conversation List Export/Index File
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/dashboard_sidebar.dart`

**Changes**: Already created in Phase 3, verify all imports work

#### 5. Test Complete User Flow
Manual testing checklist:
1. Launch app and authenticate
2. Select a workspace from sidebar
3. Verify conversations load and filter by workspace
4. Click conversations to select/deselect
5. Click "Load More" to paginate
6. Switch to different workspace
7. Verify conversation list updates
8. Send a message to selected conversations
9. Verify app bar shows selected count correctly

### Success Criteria:

#### Automated Verification:
- [x] Full build succeeds: `flutter build web`
- [x] No analyzer warnings: `flutter analyze`
- [ ] Code formatting passes: `dart format lib/`
- [ ] No unused imports: Check with analyzer

#### Manual Verification:
- [ ] Complete user flow works end-to-end
- [ ] Workspace switching properly filters conversations
- [ ] Pagination loads additional conversations
- [ ] "Load More" button disappears when no more conversations
- [ ] Multi-select conversations works correctly
- [ ] Message sending works with selected conversations
- [ ] Search panel still functions correctly
- [ ] No console errors during normal usage
- [ ] Performance is acceptable with 50+ conversations

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Testing Strategy

### Unit Tests:
- Test `getRecentChannels` data source method with various responses
- Test `getRecentConversations` repository method with client-side filtering
- Test BLoC event handlers for pagination logic
- Test `hasMoreConversations` calculation logic

### Integration Tests:
- Test complete workspace switch flow
- Test pagination across multiple pages
- Test filtering accuracy (conversations match selected workspace)

### Manual Testing Steps:
1. **Initial Load:**
   - Open app, select workspace
   - Verify first 20 conversations load
   - Verify correct workspace filtering

2. **Pagination:**
   - Click "Load More" button
   - Verify next batch appends to list
   - Verify no duplicates
   - Verify button disappears when no more conversations

3. **Workspace Switching:**
   - Switch to different workspace
   - Verify conversation list reloads
   - Verify correct filtering for new workspace

4. **Edge Cases:**
   - Workspace with 0 conversations
   - Workspace with exactly 20 conversations (no more to load)
   - Rapid workspace switching
   - Network errors during pagination

5. **UI/UX:**
   - Sidebar width is appropriate
   - Conversation items are readable
   - Loading states are clear
   - Selected state is visually distinct

## Performance Considerations

- **Initial Load**: Limit to 20 conversations to keep first load fast
- **Client-Side Filtering**: Efficient since we're filtering a small batch (20 items)
- **Cache Strategy**: Keep simple in-memory cache, clear on workspace switch
- **Pagination**: Load on demand to avoid loading hundreds of conversations upfront
- **Future Optimization**: Could implement virtual scrolling for very long lists (not in this phase)

## Migration Notes

**Gradual Rollout:**
- Phase 1-2 can be deployed without UI changes
- Phase 3 changes UI significantly - consider feature flag if needed
- Old endpoint can remain as fallback if `/channels/recent` has issues

**Rollback Plan:**
- Keep old `LoadConversations` event handler
- Can revert app bar by removing sidebar and restoring old components
- Repository cache separation allows independent operation

**Data Consistency:**
- Recent channels endpoint returns same DTO structure
- No database migrations needed
- No breaking changes to existing message loading

## References

- Message pagination pattern: `lib/features/messages/data/datasources/message_remote_datasource.dart:15-20`
- Existing pagination UI: `lib/features/messages/presentation_messages_dashboard/widgets/dashboard_content/pagination_controls_wrapper.dart`
- Current conversation loading: `lib/features/conversations/presentation/bloc/conversation_bloc.dart:52-91`
- App bar structure: `lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart`
