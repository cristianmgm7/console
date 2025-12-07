import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

class UserProfileInfo extends StatelessWidget {
  const UserProfileInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Admin User',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'admin@carbonvoice.com',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
