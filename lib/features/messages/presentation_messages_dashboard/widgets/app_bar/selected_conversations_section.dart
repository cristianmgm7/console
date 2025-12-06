import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectedConversationsSection extends StatelessWidget {
  const SelectedConversationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
          selector: (state) => state is ConversationLoaded ? state : null,
          builder: (context, conversationState) {
            if (conversationState == null ||
                conversationState.selectedConversationIds.isEmpty) {
              return _buildEmptyState();
            }

            return _buildConversationsList(context, conversationState);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const SizedBox.shrink();

  Widget _buildConversationsList(BuildContext context, ConversationLoaded conversationState) {
    final selectedConversations = conversationState.conversations
        .where((c) => conversationState.selectedConversationIds.contains(c.id))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: selectedConversations.map((conversation) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: AppPillContainer(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      conversation.name,
                      style: AppTextStyle.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppIconButton(
                    icon: AppIcons.close,
                    onPressed: () {
                      context.read<ConversationBloc>().add(
                        ToggleConversation(conversation.id),
                      );
                    },
                    size: AppIconButtonSize.small,
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
