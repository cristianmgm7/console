import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Panel for searching conversations by ID or Name
class ConversationSearchPanel extends StatefulWidget {
  const ConversationSearchPanel({super.key});

  @override
  State<ConversationSearchPanel> createState() => _ConversationSearchPanelState();
}


class _ConversationSearchPanelState extends State<ConversationSearchPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationSearchBloc, ConversationSearchState>(
      builder: (context, searchState) {
        // Only show panel if search is open
        if (searchState is! ConversationSearchOpen) {
          return const SizedBox.shrink();
        }

        // Keep controller in sync with BLoC state
        if (_searchController.text != searchState.searchQuery) {
          _searchController.value = TextEditingValue(
            text: searchState.searchQuery,
            selection: TextSelection.collapsed(offset: searchState.searchQuery.length),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 320,
            maxHeight: 420,
          ),
          child: AppContainer(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.surface,
            border: Border.all(color: AppColors.border),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        context.read<ConversationSearchBloc>().add(const CloseConversationSearch());
                      },
                      size: AppIconButtonSize.small,
                      backgroundColor: AppColors.transparent,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SearchModeButton(
                      label: 'Name',
                      isSelected: searchState.searchMode == ConversationSearchMode.name,
                      onTap: () {
                        context.read<ConversationSearchBloc>().add(
                              const ToggleSearchMode(ConversationSearchMode.name),
                            );
                      },
                    ),
                    const SizedBox(width: 8),
                    _SearchModeButton(
                      label: 'ID',
                      isSelected: searchState.searchMode == ConversationSearchMode.id,
                      onTap: () {
                        context.read<ConversationSearchBloc>().add(
                              const ToggleSearchMode(ConversationSearchMode.id),
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _searchController,
                  hint: searchState.searchMode == ConversationSearchMode.id
                      ? 'Enter conversation ID'
                      : 'Search by name',
                  onChanged: (value) {
                    context.read<ConversationSearchBloc>().add(UpdateSearchQuery(value));
                  },
                  prefixIcon: Icon(
                    AppIcons.search,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (searchState.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (searchState.isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    Text(
                      '${searchState.filteredConversations.length} result(s)',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SizedBox(
                        height: 240,
                        child: searchState.filteredConversations.isEmpty
                            ? _EmptySearchResults(searchMode: searchState.searchMode)
                            : _SearchResultsList(conversations: searchState.filteredConversations),
                      ),
                    ),
                  ],
                ],
              ],
            ),
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
class _SearchResultsList extends StatefulWidget {
  const _SearchResultsList({
    required this.conversations,
  });

  final List<Conversation> conversations;

  @override
  State<_SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<_SearchResultsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.conversations.length,
        itemBuilder: (context, index) {
          final conversation = widget.conversations[index];
          return _SearchResultItem(conversation: conversation);
        },
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
        // Select the conversation in ConversationBloc
        context.read<ConversationBloc>().add(
              ToggleConversation(conversation.channelGuid!),
            );
        // Close the search panel
        context.read<ConversationSearchBloc>().add(const CloseConversationSearch());
      },
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: AppColors.surface,
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
                    conversation.channelName ?? 'Unknown Conversation',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${conversation.channelGuid ?? 'Unknown'}',
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
