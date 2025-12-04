import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesContent extends StatelessWidget {
  const MessagesContent({
    required this.messageState,
    required this.audioState,
    required this.isAnyBlocLoading,
    required this.selectedMessages,
    required this.onToggleMessageSelection,
    required this.onToggleSelectAll,
    required this.selectAll,
    required this.onManualLoadMore,
    this.onViewDetail,
    this.onReply,
    this.onDownloadMessage,
    super.key,
  });

  final MessageState messageState;
  final AudioPlayerState audioState;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final void Function(int length, {bool? value}) onToggleSelectAll;
  final bool selectAll;
  final VoidCallback onManualLoadMore;
  final ValueChanged<String>? onViewDetail;
  final void Function(String messageId, String channelId)? onReply;
  final ValueChanged<String>? onDownloadMessage;

  @override
  Widget build(BuildContext context) {
    // Show loading when any bloc is loading
    if (isAnyBlocLoading(context)) {
      return const Center(child: AppProgressIndicator());
    }

    if (messageState is MessageError) {
      return AppEmptyState.error(
        message: (messageState as MessageError).message,
        onRetry: () {
          // Retry by reloading workspaces
          context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
        },
      );
    }
    // Handle MessageLoaded state
    if (messageState is MessageLoaded) {
      final loadedState = messageState as MessageLoaded;
      // Check if we have messages to display
      if (loadedState.messages.isEmpty) {
        return AppEmptyState.noMessages(
          onRetry: () {
            // Retry by reloading workspaces
            context.read<WorkspaceBloc>().add(const ws_events.LoadWorkspaces());
          },
        );
      }

      return SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: AppTable(
          selectAll: selectAll,
          onSelectAllChanged: (value) =>
              onToggleSelectAll(loadedState.messages.length, value: value),
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
          rows: loadedState.messages.map((message) {
            return AppTableRow(
              selected: selectedMessages.contains(message.id),
              onSelectChanged: (selected) =>
                  onToggleMessageSelection(message.id, value: selected),
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
                      onPressed: () => onViewDetail?.call(message.id),
                      size: AppIconButtonSize.small,
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      icon: AppIcons.reply,
                      tooltip: 'Reply',
                      onPressed: () => onReply?.call(message.id, message.conversationId),
                      size: AppIconButtonSize.small,
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      icon: AppIcons.download,
                      tooltip: 'Download',
                      onPressed: () => onDownloadMessage?.call(message.id),
                      size: AppIconButtonSize.small,
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
        ),
      );

      // Always show paginat
    }

    // Show initial state with progressive loading hints
    return AppEmptyState.loading();
  }
}
