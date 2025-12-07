import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
            )
          : null,
      trailing: Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
