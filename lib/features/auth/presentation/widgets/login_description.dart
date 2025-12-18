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
          const SizedBox(height: 24),
          Text(
            'The Carbon Voice Downloader lets you:',
            style: AppTextStyle.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    const features = [
      'Find messages across conversations',
      'Select multiple messages',
      'Download audio, transcripts, and more',
      'Send text messages into a conversation',
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: features.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '• ',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
