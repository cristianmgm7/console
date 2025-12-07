import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        AppIcons.user,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}
