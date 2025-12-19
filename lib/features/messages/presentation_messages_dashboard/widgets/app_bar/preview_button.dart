import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PreviewButton extends StatelessWidget {
  const PreviewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, conversationState) {
        // Only show button if exactly one conversation is selected
        final hasSingleConversation =
            conversationState is ConversationLoaded &&
            conversationState.selectedConversationIds.length == 1;

        if (!hasSingleConversation) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
          builder: (context, selectionState) {
            final selectedCount = selectionState.selectedCount;
            final isValidSelection = selectedCount >= 3 && selectedCount <= 10;

            return Tooltip(
              message: 'Select 3-10 messages to create a conversation preview',
              child: AppButton(
                onPressed: isValidSelection ? () => _handlePreview(context) : null,
                backgroundColor: isValidSelection
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.disabled.withValues(alpha: 0.1),
                foregroundColor: isValidSelection ? AppColors.primary : AppColors.disabled,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.share, size: 18),
                    const SizedBox(width: 8),
                    const Text('Publish Preview'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handlePreview(BuildContext context) {
    final conversationState = context.read<ConversationBloc>().state;
    final selectionState = context.read<MessageSelectionCubit>().state;
    final selectedCount = selectionState.selectedCount;

    // Double-check validation
    if (conversationState is! ConversationLoaded ||
        conversationState.selectedConversationIds.length != 1 ||
        selectedCount < 3 ||
        selectedCount > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 3-10 messages to create a preview'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final conversationId = conversationState.selectedConversationIds.first;
    final selectedMessageIds = selectionState.selectedMessageIds;

    // Join message IDs with commas
    final messageIdsParam = selectedMessageIds.join(',');

    // Navigate to preview composer
    context.go(
      '${AppRoutes.previewComposer}?conversationId=$conversationId&messageIds=$messageIdsParam',
    );

    // Clear message selection
    context.read<MessageSelectionCubit>().clearSelection();
  }
}
