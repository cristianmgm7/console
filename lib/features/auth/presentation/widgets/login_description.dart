import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

class LoginDescription extends StatelessWidget {
  const LoginDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Carbon Voice Downloader',
                  style: AppTextStyle.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Carbon Voice users recording async podcasts, radio station liners, or other discussions where they need the audio or transcript across many messages.',
                  style: AppTextStyle.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
