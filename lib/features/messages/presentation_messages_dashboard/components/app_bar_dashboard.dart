import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/conversation_selected_widget.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    this.onSendMessage,
    super.key,
  });

  final VoidCallback? onSendMessage;

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
                      dropdownKey: const Key('workspace_dropdown'),
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
                          context.read<WorkspaceBloc>().add(ws_events.SelectWorkspace(newValue));
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
                      value: null, // No single value since we allow multiple selections
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
                              Text(
                                conversation.name,
                                style: AppTextStyle.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
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
                            // Remove if already selected (toggle off)
                            currentSelected.remove(newValue);
                          } else {
                            // Add if not selected (toggle on)
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

          const SizedBox(width: 16),

          // Selected Conversations Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
                selector: (state) => state is ConversationLoaded ? state : null,
                builder: (context, conversationState) {
                  if (conversationState == null ||
                      conversationState.selectedConversationIds.isEmpty) {
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
                            context.read<ConversationBloc>().add(
                              ToggleConversation(conversation.id),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Send Message Button - only show when exactly one conversation is selected
          if (onSendMessage != null)
            BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
              selector: (state) => state is ConversationLoaded ? state : null,
              builder: (context, conversationState) {
                if (conversationState == null ||
                    conversationState.selectedConversationIds.length != 1) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 24),
                  child: AppButton(
                    onPressed: onSendMessage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.add, size: 16),
                        const SizedBox(width: 6),
                        const Text('Send Message'),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
