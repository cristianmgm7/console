import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationSelectorSection extends StatelessWidget {
  const ConversationSelectorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Conversations',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
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
                // empty state or
                return _buildNoConversationsState();
              }
              // build conversations dropdown
              return _buildConversationsDropdown(context, conversationState);
            },
          ),
        ),
      ],
    );
  }

  // empty state or loading state
  Widget _buildNoConversationsState() {
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

  // build conversations dropdown
  Widget _buildConversationsDropdown(BuildContext context, ConversationLoaded conversationState) {
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
        final isSelected = conversationState.selectedConversationIds.contains(
          conversation.channelGuid,
        );
        return DropdownMenuItem<String>(
          value: conversation.channelGuid,
          child: Row(
            children: [
              Icon(
                isSelected ? AppIcons.check : AppIcons.add,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                conversation.channelName ?? 'Unknown Conversation',
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
            currentSelected.remove(newValue);
          } else {
            currentSelected.add(newValue);
          }
          context.read<ConversationBloc>().add(SelectMultipleConversations(currentSelected));
        }
      },
    );
  }
}
