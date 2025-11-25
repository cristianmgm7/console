import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideNavigationBar extends StatelessWidget {
  const SideNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // App branding header
          Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.mic,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavigationItem(
                  icon: Icons.message,
                  label: 'Messages',
                  route: AppRoutes.dashboard,
                  isSelected: currentPath == AppRoutes.dashboard,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                _NavigationItem(
                  icon: Icons.mic,
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
            child: Material(
              color: currentPath == AppRoutes.settings
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.go(AppRoutes.settings),
                borderRadius: BorderRadius.circular(8),
                child: Tooltip(
                  message: 'Settings',
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
