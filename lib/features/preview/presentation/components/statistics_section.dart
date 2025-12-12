import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:flutter/material.dart';

/// Component that displays conversation statistics (messages, duration, participants)
class StatisticsSection extends StatelessWidget {
  const StatisticsSection({
    required this.messages,
    required this.conversation,
    super.key,
  });

  final List<MessageUiModel> messages;
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final totalDuration = messages.fold<Duration>(
      Duration.zero,
      (sum, message) => sum + message.duration,
    );

    return Row(
      children: [
        // Message count
        _buildStatItem(
          context,
          icon: Icons.message_outlined,
          label: 'Messages',
          value: messages.length.toString(),
        ),
        const SizedBox(width: 24),

        // Total duration
        _buildStatItem(
          context,
          icon: Icons.access_time,
          label: 'Duration',
          value: _formatDuration(totalDuration),
        ),
        const SizedBox(width: 24),

        // Participants count
        _buildStatItem(
          context,
          icon: Icons.people_outline,
          label: 'Participants',
          value: (conversation.collaborators?.length ?? 0).toString(),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
