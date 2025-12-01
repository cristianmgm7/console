import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_player_sheet.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    required this.scrollController,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    required this.onToggleSelectAll,
    required this.selectAll,
    this.onViewDetail,
    this.onDownloadAudio,
    this.onDownloadTranscript,
    this.onSummarize,
    this.onAIChat,
    super.key,
  });

  final ScrollController scrollController;
  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final void Function(int length, {bool? value}) onToggleSelectAll;
  final bool selectAll;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final ValueChanged<String>? onViewDetail;
  final VoidCallback? onDownloadAudio;
  final VoidCallback? onDownloadTranscript;
  final VoidCallback? onSummarize;
  final VoidCallback? onAIChat;

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayButton(BuildContext context, MessageUiModel message, AudioPlayerState audioState) {
    final isCurrentMessage = audioState is AudioPlayerReady && audioState.messageId == message.id;
    final isPlaying = isCurrentMessage && audioState.isPlaying;

    return AppIconButton(
      icon: isPlaying ? AppIcons.pause : AppIcons.play,
      tooltip: isPlaying ? 'Pause audio' : 'Play audio',
      onPressed: () => _handleAudioAction(context, message, audioState),
      foregroundColor: isCurrentMessage ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
      size: AppIconButtonSize.small,
    );
  }

  Future<void> _handleAudioAction(BuildContext context, MessageUiModel message, AudioPlayerState audioState) async {
    final audioBloc = context.read<AudioPlayerBloc>();
    final isCurrentMessage = audioState is AudioPlayerReady && audioState.messageId == message.id;

    if (isCurrentMessage) {
      // Toggle play/pause for current message
      if (audioState.isPlaying) {
        audioBloc.add(const PauseAudio());
      } else {
        audioBloc.add(const PlayAudio());
      }
    } else {
      // Load and play new message
      await _handlePlayAudio(context, message);
    }
  }

  Future<void> _handlePlayAudio(BuildContext context, MessageUiModel message) async {
    if (!message.hasPlayableAudio || message.audioUrl == null) return;

    // Get the audio player BLoC
    final audioBloc = context.read<AudioPlayerBloc>();

    // Load audio - let the BLoC fetch the pre-signed URL
    audioBloc.add(
      LoadAudio(
        messageId: message.id,
        waveformData: message.playableAudioModel?.waveformData ?? [],
      ),
    );

    // Auto-play after loading
    audioBloc.add(const PlayAudio());

    // Show player modal
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const AudioPlayerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      backgroundColor: AppColors.surface,
      child: Stack(
        children: [
          // Main content
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, messageState) {
              return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                builder: (context, audioState) {
                  return _buildContent(context, messageState, audioState);
                },
              );
            },
          ),

          // Action panel - only show when messages are selected
          if (selectedMessages.isNotEmpty && onDownloadAudio != null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: MessagesActionPanel(
                  selectedCount: selectedMessages.length,
                  onDownloadAudio: onDownloadAudio!,
                  onDownloadTranscript: onDownloadTranscript ?? () {},
                  onSummarize: onSummarize ?? () {},
                  onAIChat: onAIChat ?? () {},
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MessageState messageState, AudioPlayerState audioState) {
    // Show loading when any bloc is loading
    if (isAnyBlocLoading(context)) {
      return const Center(child: AppProgressIndicator());
    }

    if (messageState is MessageError) {
      return AppEmptyState.error(
        message: messageState.message,
        onRetry: () {
          // Retry by reloading workspaces
          context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
        },
      );
    }
    // Handle MessageLoaded state
    if (messageState is MessageLoaded) {
      // Check if we have messages to display
      if (messageState.messages.isEmpty) {
        return AppEmptyState.noMessages(
          onRetry: () {
            // Retry by reloading workspaces
            context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
          },
        );
      }

      final tableWidget = AppTable(
        selectAll: selectAll,
        onSelectAllChanged: (value) =>
            onToggleSelectAll(messageState.messages.length, value: value),
        columns: const [
          AppTableColumn(
            title: 'Date',
            width: FixedColumnWidth(90),
          ),
          AppTableColumn(
            title: 'Play',
            width: FixedColumnWidth(60),
          ),
          AppTableColumn(
            title: 'Duration',
            width: FixedColumnWidth(80),
          ),
          AppTableColumn(
            title: 'Owner',
            width: FixedColumnWidth(120),
          ),
          AppTableColumn(
            title: 'Summary',
            width: FlexColumnWidth(),
          ),
          AppTableColumn(
            title: 'Actions',
            width: FixedColumnWidth(180), // Increased width for horizontal action buttons
          ),
        ],
        rows: messageState.messages.map((message) {
          return AppTableRow(
            selected: selectedMessages.contains(message.id),
            onSelectChanged: (selected) =>
                onToggleMessageSelection(message.id, value: selected),
            cells: [
              // Date
              Text(
                _formatDate(message.createdAt),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Play
              if (message.hasPlayableAudio) _buildPlayButton(context, message, audioState)
              else const SizedBox.shrink(),

              // Duration
              Text(
                _formatDuration(message.duration),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              // Owner
              Text(
                message.creator?.name ?? message.creatorId,
                style: AppTextStyle.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              // Message
              Text(
                message.text ?? 'No content',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Horizontal Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: AppIcons.eye,
                    tooltip: 'View Details',
                    onPressed: () => onViewDetail?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () => {}, // TODO: Implement download action
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.delete,
                    tooltip: 'Delete',
                    onPressed: () => {}, // TODO: Implement delete action
                    foregroundColor: AppColors.error,
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      );

      // Add loading indicator below the table if loading more
      if (messageState.isLoadingMore) {
        return Column(
          children: [
            tableWidget,
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: AppProgressIndicator()),
            ),
          ],
        );
      }

      return tableWidget;
    }

    // Show initial state with progressive loading hints
    return AppEmptyState.loading();
  }
}
