import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar_grid.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_message_item.dart';
import 'package:flutter/material.dart';

/// Widget that visualizes how the preview will look to end users
/// Displays conversation metadata, participants, statistics, and messages
class PreviewVisualization extends StatelessWidget {
  const PreviewVisualization({
    required this.preview,
    super.key,
  });

  final PreviewUiModel preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Preview',
              style: AppTextStyle.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is how your conversation preview will appear',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Conversation header section
            _buildConversationHeader(context),
            const SizedBox(height: 24),

            // Statistics section
            _buildStatistics(context),
            const SizedBox(height: 24),

            // Participants section
            if (preview.participants.isNotEmpty) ...[
              _buildParticipantsSection(context),
              const SizedBox(height: 24),
            ],

            // Messages section
            _buildMessagesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        if (preview.conversationCoverUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(preview.conversationCoverUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (preview.conversationCoverUrl != null) const SizedBox(height: 16),

        // Conversation name
        Text(
          preview.conversationName,
          style: AppTextStyle.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Conversation description
        if (preview.conversationDescription.isNotEmpty)
          Text(
            preview.conversationDescription,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Row(
      children: [
        // Message count
        _buildStatItem(
          context,
          icon: Icons.message_outlined,
          label: 'Messages',
          value: preview.messageCount.toString(),
        ),
        const SizedBox(width: 24),

        // Total duration
        _buildStatItem(
          context,
          icon: Icons.access_time,
          label: 'Duration',
          value: preview.totalDurationFormatted,
        ),
        const SizedBox(width: 24),

        // Participants count
        _buildStatItem(
          context,
          icon: Icons.people_outline,
          label: 'Participants',
          value: preview.participants.length.toString(),
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

  Widget _buildParticipantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ParticipantAvatarGrid(participants: preview.participants),
      ],
    );
  }

  Widget _buildMessagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Messages',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...preview.messages.map((message) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PreviewMessageItem(message: message),
          );
        }),
      ],
    );
  }
}
