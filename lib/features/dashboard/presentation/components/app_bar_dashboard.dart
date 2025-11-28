import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/widgets/conversation_widget.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
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
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.zero,
      border: const Border(
        bottom: BorderSide(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Messages',
              style: AppTextStyle.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
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

              return Column(
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
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 170,
                    height: 40,
                    child: AppDropdown<String>(
                      value: workspaceState.selectedWorkspace?.id,
                      items: workspaceState.workspaces.map((workspace) {
                        return DropdownMenuItem<String>(
                          value: workspace.id,
                          child: Text(
                            workspace.name,
                            style: AppTextStyle.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          context
                              .read<WorkspaceBloc>()
                              .add(ws_events.SelectWorkspace(newValue));
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 16),

          // Conversation Selector Dropdown
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
                    if (conversationState == null ||
                        conversationState.conversations.isEmpty) {
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

                    final selectedCount = conversationState.selectedConversationIds.length;
                    final displayText = selectedCount == 0
                        ? 'Select conversations'
                        : '$selectedCount selected';

                    return PopupMenuButton<String>(
                      child: AppContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: AppColors.surface,
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayText,
                                style: AppTextStyle.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              AppIcons.chevronDown,
                              size: 20,
                              color: AppColors.textSecondary,
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
                            AppCheckbox(
                              value: isSelected,
                              onChanged: null, // Handled by parent onSelected
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                    }).toList();
                  },
                  onSelected: (String conversationId) {
                    context.read<ConversationBloc>().add(ToggleConversation(conversationId));
                  },
                );
              },
            ),
          ),
        ],
      ),

          const SizedBox(width: 16),

          // Selected Conversations Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
                selector: (state) => state is ConversationLoaded ? state : null,
                builder: (context, conversationState) {
                if (conversationState == null || conversationState.selectedConversationIds.isEmpty) {
                  return const SizedBox.shrink();
                }

                final selectedConversations = conversationState.conversations
                    .where((c) => conversationState.selectedConversationIds.contains(c.id))
                    .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: selectedConversations.map((conversation) {
                      return ConversationWidget(
                        
                        conversation: conversation,
                        onRemove: () {
                          context.read<ConversationBloc>().add(ToggleConversation(conversation.id));
                        },
                      );
                    }).toList(),
                  ),
                );
              },
              ),
            ),
          ),
          // Refresh button - only show when any bloc is loaded
          BlocBuilder<WorkspaceBloc, WorkspaceState>(
            builder: (context, workspaceState) {
              final hasData = workspaceState is WorkspaceLoaded;
              if (!hasData) return const SizedBox.shrink();

              return AppIconButton(
                icon: AppIcons.refresh,
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
