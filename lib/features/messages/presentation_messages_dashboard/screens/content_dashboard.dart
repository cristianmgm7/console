import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/audio_mini_player_positioned.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/download_progress_indicator.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/message_composition_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_action_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_content_container.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/pagination_controls_wrapper.dart';
import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AppContainer(
      backgroundColor: AppColors.surface,
      child: Stack(
        children: [
          MessagesContentContainer(isAnyBlocLoading: isAnyBlocLoading),
          const DownloadProgressIndicator(),
          const MessagesActionPanelWrapper(),
          PaginationControlsWrapper(
            onLoadMore: onManualLoadMore,
            hasMore: hasMoreMessages,
            isLoading: isLoadingMore,
          ),
          const AudioMiniPlayerPositioned(),
          const MessageCompositionPanelWrapper(),
        ],
      ),
    );
  }
}
