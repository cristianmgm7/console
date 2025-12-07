import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:flutter/material.dart';

class UserProfileInfo extends StatelessWidget {
  const UserProfileInfo({
    required this.user,
    super.key,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          user.fullName,
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
