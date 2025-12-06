import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesActionPanelWrapper extends StatelessWidget {
  const MessagesActionPanelWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
      builder: (context, selectionState) {
        if (!selectionState.hasSelection) return const SizedBox.shrink();

        return Positioned(
          bottom: 24,
          right: 24,
          child: MessagesActionPanel(
            onDownloadAudio: () {
              final messageIds = context.read<MessageSelectionCubit>().getSelectedMessageIds();
              context.read<DownloadBloc>().add(StartDownloadAudio(messageIds));
              context.read<MessageSelectionCubit>().clearSelection();
            },
            onDownloadTranscript: () {
              final messageIds = context.read<MessageSelectionCubit>().getSelectedMessageIds();
              context.read<DownloadBloc>().add(StartDownloadTranscripts(messageIds));
              context.read<MessageSelectionCubit>().clearSelection();
            },
            onSummarize: () {
              // TODO: Implement summarize functionality
            },
            onAIChat: () {
              // TODO: Implement AI chat functionality
            },
          ),
        );
      },
    );
  }
}
