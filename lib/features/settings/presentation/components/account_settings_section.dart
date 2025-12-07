import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';

class AccountSettingsSection extends StatelessWidget {
  const AccountSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          SettingsListTile(
            icon: AppIcons.user,
            title: 'Edit Profile',
            onTap: null, // TODO: Implement edit profile
          ),
          const Divider(height: 1),
          SettingsListTile(
            icon: AppIcons.lock,
            title: 'Change Password',
            onTap: null, // TODO: Implement change password
          ),
        ],
      ),
    );
  }
}
