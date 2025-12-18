import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart'
    as msg_events;
import 'package:carbon_voice_console/features/messages/presentation_send_message/components/inline_message_composition_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageCompositionPanelWrapper extends StatelessWidget {
  const MessageCompositionPanelWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageCompositionCubit, MessageCompositionState>(
      builder: (context, compositionState) {
        if (!compositionState.isVisible || !compositionState.canCompose) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 54, // Above the audio mini player (24 + ~80 for player height + padding)
          left: 24,
          right: 24,
          child: Center(
            child: InlineMessageCompositionPanel(
              workspaceId: compositionState.workspaceId!,
              channelId: compositionState.channelId!,
              replyToMessageId: compositionState.replyToMessageId,
              onClose: () {
                context.read<MessageCompositionCubit>().closePanel();
              },
              onSuccess: () {
                // Refresh messages after successful send
                context.read<MessageBloc>().add(const msg_events.RefreshMessages());
                context.read<MessageCompositionCubit>().onSuccess();
              },
              onCancelReply: () {
                context.read<MessageCompositionCubit>().cancelReply();
              },
            ),
          ),
        );
      },
    );
  }
}
