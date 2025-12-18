import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

class LoginFeaturesSection extends StatelessWidget {
  const LoginFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: _buildFeatureList(),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      FeatureData(
        icon: AppIcons.search,
        text: 'Find messages across conversations',
      ),
      FeatureData(
        icon: AppIcons.listChecks,
        text: 'Select multiple messages',
      ),
      FeatureData(
        icon: AppIcons.fileDownload,
        text: 'Download audio, transcripts, and more',
      ),
      FeatureData(
        icon: AppIcons.textMessage,
        text: 'Send text messages into a conversation',
      ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.expand((feature) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: FeatureItem(
            icon: feature.icon,
            text: feature.text,
          ),
        ),
        if (feature != features.last)
          Divider(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            thickness: 1,
          ),
      ]).toList(),
    );
  }
}

class FeatureItem extends StatelessWidget {
  const FeatureItem({
    required this.icon, required this.text, super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class FeatureData {
  const FeatureData({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;
}
