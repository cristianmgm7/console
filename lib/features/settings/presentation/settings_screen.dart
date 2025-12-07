import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:carbon_voice_console/features/settings/presentation/components/account_settings_section.dart';
import 'package:carbon_voice_console/features/settings/presentation/components/general_settings_section.dart';
import 'package:carbon_voice_console/features/settings/presentation/components/logout_section.dart';
import 'package:carbon_voice_console/features/settings/presentation/components/user_profile_section.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/section_title.dart';
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
          children: const [
            // User Profile Section
            UserProfileSection(),
            SizedBox(height: 24),

            // General Settings Section
            SectionTitle(title: 'General'),
            SizedBox(height: 8),
            GeneralSettingsSection(),
            SizedBox(height: 24),

            // Account Settings Section
            SectionTitle(title: 'Account'),
            SizedBox(height: 8),
            AccountSettingsSection(),
            SizedBox(height: 24),

            // Logout Section
            LogoutSection(),
          ],
        ),
      ),
    );
  }
}
