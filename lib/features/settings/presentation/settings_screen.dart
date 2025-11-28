import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Navigate to login when logged out
        if (state is LoggedOut || state is Unauthenticated) {
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Settings',
            style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surface,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // User Profile Section
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        AppIcons.user,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            Text(
              'General',
              style: AppTextStyle.titleSmall.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(AppIcons.bell, color: AppColors.textSecondary),
                  title: Text(
                    'Notifications',
                    style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  trailing: AppSwitch(
                    value: true,
                    onChanged: (value) {
                      // TODO: Implement notifications toggle
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(AppIcons.globe, color: AppColors.textSecondary),
                  title: Text(
                    'Language',
                    style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'English',
                    style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
                  onTap: () {
                    // TODO: Implement language selection
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(AppIcons.palette, color: AppColors.textSecondary),
                  title: Text(
                    'Theme',
                    style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'System default',
                    style: AppTextStyle.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
                  onTap: () {
                    // TODO: Implement theme selection
                  },
                ),
              ],
            ),
          ),
            const SizedBox(height: 24),

            // Account Section
            Text(
              'Account',
              style: AppTextStyle.titleSmall.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(AppIcons.user, color: AppColors.textSecondary),
                  title: Text(
                    'Edit Profile',
                    style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  trailing: Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
                  onTap: () {
                    // TODO: Implement edit profile
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(AppIcons.lock, color: AppColors.textSecondary),
                  title: Text(
                    'Change Password',
                    style: AppTextStyle.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  trailing: Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
                  onTap: () {
                    // TODO: Implement change password
                  },
                ),
              ],
            ),
          ),
            const SizedBox(height: 24),

            // Logout Button
            AppCard(
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
                onTap: () async {
                  // Show confirmation dialog
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
