import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SendMessageButton extends StatelessWidget {
  const SendMessageButton({super.key});

  void _handleSendMessage(BuildContext context) {
    final workspaceState = context.read<WorkspaceBloc>().state;
    final conversationState = context.read<ConversationBloc>().state;

    final workspaceId = workspaceState is WorkspaceLoaded && workspaceState.selectedWorkspace != null
        ? workspaceState.selectedWorkspace!.id
        : '';

    if (workspaceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workspace selected')),
      );
      return;
    }

    if (conversationState is! ConversationLoaded || conversationState.selectedConversationIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select exactly one conversation')),
      );
      return;
    }

    // Find the selected conversation to get the correct channel ID
    final selectedConversationId = conversationState.selectedConversationIds.first;
    final selectedConversation = conversationState.conversations
        .where((c) => c.id == selectedConversationId)
        .firstOrNull;

    if (selectedConversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected conversation not found')),
      );
      return;
    }

    // Use the conversation's channelGuid as the channelId
    final channelId = selectedConversation.channelGuid ?? selectedConversation.id;

    context.read<MessageCompositionCubit>().openNewMessage(
      workspaceId: workspaceId,
      channelId: channelId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
      selector: (state) => state is ConversationLoaded ? state : null,
      builder: (context, conversationState) {
        if (conversationState == null ||
            conversationState.selectedConversationIds.length != 1) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 16, top: 24),
          child: AppButton(
            onPressed: () => _handleSendMessage(context),
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
    );
  }
}
