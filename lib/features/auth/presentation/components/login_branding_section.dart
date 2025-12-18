import 'package:carbon_voice_console/features/auth/presentation/widgets/login_description.dart';
import 'package:carbon_voice_console/features/auth/presentation/widgets/login_features_section.dart';
import 'package:carbon_voice_console/features/auth/presentation/widgets/login_title.dart';
import 'package:flutter/material.dart';

class LoginBrandingSection extends StatelessWidget {
  const LoginBrandingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoginTitle(),
        SizedBox(height: 32),
        LoginDescription(),
        SizedBox(height: 24),
        LoginFeaturesSection(),
      ],
    );
  }
}
