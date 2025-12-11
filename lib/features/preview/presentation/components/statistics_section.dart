import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:flutter/material.dart';

/// Component that displays conversation statistics (messages, duration, participants)
class StatisticsSection extends StatelessWidget {
  const StatisticsSection({
    required this.previewUiModel,
    super.key,
  });

  final PreviewUiModel previewUiModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Message count
        _buildStatItem(
          context,
          icon: Icons.message_outlined,
          label: 'Messages',
          value: previewUiModel.messageCount.toString(),
        ),
        const SizedBox(width: 24),

        // Total duration
        _buildStatItem(
          context,
          icon: Icons.access_time,
          label: 'Duration',
          value: previewUiModel.totalDurationFormatted,
        ),
        const SizedBox(width: 24),

        // Participants count
        _buildStatItem(
          context,
          icon: Icons.people_outline,
          label: 'Participants',
          value: previewUiModel.participants.length.toString(),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
