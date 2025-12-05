import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_mini_player_widget.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/message_download/presentation/widgets/circular_download_progress_widget.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_event.dart'
    as msg_events;
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_content.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/pagination_controls.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_composition_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/components/inline_message_composition_panel.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.onManualLoadMore,
    required this.hasMoreMessages,
    required this.isLoadingMore,
    super.key,
  });

  final bool Function(BuildContext context) isAnyBlocLoading;
  final VoidCallback onManualLoadMore;
  final bool hasMoreMessages;
  final bool isLoadingMore;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      backgroundColor: AppColors.surface,
      child: Stack(
        children: [
          // Main content - fills entire space
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, messageState) {
              return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                builder: (context, audioState) {
                  return MessagesContent(
                    messageState: messageState,
                    audioState: audioState,
                    isAnyBlocLoading: widget.isAnyBlocLoading,
                    onReply: (messageId, channelId) {
                      final workspaceState = context.read<WorkspaceBloc>().state;
                      final workspaceId = workspaceState is WorkspaceLoaded &&
                                         workspaceState.selectedWorkspace != null
                          ? workspaceState.selectedWorkspace!.id
                          : '';

                      if (workspaceId.isEmpty) {
                        return; // Cannot open reply without workspace
                      }

                      context.read<MessageCompositionCubit>().openReply(
                        workspaceId: workspaceId,
                        channelId: channelId,
                        replyToMessageId: messageId,
                      );
                    },
                    onDownloadMessage: (messageId) {
                      context.read<DownloadBloc>().add(StartDownloadAudio({messageId}));
                    },
                  );
                },
              );
            },
          ),

          // Circular download progress indicator - positioned at top-right
          const Positioned(
            top: 100,
            right: 24,
            child: CircularDownloadProgressWidget(),
          ),

          // Action panel - reads MessageSelectionCubit
          BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
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
          ),

          // Pagination controls - positioned on the left side
          Positioned(
            bottom: 0,
            left: 24,
            child: BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
              selector: (state) => state is MessageLoaded ? state : null,
              builder: (context, messageState) {
                if (messageState == null) return const SizedBox.shrink();

                return PaginationControls(
                  onLoadMore: widget.onManualLoadMore,
                  hasMore: widget.hasMoreMessages,
                  isLoading: widget.isLoadingMore,
                );
              },
            ),
          ),

          // Mini player - positioned at bottom, moves up when composition panel is open
          BlocBuilder<MessageCompositionCubit, MessageCompositionState>(
            builder: (context, compositionState) {
              return Positioned(
                bottom: compositionState.isVisible && compositionState.canCompose
                    ? 700  // Move up when composition panel is open
                    : 24,  // Normal position
                left: 0,
                right: 0,
                child: const Center(
                  child: AudioMiniPlayerWidget(),
                ),
              );
            },
          ),

          // Message composition panel - positioned above audio mini player
          BlocBuilder<MessageCompositionCubit, MessageCompositionState>(
            builder: (context, compositionState) {
              if (!compositionState.isVisible || !compositionState.canCompose) {
                return const SizedBox.shrink();
              }

              return Positioned(
                bottom: 24, // Above the audio mini player (24 + ~80 for player height + padding)
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
          ),
        ],
      ),
    );
  }

}
