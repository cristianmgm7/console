import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideNavigationBar extends StatelessWidget {
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return SizedBox(
      width: 72,
      child: AppContainer(
        backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // App branding header
          AppContainer(
            padding: const EdgeInsets.all(16),
            child: Icon(
              AppIcons.mic,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavigationItem(
                  icon: AppIcons.message,
                  label: 'Messages',
                  route: AppRoutes.dashboard,
                  isSelected: currentPath == AppRoutes.dashboard,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                _NavigationItem(
                  icon: AppIcons.mic,
                  label: 'Voice Memos',
                  route: AppRoutes.voiceMemos,
                  isSelected: currentPath == AppRoutes.voiceMemos,
                  onTap: () => context.go(AppRoutes.voiceMemos),
                ),
              ],
            ),
          ),
          // Bottom section - User/Settings
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppContainer(
              backgroundColor: currentPath == AppRoutes.settings
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: AppIconButton(
                icon: AppIcons.user,
                onPressed: () => context.go(AppRoutes.settings),
                tooltip: 'Settings',
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                size: AppIconButtonSize.medium,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _NavigationItem extends StatelessWidget {

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: AppContainer(
        backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: AppIconButton(
          icon: icon,
          onPressed: onTap,
          tooltip: label,
          backgroundColor: Colors.transparent,
          foregroundColor: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: AppIconButtonSize.medium,
        ),
      ),
    );
  }
}
