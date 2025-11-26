import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart' as ws_events;
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    required this.onRefresh,
    super.key,
  });

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            'Audio Messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(width: 16),

          // Workspace Dropdown
          BlocSelector<WorkspaceBloc, WorkspaceState, WorkspaceLoaded?>(
            selector: (state) => state is WorkspaceLoaded ? state : null,
            builder: (context, workspaceState) {
              if (workspaceState == null || workspaceState.workspaces.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: workspaceState.selectedWorkspace?.id,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: workspaceState.workspaces.map((workspace) {
                    return DropdownMenuItem<String>(
                      value: workspace.id,
                      child: Text(workspace.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<WorkspaceBloc>().add(ws_events.SelectWorkspace(newValue));
                    }
                  },
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Search Field and Conversation Display (Flexible)
          Expanded(
            child: Row(
              children: [
                // Conversation Selector Dropdown
                Flexible(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
                      selector: (state) => state is ConversationLoaded ? state : null,
                      builder: (context, conversationState) {
                        if (conversationState == null || conversationState.conversations.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No conversations',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }

                        final selectedCount = conversationState.selectedConversationIds.length;
                        final displayText = selectedCount == 0
                            ? 'Select conversations'
                            : '$selectedCount selected';

                        return PopupMenuButton<String>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayText,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return conversationState.conversations.map((conversation) {
                              final isSelected = conversationState.selectedConversationIds.contains(conversation.id);
                              return PopupMenuItem<String>(
                                value: conversation.id,
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: null, // Handled by parent onSelected
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        conversation.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                          onSelected: (String conversationId) {
                            context.read<ConversationBloc>().add(ToggleConversation(conversationId));
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Conversation Name Display
                Flexible(
                  flex: 3,
                  child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
                    selector: (state) => state is ConversationLoaded ? state : null,
                    builder: (context, conversationState) {
                      if (conversationState == null || conversationState.selectedConversationIds.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                conversationState.conversations
                                    .where((c) => conversationState.selectedConversationIds.contains(c.id))
                                    .map((c) => c.name)
                                    .join(', '),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Refresh button - only show when any bloc is loaded
          BlocBuilder<WorkspaceBloc, WorkspaceState>(
            builder: (context, workspaceState) {
              final hasData = workspaceState is WorkspaceLoaded;
              if (!hasData) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
    );
  }
}
