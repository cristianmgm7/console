import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_search_button.dart';
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
              const SizedBox(width: 8),
              Text(
                '${state.conversations.length}',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              const ConversationSearchButton(),
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
              child:               AppButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () {
                        context.read<ConversationBloc>().add(
                          const LoadMoreRecentConversations(),
                        );
                      },
                child: Text(state.isLoadingMore ? 'Loading...' : 'Load More'),
              ),
            ),
          ),
      ],
    );
  }
}
