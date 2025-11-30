import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Users',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        leading: AppIconButton(
          icon: AppIcons.back,
          onPressed: () => context.go(AppRoutes.dashboard),
          tooltip: 'Back to Dashboard',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.users,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Users Management',
                style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Manage system users',
                style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              AppButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.back, size: 18),
                    const SizedBox(width: 8),
                    const Text('Back to Dashboard'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
