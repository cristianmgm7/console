import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/auth/presentation/widgets/login_description.dart';
import 'package:carbon_voice_console/features/auth/presentation/widgets/login_features_section.dart';
import 'package:flutter/material.dart';

class LoginBrandingSection extends StatelessWidget {
  const LoginBrandingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const LoginDescription(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text('How it works', style: AppTextStyle.headlineSmall),
        ),
        const SizedBox(height: 8),
        const LoginFeaturesSection(),
      ],
    );
  }
}
