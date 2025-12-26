import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/routing/navigation_item.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/navigation/user_profile_button.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideNavigationBar extends StatelessWidget {
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return SizedBox(
      width: 80,
      child: AppContainer(
        
        backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                NavigationItem(
                  icon: AppIcons.message,
                  label: 'Messages',
                  route: AppRoutes.dashboard,
                  isSelected: currentPath == AppRoutes.dashboard,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                NavigationItem(
                  icon: AppIcons.mic,
                  label: 'Voice Memos',
                  route: AppRoutes.voiceMemos,
                  isSelected: currentPath == AppRoutes.voiceMemos,
                  onTap: () => context.go(AppRoutes.voiceMemos),
                ),
                NavigationItem(
                  icon: AppIcons.sparkles, // or AppIcons.robot if available
                  label: 'Agent Chat',
                  route: AppRoutes.agentChat,
                  isSelected: currentPath == AppRoutes.agentChat,
                  onTap: () => context.go(AppRoutes.agentChat),
                ),
              ],
            ),
          ),
          // Bottom section - User/Settings
          const Divider(height: 1),
          UserProfileButton(
            isSelected: currentPath == AppRoutes.settings,
          ),
        ],
      ),
    ),
    );
  }
}
