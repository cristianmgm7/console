import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/cubit/message_detail_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesContent extends StatelessWidget {
  const MessagesContent({
    required this.messageState,
    required this.audioState,
    required this.isAnyBlocLoading,
    super.key,
  });

  final MessageState messageState;
  final AudioPlayerState audioState;
  final bool Function(BuildContext context) isAnyBlocLoading;

  // All callbacks removed - use Cubits directly

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
          child: BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
            builder: (context, selectionState) {
              return AppTable(
                selectAll: selectionState.selectAll,
                onSelectAllChanged: (value) {
                  context.read<MessageSelectionCubit>().toggleSelectAll(
                    loadedState.messages.map((m) => m.id).toList(),
                    value: value,
                  );
                },
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
                    selected: selectionState.selectedMessageIds.contains(message.id),
                    onSelectChanged: (selected) {
                      context.read<MessageSelectionCubit>().toggleMessage(
                        message.id,
                        value: selected,
                      );
                    },
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
                      onPressed: () {
                        context.read<MessageDetailCubit>().openDetail(message.id);
                      },
                      size: AppIconButtonSize.small,
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      icon: AppIcons.reply,
                      tooltip: 'Reply',
                      onPressed: () {
                        final workspaceState = context.read<WorkspaceBloc>().state;
                        if (workspaceState is WorkspaceLoaded &&
                            workspaceState.selectedWorkspace != null) {
                          context.read<MessageCompositionCubit>().openReply(
                            workspaceId: workspaceState.selectedWorkspace!.id,
                            channelId: message.conversationId,
                            replyToMessageId: message.id,
                          );
                        }
                      },
                      size: AppIconButtonSize.small,
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      icon: AppIcons.download,
                      tooltip: 'Download',
                      onPressed: () {
                        context.read<DownloadBloc>().add(StartDownloadAudio({message.id}));
                      },
                      size: AppIconButtonSize.small,
                    ),
                    ],
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
        ),
      );

      // Always show paginat
    }

    // Show initial state with progressive loading hints
    return AppEmptyState.loading();
  }
}
