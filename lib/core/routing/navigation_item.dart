import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class NavigationItem extends StatelessWidget {

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
    super.key, 
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
        ),
      ),
    );
  }
}
