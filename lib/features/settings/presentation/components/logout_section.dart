import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogoutSection extends StatelessWidget {
  const LogoutSection({super.key});

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          AppTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          AppButton(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.surface,
            onPressed: () {
              Navigator.pop(context);
              // Dispatch logout event to AuthBloc
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.error.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(
          AppIcons.logout,
          color: AppColors.error,
        ),
        title: Text(
          'Logout',
          style: AppTextStyle.bodyLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => _showLogoutConfirmation(context),
      ),
    );
  }
}
