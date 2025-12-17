import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_workspace_section.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/dashboard_sidebar/sidebar_conversation_list.dart';
import 'package:flutter/material.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  static const double sidebarWidth = 280;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: sidebarWidth,
      child: AppContainer(
        backgroundColor: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            // Workspace selector at top
            SidebarWorkspaceSection(),

            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),

            // Conversation list fills remaining space
            Expanded(
              child: SidebarConversationList(),
            ),
          ],
        ),
      ),
    );
  }
}
