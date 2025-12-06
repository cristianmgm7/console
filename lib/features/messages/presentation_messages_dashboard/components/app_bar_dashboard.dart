import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_search_button.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/conversation_selector_section.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/dashboard_title.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/selected_conversations_section.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/send_message_button.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/app_bar/workspace_section.dart';
import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.surface,
      borderRadius: BorderRadius.zero,
      border: Border(
        bottom: BorderSide(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          DashboardTitle(),
          SizedBox(width: 16),
          WorkspaceSection(),
          SizedBox(width: 16),
          ConversationSelectorSection(),
          SizedBox(width: 8),
          ConversationSearchButton(),
          SizedBox(width: 16),
          SelectedConversationsSection(),
          SendMessageButton(),
        ],
      ),
    );
  }
}
