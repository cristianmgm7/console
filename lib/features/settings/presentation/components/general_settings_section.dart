import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:flutter/material.dart';

class GeneralSettingsSection extends StatelessWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          SettingsSwitchTile(
            icon: AppIcons.bell,
            title: 'Notifications',
            value: true,
            onChanged: null, // TODO: Implement notifications toggle
          ),
          const Divider(height: 1),
          SettingsListTile(
            icon: AppIcons.globe,
            title: 'Language',
            subtitle: 'English',
          ),
          const Divider(height: 1),
          SettingsListTile(
            icon: AppIcons.palette,
            title: 'Theme',
            subtitle: 'System default',
          ),
        ],
      ),
    );
  }
}
