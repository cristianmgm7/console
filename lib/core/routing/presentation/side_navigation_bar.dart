import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_routes.dart';

class SideNavigationBar extends StatefulWidget {
  const SideNavigationBar({super.key});

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();
}

class _SideNavigationBarState extends State<SideNavigationBar> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 250 : 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App branding header
          Container(
            padding: EdgeInsets.all(_isExpanded ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (_isExpanded) const Spacer(),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Carbon Voice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Console',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Expand/Collapse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: _isExpanded 
                        ? MainAxisAlignment.start 
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: 16),
                        Text(
                          'Collapse',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _NavigationItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: AppRoutes.dashboard,
                  isSelected: currentPath == AppRoutes.dashboard,
                  isExpanded: _isExpanded,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                _NavigationItem(
                  icon: Icons.mic,
                  label: 'Voice Memos',
                  route: AppRoutes.voiceMemos,
                  isSelected: currentPath == AppRoutes.voiceMemos,
                  isExpanded: _isExpanded,
                  onTap: () => context.go(AppRoutes.voiceMemos),
                ),
                _NavigationItem(
                  icon: Icons.people,
                  label: 'Users',
                  route: AppRoutes.users,
                  isSelected: currentPath == AppRoutes.users,
                  isExpanded: _isExpanded,
                  onTap: () => context.go(AppRoutes.users),
                ),
              ],
            ),
          ),
          // Bottom section - User/Settings
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: currentPath == AppRoutes.settings
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.go(AppRoutes.settings),
                borderRadius: BorderRadius.circular(8),
                child: Tooltip(
                  message: _isExpanded ? '' : 'Settings',
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: _isExpanded 
                          ? MainAxisAlignment.start 
                          : MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin User',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  'Settings',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.settings,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
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
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: isExpanded ? '' : label,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: isExpanded 
                    ? MainAxisAlignment.start 
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

