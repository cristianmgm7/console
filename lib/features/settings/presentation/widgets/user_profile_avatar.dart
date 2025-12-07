import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:flutter/material.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    required this.user,
    super.key,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 40,
      backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: hasAvatar
          ? null
          : Icon(
              AppIcons.user,
              size: 40,
              color: AppColors.primary,
            ),
    );
  }
}
