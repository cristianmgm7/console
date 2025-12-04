import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_mini_player_widget.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/messages_action_panel.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/components/pagination_controls.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
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
    super.key,
  });

  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final void Function(int length, {bool? value}) onToggleSelectAll;
  final bool selectAll;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final VoidCallback onManualLoadMore;
  final ValueChanged<String>? onViewDetail;
  final ValueChanged<String>? onReply;
  final ValueChanged<String>? onDownloadMessage;
  final VoidCallback? onDownloadAudio;
  final VoidCallback? onDownloadTranscript;
  final VoidCallback? onSummarize;
  final VoidCallback? onAIChat;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          if (widget.selectedMessages.isNotEmpty && widget.onDownloadAudio != null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: MessagesActionPanel(
                  selectedCount: widget.selectedMessages.length,
                  onDownloadAudio: widget.onDownloadAudio!,
                  onDownloadTranscript: widget.onDownloadTranscript ?? () {},
                  onSummarize: widget.onSummarize ?? () {},
                  onAIChat: widget.onAIChat ?? () {},
                ),
              ),
            ),

          // Mini player - show when audio is ready
          Positioned(
            bottom: widget.selectedMessages.isNotEmpty ? 100 : 24,
            left: 0,
            right: 0,
            child: const Center(
              child: AudioMiniPlayerWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MessageState messageState, AudioPlayerState audioState) {
    // Show loading when any bloc is loading
    if (widget.isAnyBlocLoading(context)) {
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
        selectAll: widget.selectAll,
        onSelectAllChanged: (value) =>
            widget.onToggleSelectAll(messageState.messages.length, value: value),
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
            selected: widget.selectedMessages.contains(message.id),
            onSelectChanged: (selected) =>
                widget.onToggleMessageSelection(message.id, value: selected),
            cells: [
              // Date
              Text(
                DateTimeFormatters.formatDate(message.createdAt),
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              // Play
              if (message.hasPlayableAudio) MessagePlayButton(message: message, audioState: audioState)
              else const SizedBox.shrink(),

              // Duration
              Text(
                DateTimeFormatters.formatDuration(message.duration),
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
                    onPressed: () => widget.onViewDetail?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.reply,
                    tooltip: 'Reply',
                    onPressed: () => widget.onReply?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: AppIcons.download,
                    tooltip: 'Download',
                    onPressed: () => widget.onDownloadMessage?.call(message.id),
                    size: AppIconButtonSize.small,
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      );

      // Always show pagination controls below the table (replaces loading indicator)
      return Column(
        children: [
          // Make the table scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: tableWidget,
            ),
          ),
          PaginationControls(
            onLoadMore: widget.onManualLoadMore,
            hasMore: messageState.hasMoreMessages,
            isLoading: messageState.isLoadingMore,
          ),
        ],
      );
    }

    // Show initial state with progressive loading hints
    return AppEmptyState.loading();
  }
}
