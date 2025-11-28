import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/widgets/audio_player_sheet.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart' as ws_events;
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
    super.key,
  });

  final ScrollController scrollController;
  final Set<String> selectedMessages;
  final void Function(String, {bool? value}) onToggleMessageSelection;
  final void Function(int length, {bool? value}) onToggleSelectAll;
  final bool selectAll;
  final bool Function(BuildContext context) isAnyBlocLoading;
  final ValueChanged<String>? onViewDetail;

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

  Future<void> _handlePlayAudio(BuildContext context, MessageUiModel message) async {
    if (!message.hasPlayableAudio || message.audioUrl == null) return;

    // Get the audio player BLoC
    final audioBloc = context.read<AudioPlayerBloc>();

    // Load audio
    audioBloc.add(LoadAudio(
      messageId: message.id,
      audioUrl: message.audioUrl!,
      waveformData: message.playableAudioModel?.waveformData ?? [],
    ),);

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
      child: BlocBuilder<MessageBloc, MessageState>(
        builder: (context, messageState) {
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
            onSelectAllChanged: (value) => onToggleSelectAll(messageState.messages.length, value: value),
            columns: const [
              AppTableColumn(
                title: 'Date',
                width: FixedColumnWidth(120),
              ),
              AppTableColumn(
                title: 'Owner',
                width: FixedColumnWidth(140),
              ),
              AppTableColumn(
                title: 'Message',
                width: FlexColumnWidth(),
              ),
              AppTableColumn(
                title: 'Duration',
                width: FixedColumnWidth(60),
              ),
              AppTableColumn(
                title: 'Status',
                width: FixedColumnWidth(90),
              ),
              AppTableColumn(
                title: '',
                width: FixedColumnWidth(56),
              ),
            ],
            rows: messageState.messages.map((message) {
              return AppTableRow(
                selected: selectedMessages.contains(message.id),
                onSelectChanged: (selected) => onToggleMessageSelection(message.id, value: selected),
                cells: [
                  // Date
                  Text(
                    _formatDate(message.createdAt),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        message.text ?? 'No content',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Duration
                  Row(
                    children: [
                      if (message.hasPlayableAudio) ...[
                        AppIconButton(
                          icon: AppIcons.play,
                          tooltip: 'Play audio',
                          onPressed: () => _handlePlayAudio(context, message),
                          foregroundColor: AppColors.primary,
                          size: AppIconButtonSize.small,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _formatDuration(message.duration),
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Status
                  Text(
                    'Active', // You can customize this based on message status
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Menu
                  PopupMenuButton(
                    icon: Icon(AppIcons.moreVertical, color: AppColors.textSecondary, size: 20),
                    itemBuilder: (context) => [
                      AppPopupMenuItem.standard(
                        value: 'view',
                        icon: AppIcons.eye,
                        text: 'View Details',
                      ),
                      AppPopupMenuItem.standard(
                        value: 'edit',
                        icon: AppIcons.edit,
                        text: 'Edit',
                      ),
                      AppPopupMenuItem.standard(
                        value: 'download',
                        icon: AppIcons.download,
                        text: 'Download',
                      ),
                      AppPopupMenuItem.standard(
                        value: 'archive',
                        icon: AppIcons.archive,
                        text: 'Archive',
                      ),
                      AppPopupMenuItem.destructive(
                        value: 'delete',
                        icon: AppIcons.delete,
                        text: 'Delete',
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onViewDetail?.call(message.id);
                        // TODO: Implement other menu actions
                      }
                    },
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
      },
    ),);
  }
}
