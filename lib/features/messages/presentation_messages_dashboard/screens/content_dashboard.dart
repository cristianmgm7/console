import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_search_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/audio_mini_player_positioned.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/download_progress_indicator.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/message_composition_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_action_panel_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/messages_content_container.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_content/pagination_controls_wrapper.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/dashboard_sidebar.dart';
import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    required this.isAnyBlocLoading,
    super.key,
  });

  final bool Function(BuildContext context) isAnyBlocLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left sidebar
        const DashboardSidebar(),

        // Main content area
        Expanded(
          child: AppContainer(
            backgroundColor: AppColors.surface,
            child: Stack(
              children: [
                MessagesContentContainer(isAnyBlocLoading: isAnyBlocLoading),
                const DownloadProgressIndicator(),
                const ConversationSearchPanelWrapper(),
                const MessagesActionPanelWrapper(),
                const PaginationControlsWrapper(),
                const AudioMiniPlayerPositioned(),
                const MessageCompositionPanelWrapper(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
