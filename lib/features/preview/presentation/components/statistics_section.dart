import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:flutter/material.dart';

/// Component that displays conversation statistics (messages, duration, participants)
class StatisticsSection extends StatelessWidget {
  const StatisticsSection({
    required this.conversation,
    super.key,
  });

  final ConversationUiModel conversation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message count
        _buildStatItem(
          context,
          icon: Icons.message_outlined,
          label: 'Messages',
          value: conversation.totalMessages.toString(),
        ),
        const SizedBox(width: 24),

        // Total duration
        _buildStatItem(
          context,
          icon: Icons.access_time,
          label: 'Duration',
          value: conversation.totalDurationFormatted,
        ),
        const SizedBox(width: 24),

        // Participants count
        _buildStatItem(
          context,
          icon: Icons.people_outline,
          label: 'Participants',
          value: conversation.participantCount.toString(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ],
    );
  }
}
