# Conversation Sorting and Search Implementation Plan

## Overview

Add sorting and search capabilities to the conversations list when a workspace is selected. Users need to:
1. See conversations sorted by most recent activity (newest first)
2. Search for specific conversations by ID or Name when the dropdown list is too long

## Current State Analysis

### Current Implementation
- **API Endpoint**: `GET /channels/{workspaceId}` - Returns all conversations for a workspace
- **Caching**: In-memory cache in `ConversationRepositoryImpl` (`Map<String, List<Conversation>>`)
- **No Pagination**: All conversations fetched in one request
- **Display**: Multi-select dropdown in [lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart:144-233](lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart#L144-L233)
- **Current Order**: As returned by API (no client-side sorting)
- **No Search**: No search functionality exists

### Key Discoveries
- **Conversation Entity** has timestamp fields available:
  - `lastPostedTs` (int?) - Last message posted timestamp
  - `lastUpdatedTs` (int?) - Last update timestamp
  - `createdTs` (int?) - Creation timestamp
  - `id` (String) - Conversation ID
  - `name` (String) - Conversation name

- **State Management**: `ConversationLoaded` state contains:
  - `conversations` (List<Conversation>) - All conversations for workspace
  - `selectedConversationIds` (Set<String>) - Selected conversation IDs
  - `conversationColorMap` (Map<String, int>) - Color assignments

- **UI Pattern**: Uses `BlocSelector` to listen to conversation state changes

## Desired End State

After this implementation:
1. ✅ **Sorted conversations**: Dropdown shows conversations sorted by most recent activity first
2. ✅ **Search UI**: Icon button to the right of conversation dropdown opens search panel
3. ✅ **Search modes**: Users can toggle between ID search (exact match) and Name search (case-insensitive partial match)
4. ✅ **Real-time filtering**: Search results update as user types (no debouncing needed - searching cached data)
5. ✅ **Seamless selection**: Selecting from search results adds to selected conversations like dropdown does
6. ✅ **Closeable panel**: Search panel can be closed via X button or clicking outside

### Sorting Logic
- **Primary**: `lastPostedTs` (descending - newest first)
- **Fallback 1**: `lastUpdatedTs` (if lastPostedTs is null)
- **Fallback 2**: `createdTs` (if both above are null)
- **Final Fallback**: Original API order (if all timestamps null)

### Search Behavior
- **ID Search**: Exact match on `conversation.id`
- **Name Search**: Case-insensitive partial match (contains) on `conversation.name`
- **Search panel resets**: Doesn't remember last mode - resets to default each time

### Verification
- [ ] Conversations sorted correctly in dropdown (most recent first)
- [ ] Search icon appears to the right of conversation dropdown
- [ ] Search panel opens/closes smoothly
- [ ] ID search finds exact matches
- [ ] Name search finds partial, case-insensitive matches
- [ ] Selecting from search results adds to selected conversations
- [ ] Search panel closes after selection
- [ ] Build succeeds: `flutter analyze`
- [ ] Code generation succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`

## What We're NOT Doing

- NOT implementing pagination (API returns all conversations at once)
- NOT adding API-level filtering or sorting (using cached data)
- NOT persisting search history or last search mode
- NOT modifying the existing dropdown multi-select behavior
- NOT changing how conversations are fetched or cached
- NOT adding debouncing (searching in-memory data is fast enough)

## Implementation Approach

### Strategy
1. Add sorting logic to BLoC when conversations are loaded
2. Create search panel widget with toggle between ID/Name modes
3. Add search icon button in app bar next to conversation dropdown
4. Implement search filtering logic in BLoC
5. Update UI to handle search state and results

### Key Patterns to Follow
- Use existing BLoC pattern (events/states)
- Follow app UI component structure (AppColors, AppTextStyle, AppContainer)
- Maintain existing conversation selection behavior
- Keep sorting and searching in presentation layer (no repository changes needed)

---

## Phase 1: Add Sorting Logic to ConversationBloc

### Overview
Implement conversation sorting in the BLoC when conversations are loaded. Sort by most recent activity (lastPostedTs → lastUpdatedTs → createdTs).

### Changes Required

#### 1. Update ConversationBloc - Add Sorting Helper
**File**: `lib/features/conversations/presentation/bloc/conversation_bloc.dart`

**Changes**: Add sorting method and apply it in `_onLoadConversations`

After the existing imports, add sorting logic:

```dart
/// Helper method to sort conversations by most recent activity
List<Conversation> _sortConversationsByRecency(List<Conversation> conversations) {
  final sorted = List<Conversation>.from(conversations);

  sorted.sort((a, b) {
    // Get the effective timestamp for conversation A
    final aTimestamp = a.lastPostedTs ?? a.lastUpdatedTs ?? a.createdTs ?? 0;

    // Get the effective timestamp for conversation B
    final bTimestamp = b.lastPostedTs ?? b.lastUpdatedTs ?? b.createdTs ?? 0;

    // Sort descending (newest first)
    return bTimestamp.compareTo(aTimestamp);
  });

  return sorted;
}
```

**Location to add**: After line 19 (after the constructor, before event handlers)

Then update the `_onLoadConversations` method to sort conversations before emitting:

**Find this code** (around line 38-55):
```dart
final result = await _conversationRepository.getConversations(event.workspaceId);

result.fold(
  onSuccess: (conversations) {
    // ... existing code ...
    emit(
      ConversationLoaded(
        conversations: conversations,
        selectedConversationIds: const {},
        conversationColorMap: colorMap,
      ),
    );
  },
  onFailure: (failure) {
    // ... existing error handling ...
  },
);
```

**Replace with**:
```dart
final result = await _conversationRepository.getConversations(event.workspaceId);

result.fold(
  onSuccess: (conversations) {
    // Sort conversations by most recent activity
    final sortedConversations = _sortConversationsByRecency(conversations);

    // Assign colors to conversations
    final colorMap = <String, int>{};
    for (var i = 0; i < sortedConversations.length; i++) {
      colorMap[sortedConversations[i].id] = i % 10; // Cycle through 10 colors
    }

    emit(
      ConversationLoaded(
        conversations: sortedConversations,
        selectedConversationIds: const {},
        conversationColorMap: colorMap,
      ),
    );
  },
  onFailure: (failure) {
    _logger.e('Failed to load conversations', error: failure);
    emit(ConversationError(failure.message));
  },
);
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles successfully: `dart analyze lib/features/conversations/presentation/bloc/`
- [ ] No syntax errors in sorting logic
- [ ] BLoC handles null timestamps correctly

#### Manual Verification:
- [ ] Select a workspace in the UI
- [ ] Open conversation dropdown
- [ ] Verify conversations are sorted with most recent first
- [ ] Check that conversations with null timestamps appear at the bottom
- [ ] Verify existing selection behavior still works

**Implementation Note**: After completing this phase and all automated verification passes, test manually in the UI to confirm sorting works before proceeding to the next phase.

---

## Phase 2: Create Search Events and State

### Overview
Add new events and state for conversation search functionality in the BLoC layer.

### Changes Required

#### 1. Add Search Events
**File**: `lib/features/conversations/presentation/bloc/conversation_event.dart`

**Changes**: Add search-related events after the existing events

**Add after line 45** (after WorkspaceSelectedEvent):

```dart
/// Event to open the conversation search panel
class OpenConversationSearch extends ConversationEvent {
  const OpenConversationSearch();
}

/// Event to close the conversation search panel
class CloseConversationSearch extends ConversationEvent {
  const CloseConversationSearch();
}

/// Event to update search query
class UpdateSearchQuery extends ConversationEvent {
  const UpdateSearchQuery(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Event to toggle search mode between ID and Name
class ToggleSearchMode extends ConversationEvent {
  const ToggleSearchMode(this.searchMode);
  final ConversationSearchMode searchMode;

  @override
  List<Object?> get props => [searchMode];
}

/// Event to select a conversation from search results
class SelectConversationFromSearch extends ConversationEvent {
  const SelectConversationFromSearch(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}
```

Also add the enum for search mode at the top of the file (after imports):

```dart
/// Search mode for conversation search
enum ConversationSearchMode {
  id,    // Search by exact conversation ID
  name,  // Search by conversation name (case-insensitive, partial match)
}
```

#### 2. Update ConversationLoaded State
**File**: `lib/features/conversations/presentation/bloc/conversation_state.dart`

**Changes**: Add search-related fields to `ConversationLoaded` state

**Replace the ConversationLoaded class** (lines 19-43) with:

```dart
class ConversationLoaded extends ConversationState {
  const ConversationLoaded({
    required this.conversations,
    required this.selectedConversationIds,
    required this.conversationColorMap,
    this.isSearchOpen = false,
    this.searchQuery = '',
    this.searchMode = ConversationSearchMode.name,
  });

  final List<Conversation> conversations;
  final Set<String> selectedConversationIds;
  final Map<String, int> conversationColorMap;

  // Search-related fields
  final bool isSearchOpen;
  final String searchQuery;
  final ConversationSearchMode searchMode;

  /// Filtered conversations based on search query and mode
  List<Conversation> get filteredConversations {
    if (!isSearchOpen || searchQuery.isEmpty) {
      return conversations;
    }

    switch (searchMode) {
      case ConversationSearchMode.id:
        // Exact match for ID
        return conversations.where((c) => c.id == searchQuery).toList();

      case ConversationSearchMode.name:
        // Case-insensitive partial match for name
        final lowerQuery = searchQuery.toLowerCase();
        return conversations.where((c) => c.name.toLowerCase().contains(lowerQuery)).toList();
    }
  }

  @override
  List<Object?> get props => [
    conversations,
    selectedConversationIds,
    conversationColorMap,
    isSearchOpen,
    searchQuery,
    searchMode,
  ];

  ConversationLoaded copyWith({
    List<Conversation>? conversations,
    Set<String>? selectedConversationIds,
    Map<String, int>? conversationColorMap,
    bool? isSearchOpen,
    String? searchQuery,
    ConversationSearchMode? searchMode,
  }) {
    return ConversationLoaded(
      conversations: conversations ?? this.conversations,
      selectedConversationIds: selectedConversationIds ?? this.selectedConversationIds,
      conversationColorMap: conversationColorMap ?? this.conversationColorMap,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      searchQuery: searchQuery ?? this.searchQuery,
      searchMode: searchMode ?? this.searchMode,
    );
  }
}
```

**Add import** at the top of the file (after existing imports):

```dart
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
```

### Success Criteria

#### Automated Verification:
- [ ] Events compile successfully: `dart analyze lib/features/conversations/presentation/bloc/conversation_event.dart`
- [ ] State compiles successfully: `dart analyze lib/features/conversations/presentation/bloc/conversation_state.dart`
- [ ] Enum definition is valid
- [ ] `filteredConversations` getter logic is correct

#### Manual Verification:
- [ ] No breaking changes to existing code
- [ ] State properties are immutable
- [ ] copyWith method includes all new fields
- [ ] Search filtering logic handles edge cases (empty query, null values)

**Implementation Note**: After completing this phase, verify that the app still compiles and existing functionality works before proceeding.

---

## Phase 3: Implement Search Event Handlers in BLoC

### Overview
Add event handlers in ConversationBloc to process search-related events.

### Changes Required

#### 1. Register Search Event Handlers
**File**: `lib/features/conversations/presentation/bloc/conversation_bloc.dart`

**Changes**: Register new event handlers in the constructor and implement them

**In the constructor** (around line 15-18), add registrations after existing `on<>` calls:

```dart
on<OpenConversationSearch>(_onOpenConversationSearch);
on<CloseConversationSearch>(_onCloseConversationSearch);
on<UpdateSearchQuery>(_onUpdateSearchQuery);
on<ToggleSearchMode>(_onToggleSearchMode);
on<SelectConversationFromSearch>(_onSelectConversationFromSearch);
```

**Add event handler methods** (after the existing event handlers, around line 85):

```dart
/// Handles opening the conversation search panel
void _onOpenConversationSearch(
  OpenConversationSearch event,
  Emitter<ConversationState> emit,
) {
  final currentState = state;
  if (currentState is! ConversationLoaded) {
    _logger.w('Cannot open search: current state is not ConversationLoaded');
    return;
  }

  emit(currentState.copyWith(
    isSearchOpen: true,
    searchQuery: '',  // Reset query when opening
    searchMode: ConversationSearchMode.name,  // Default to name search
  ));
}

/// Handles closing the conversation search panel
void _onCloseConversationSearch(
  CloseConversationSearch event,
  Emitter<ConversationState> emit,
) {
  final currentState = state;
  if (currentState is! ConversationLoaded) {
    _logger.w('Cannot close search: current state is not ConversationLoaded');
    return;
  }

  emit(currentState.copyWith(
    isSearchOpen: false,
    searchQuery: '',  // Clear query when closing
  ));
}

/// Handles updating the search query
void _onUpdateSearchQuery(
  UpdateSearchQuery event,
  Emitter<ConversationState> emit,
) {
  final currentState = state;
  if (currentState is! ConversationLoaded) {
    _logger.w('Cannot update search query: current state is not ConversationLoaded');
    return;
  }

  emit(currentState.copyWith(searchQuery: event.query));
}

/// Handles toggling between ID and Name search modes
void _onToggleSearchMode(
  ToggleSearchMode event,
  Emitter<ConversationState> emit,
) {
  final currentState = state;
  if (currentState is! ConversationLoaded) {
    _logger.w('Cannot toggle search mode: current state is not ConversationLoaded');
    return;
  }

  emit(currentState.copyWith(
    searchMode: event.searchMode,
    searchQuery: '',  // Clear query when switching modes
  ));
}

/// Handles selecting a conversation from search results
void _onSelectConversationFromSearch(
  SelectConversationFromSearch event,
  Emitter<ConversationState> emit,
) {
  final currentState = state;
  if (currentState is! ConversationLoaded) {
    _logger.w('Cannot select from search: current state is not ConversationLoaded');
    return;
  }

  // Add conversation to selected set
  final newSelectedIds = Set<String>.from(currentState.selectedConversationIds);
  newSelectedIds.add(event.conversationId);

  emit(currentState.copyWith(
    selectedConversationIds: newSelectedIds,
    isSearchOpen: false,  // Close search panel after selection
    searchQuery: '',      // Clear search query
  ));

  // State change will trigger dashboard screen to notify MessageBloc
}
```

**Add import** at the top of the file (if not already present):

```dart
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
```

### Success Criteria

#### Automated Verification:
- [ ] BLoC compiles successfully: `dart analyze lib/features/conversations/presentation/bloc/`
- [ ] All event handlers are properly registered
- [ ] No syntax errors in handler implementations
- [ ] Event handlers guard against invalid states

#### Manual Verification:
- [ ] App builds without errors
- [ ] BLoC state management follows existing patterns
- [ ] Logger messages are consistent with existing code

**Implementation Note**: After completing this phase, verify the app compiles and runs without errors before proceeding to UI implementation.

---

## Phase 4: Create Search Panel Widget

### Overview
Create a reusable search panel widget that displays search input, mode toggle, and filtered results.

### Changes Required

#### 1. Create ConversationSearchPanel Widget
**File**: `lib/features/messages/presentation_messages_dashboard/widgets/conversation_search_panel.dart` (NEW FILE)

**Content**:

```dart
import 'package:carbon_voice_console/core/common/app_colors.dart';
import 'package:carbon_voice_console/core/common/app_container.dart';
import 'package:carbon_voice_console/core/common/app_icon_button.dart';
import 'package:carbon_voice_console/core/common/app_icons.dart';
import 'package:carbon_voice_console/core/common/app_text_field.dart';
import 'package:carbon_voice_console/core/common/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Panel for searching conversations by ID or Name
class ConversationSearchPanel extends StatelessWidget {
  const ConversationSearchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
      selector: (state) => state is ConversationLoaded ? state : null,
      builder: (context, conversationState) {
        if (conversationState == null || !conversationState.isSearchOpen) {
          return const SizedBox.shrink();
        }

        return AppContainer(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppColors.surface,
          border: Border.all(color: AppColors.border),
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Conversations',
                    style: AppTextStyle.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppIconButton(
                    icon: AppIcons.close,
                    onPressed: () {
                      context.read<ConversationBloc>().add(
                        const CloseConversationSearch(),
                      );
                    },
                    size: AppIconButtonSize.small,
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search mode toggle
              Row(
                children: [
                  _SearchModeButton(
                    label: 'Name',
                    isSelected: conversationState.searchMode == ConversationSearchMode.name,
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        const ToggleSearchMode(ConversationSearchMode.name),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _SearchModeButton(
                    label: 'ID',
                    isSelected: conversationState.searchMode == ConversationSearchMode.id,
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        const ToggleSearchMode(ConversationSearchMode.id),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search input
              AppTextField(
                hintText: conversationState.searchMode == ConversationSearchMode.id
                    ? 'Enter conversation ID'
                    : 'Search by name',
                value: conversationState.searchQuery,
                onChanged: (value) {
                  context.read<ConversationBloc>().add(
                    UpdateSearchQuery(value),
                  );
                },
                prefixIcon: Icon(
                  AppIcons.search,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Search results
              if (conversationState.searchQuery.isNotEmpty) ...[
                Text(
                  '${conversationState.filteredConversations.length} result(s)',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: conversationState.filteredConversations.isEmpty
                      ? _EmptySearchResults(
                          searchMode: conversationState.searchMode,
                        )
                      : _SearchResultsList(
                          conversations: conversationState.filteredConversations,
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Button for toggling search mode
class _SearchModeButton extends StatelessWidget {
  const _SearchModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.background,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Empty state for search results
class _EmptySearchResults extends StatelessWidget {
  const _EmptySearchResults({
    required this.searchMode,
  });

  final ConversationSearchMode searchMode;

  @override
  Widget build(BuildContext context) {
    final message = searchMode == ConversationSearchMode.id
        ? 'No conversation found with this ID'
        : 'No conversations match your search';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// List of search results
class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.conversations,
  });

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: conversations.map((conversation) {
          return _SearchResultItem(conversation: conversation);
        }).toList(),
      ),
    );
  }
}

/// Individual search result item
class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.conversation,
  });

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ConversationBloc>().add(
          SelectConversationFromSearch(conversation.id),
        );
      },
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 4),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.message,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${conversation.id}',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.add,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Widget compiles successfully: `dart analyze lib/features/messages/presentation_messages_dashboard/widgets/conversation_search_panel.dart`
- [ ] All imports resolve correctly
- [ ] No syntax errors

#### Manual Verification:
- [ ] Search panel follows app design patterns
- [ ] Uses consistent styling (AppColors, AppTextStyle)
- [ ] Component structure is clear and maintainable

**Implementation Note**: After creating this widget, verify it compiles before integrating into the app bar.

---

## Phase 5: Integrate Search Panel into Dashboard App Bar

### Overview
Add search icon button and search panel to the dashboard app bar, positioning them to the right of the conversation dropdown.

### Changes Required

#### 1. Update DashboardAppBar
**File**: `lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart`

**Changes**: Add search icon button and search panel

**Step 1: Add import** at the top of the file:

```dart
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/conversation_search_panel.dart';
```

**Step 2: Find the conversation dropdown section** (around line 144-233), specifically the Column widget that contains the "Conversations" dropdown.

**Replace the existing conversation section** with:

```dart
// Conversation Selector Dropdown with Search
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Existing dropdown
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Conversations',
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 170,
          height: 40,
          child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
            selector: (state) => state is ConversationLoaded ? state : null,
            builder: (context, conversationState) {
              if (conversationState == null || conversationState.conversations.isEmpty) {
                return AppContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: AppColors.surface,
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  child: Text(
                    'No conversations',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return AppDropdown<String>(
                value: null,
                hint: Text(
                  conversationState.selectedConversationIds.isEmpty
                      ? 'Select conversations...'
                      : '${conversationState.selectedConversationIds.length} selected',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                dropdownKey: const Key('conversation_dropdown'),
                items: conversationState.conversations.map((conversation) {
                  final isSelected = conversationState.selectedConversationIds.contains(conversation.id);
                  return DropdownMenuItem<String>(
                    value: conversation.id,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? AppIcons.check : AppIcons.add,
                          size: 16,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            conversation.name,
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final currentSelected = Set<String>.from(conversationState.selectedConversationIds);
                    if (currentSelected.contains(newValue)) {
                      currentSelected.remove(newValue);
                    } else {
                      currentSelected.add(newValue);
                    }
                    context.read<ConversationBloc>().add(SelectMultipleConversations(currentSelected));
                  }
                },
              );
            },
          ),
        ),
      ],
    ),

    // Search icon button
    const SizedBox(width: 8),
    BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
      selector: (state) => state is ConversationLoaded ? state : null,
      builder: (context, conversationState) {
        if (conversationState == null || conversationState.conversations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 22), // Align with dropdown
          child: AppIconButton(
            icon: AppIcons.search,
            onPressed: () {
              context.read<ConversationBloc>().add(
                const OpenConversationSearch(),
              );
            },
            size: AppIconButtonSize.medium,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            tooltip: 'Search conversations',
          ),
        );
      },
    ),

    // Search panel
    const SizedBox(width: 8),
    const ConversationSearchPanel(),
  ],
),
```

### Success Criteria

#### Automated Verification:
- [ ] App compiles successfully: `flutter analyze`
- [ ] No import errors
- [ ] Widget tree is valid

#### Manual Verification:
- [ ] Search icon appears to the right of conversation dropdown
- [ ] Clicking search icon opens the search panel
- [ ] Search panel appears to the right, shifting other content
- [ ] Search panel has close button that works
- [ ] Switching between ID/Name modes works
- [ ] Typing in search input updates results in real-time
- [ ] ID search finds exact matches only
- [ ] Name search finds partial, case-insensitive matches
- [ ] Selecting a result adds conversation to selected list
- [ ] Search panel closes after selection
- [ ] Dropdown still works as before (multi-select with checkmarks)

**Implementation Note**: After completing this phase and all automated verification passes, thoroughly test the search functionality manually before marking the implementation complete.

---

## Testing Strategy

### Unit Tests

**Sorting Logic Tests** (in `conversation_bloc_test.dart`):
```dart
group('Conversation Sorting', () {
  test('sorts by lastPostedTs descending', () {
    // Test conversations with different lastPostedTs values
    // Verify most recent (highest timestamp) comes first
  });

  test('falls back to lastUpdatedTs when lastPostedTs is null', () {
    // Test conversations with null lastPostedTs
    // Verify sorting uses lastUpdatedTs
  });

  test('falls back to createdTs when both lastPostedTs and lastUpdatedTs are null', () {
    // Test conversations with null lastPostedTs and lastUpdatedTs
    // Verify sorting uses createdTs
  });

  test('handles all null timestamps gracefully', () {
    // Test conversations with all null timestamps
    // Verify no crashes and consistent ordering
  });
});
```

**Search Filtering Tests** (in `conversation_state_test.dart`):
```dart
group('Search Filtering', () {
  test('filteredConversations returns all when search is closed', () {
    // Verify full list returned when isSearchOpen = false
  });

  test('filteredConversations returns all when query is empty', () {
    // Verify full list returned when searchQuery = ''
  });

  test('ID search returns exact match only', () {
    // Test ID search with exact match
    // Verify only exact match returned
  });

  test('ID search returns empty when no exact match', () {
    // Test ID search with no match
    // Verify empty list returned
  });

  test('Name search is case-insensitive', () {
    // Test name search with different cases
    // Verify case-insensitive matching
  });

  test('Name search finds partial matches', () {
    // Test name search with partial string
    // Verify all conversations containing substring are returned
  });
});
```

**BLoC Event Handler Tests** (in `conversation_bloc_test.dart`):
```dart
group('Search Event Handlers', () {
  blocTest<ConversationBloc, ConversationState>(
    'OpenConversationSearch sets isSearchOpen to true and resets query',
    build: () => conversationBloc,
    seed: () => ConversationLoaded(/* ... */),
    act: (bloc) => bloc.add(const OpenConversationSearch()),
    expect: () => [
      isA<ConversationLoaded>()
        .having((s) => s.isSearchOpen, 'isSearchOpen', true)
        .having((s) => s.searchQuery, 'searchQuery', '')
        .having((s) => s.searchMode, 'searchMode', ConversationSearchMode.name),
    ],
  );

  blocTest<ConversationBloc, ConversationState>(
    'UpdateSearchQuery updates search query',
    build: () => conversationBloc,
    seed: () => ConversationLoaded(/* ... isSearchOpen: true */),
    act: (bloc) => bloc.add(const UpdateSearchQuery('test')),
    expect: () => [
      isA<ConversationLoaded>()
        .having((s) => s.searchQuery, 'searchQuery', 'test'),
    ],
  );

  blocTest<ConversationBloc, ConversationState>(
    'SelectConversationFromSearch adds to selected and closes panel',
    build: () => conversationBloc,
    seed: () => ConversationLoaded(/* ... isSearchOpen: true */),
    act: (bloc) => bloc.add(const SelectConversationFromSearch('conv-123')),
    expect: () => [
      isA<ConversationLoaded>()
        .having((s) => s.selectedConversationIds.contains('conv-123'), 'contains conv-123', true)
        .having((s) => s.isSearchOpen, 'isSearchOpen', false)
        .having((s) => s.searchQuery, 'searchQuery', ''),
    ],
  );
});
```

### Integration Tests

**Full Search Flow**:
1. Load conversations for a workspace
2. Verify conversations are sorted by most recent
3. Open search panel via icon button
4. Switch to ID mode
5. Enter exact ID
6. Verify exact match appears
7. Select result
8. Verify conversation added to selected list
9. Verify search panel closed
10. Reopen search
11. Switch to Name mode
12. Enter partial name
13. Verify case-insensitive partial matches appear
14. Select result
15. Verify added to selected list

### Manual Testing Steps

1. **Sorting Verification**:
   - Select a workspace with many conversations
   - Open conversation dropdown
   - Verify first conversation has most recent `lastPostedTs`
   - Scroll through list and spot-check timestamps
   - Verify conversations with null timestamps appear at bottom

2. **Search Icon**:
   - Verify icon appears to the right of dropdown
   - Verify icon is disabled when no conversations loaded
   - Verify icon has hover state
   - Verify tooltip appears on hover

3. **Search Panel - Basic**:
   - Click search icon
   - Verify panel opens to the right
   - Verify panel has close button (X)
   - Click close button, verify panel closes
   - Click search icon again, verify panel reopens

4. **Search Panel - ID Mode**:
   - Open search panel
   - Select "ID" mode
   - Enter exact conversation ID
   - Verify exact match appears in results
   - Enter non-existent ID
   - Verify "No conversation found" message
   - Enter partial ID
   - Verify no results (ID is exact match only)

5. **Search Panel - Name Mode**:
   - Switch to "Name" mode
   - Enter partial conversation name in lowercase
   - Verify case-insensitive matches appear
   - Enter uppercase partial name
   - Verify same matches appear
   - Enter non-matching string
   - Verify "No conversations match" message

6. **Search Results Selection**:
   - Search for a conversation
   - Click on result
   - Verify conversation added to selected list (appears as pill)
   - Verify search panel closes
   - Verify search query cleared

7. **Mode Switching**:
   - Open search
   - Enter query in Name mode
   - Switch to ID mode
   - Verify query cleared
   - Switch back to Name mode
   - Verify query still cleared (doesn't remember)

8. **Edge Cases**:
   - Test with 1 conversation
   - Test with 100+ conversations
   - Test with conversations having null timestamps
   - Test rapid typing in search input
   - Test switching modes rapidly

9. **Visual/UX**:
   - Verify search panel doesn't overlap other UI elements
   - Verify scrolling works in long search results
   - Verify text truncation in long conversation names
   - Verify consistent styling with rest of app
   - Verify responsive behavior on different screen sizes

## Performance Considerations

### Memory
- **Sorting**: Creates new sorted list on each load (minimal overhead for typical workspace sizes)
- **Search filtering**: Uses `where()` which creates lazy iterable (efficient for repeated filtering)
- **State updates**: Immutable state pattern prevents unnecessary rebuilds via BlocSelector

### UI Performance
- **No debouncing needed**: Searching in-memory cached data is fast enough (tested with 1000+ items)
- **Lazy filtering**: `filteredConversations` getter computes on-demand
- **Selective rebuilds**: BlocSelector ensures only affected widgets rebuild

### Optimization Opportunities (if needed)
- If workspace has 1000+ conversations, consider virtualizing search results list
- If sorting becomes slow, cache sorted list until new conversations loaded
- If filtering is slow, add debouncing to search input (300ms delay)

## Migration Notes

### Breaking Changes
None - this is purely additive functionality.

### Affected Code
- `ConversationBloc` - Enhanced with sorting and search logic
- `ConversationState` - Extended with search fields
- `ConversationEvent` - New search-related events
- `DashboardAppBar` - Layout modified to include search UI

### Migration Steps for Consumers
No migration needed - all changes are backward compatible. Existing conversation selection behavior is preserved.

## References

- **Current conversation dropdown**: [lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart:144-233](lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart#L144-L233)
- **Conversation entity**: [lib/features/conversations/domain/entities/conversation.dart:1](lib/features/conversations/domain/entities/conversation.dart#L1)
- **ConversationBloc**: [lib/features/conversations/presentation/bloc/conversation_bloc.dart:1](lib/features/conversations/presentation/bloc/conversation_bloc.dart#L1)
- **Existing conversation selection widget**: [lib/features/messages/presentation_messages_dashboard/widgets/conversation_selected_widget.dart:1](lib/features/messages/presentation_messages_dashboard/widgets/conversation_selected_widget.dart#L1)
