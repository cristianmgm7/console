import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/widgets/session_list_item.dart';

class SessionListSidebar extends StatelessWidget {
  const SessionListSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          // Header with "New Chat" button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppButton(
              onPressed: () {
                // TODO: Create new session
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.add, size: 18),
                  const SizedBox(width: 8),
                  const Text('New Chat'),
                ],
              ),
            ),
          ),

          const Divider(),

          // Session list
          Expanded(
            child: ListView.builder(
              itemCount: 0, // TODO: Connect to BLoC state
              itemBuilder: (context, index) {
                // TODO: Implement SessionListItem in Phase 2
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
