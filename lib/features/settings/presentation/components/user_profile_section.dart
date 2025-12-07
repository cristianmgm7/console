import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/user_profile_avatar.dart';
import 'package:carbon_voice_console/features/settings/presentation/widgets/user_profile_info.dart';
import 'package:flutter/material.dart';

class UserProfileSection extends StatelessWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            UserProfileAvatar(),
            SizedBox(height: 16),
            UserProfileInfo(),
          ],
        ),
      ),
    );
  }
}
