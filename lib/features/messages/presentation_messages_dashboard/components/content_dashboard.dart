import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_mini_player_widget.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/messages_content.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/components/inline_message_composition_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    required this.onToggleSelectAll,
    required this.selectAll,
    required this.onManualLoadMore,
    this.onViewDetail,
    this.onReply,
    this.onDownloadMessage,
    this.onDownloadAudio,
    this.onDownloadTranscript,
    this.onSummarize,
    this.onAIChat,
    this.showMessageComposition,
    this.compositionWorkspaceId,
    this.compositionChannelId,
    this.compositionReplyToMessageId,
    this.onCloseMessageComposition,
    this.onMessageCompositionSuccess,
    super.key,
  });

  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final void Function(int length, {bool? value}) onToggleSelectAll;
  final bool selectAll;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final VoidCallback onManualLoadMore;
  final ValueChanged<String>? onViewDetail;
  final void Function(String messageId, String channelId)? onReply;
  final ValueChanged<String>? onDownloadMessage;
  final VoidCallback? onDownloadAudio;
  final VoidCallback? onDownloadTranscript;
  final VoidCallback? onSummarize;
  final VoidCallback? onAIChat;

  // Message composition panel parameters
  final bool? showMessageComposition;
  final String? compositionWorkspaceId;
  final String? compositionChannelId;
  final String? compositionReplyToMessageId;
  final VoidCallback? onCloseMessageComposition;
  final VoidCallback? onMessageCompositionSuccess;

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
                    selectedMessages: widget.selectedMessages,
                    onToggleMessageSelection: widget.onToggleMessageSelection,
                    onToggleSelectAll: widget.onToggleSelectAll,
                    selectAll: widget.selectAll,
                    onManualLoadMore: widget.onManualLoadMore,
                    onViewDetail: widget.onViewDetail,
                    onReply: widget.onReply,
                    onDownloadMessage: widget.onDownloadMessage,
                  );
                },
              );
            },
          ),

          // Action panel - positioned in top-right for track downloads
          if (widget.selectedMessages.isNotEmpty && widget.onDownloadAudio != null)
            Positioned(
              top: 24,
              right: 24,
              child: MessagesActionPanel(
                selectedCount: widget.selectedMessages.length,
                onDownloadAudio: widget.onDownloadAudio!,
                onDownloadTranscript: widget.onDownloadTranscript ?? () {},
                onSummarize: widget.onSummarize ?? () {},
                onAIChat: widget.onAIChat ?? () {},
              ),
            ),

          // Mini player - positioned at bottom
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AudioMiniPlayerWidget(),
            ),
          ),

          // Message composition panel - positioned above audio mini player
          if ((widget.showMessageComposition ?? false) &&
              widget.compositionWorkspaceId != null &&
              widget.compositionChannelId != null)
            Positioned(
              bottom: 120, // Above the audio mini player (24 + ~80 for player height + padding)
              left: 24,
              right: 24,
              child: Center(
                child: InlineMessageCompositionPanel(
                  workspaceId: widget.compositionWorkspaceId!,
                  channelId: widget.compositionChannelId!,
                  replyToMessageId: widget.compositionReplyToMessageId,
                  onClose: widget.onCloseMessageComposition,
                  onSuccess: widget.onMessageCompositionSuccess,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
