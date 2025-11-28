import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_bloc.dart';
import 'package:flutter/material.dart';

class MessageDetailContent extends StatelessWidget {
  const MessageDetailContent({required this.state, super.key});

  final MessageDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildContentSection(),
          const SizedBox(height: 24),
          _buildMetadataSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID', message.id),
            _buildInfoRow('Creator', message.creatorId),
            _buildInfoRow('Created', _formatDate(message.createdAt)),
            _buildInfoRow('Duration', _formatDuration(message.duration)),
            _buildInfoRow('Status', message.status),
            _buildInfoRow('Type', message.type),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (message.transcriptText != null) ...[
              Text(
                'Transcript',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message.transcriptText!,
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
            if (message.text != null) ...[
              Text(
                'Text',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message.text!,
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (message.audioUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                'Audio URL',
                style: AppTextStyle.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              SelectableText(
                message.audioUrl!,
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final message = state.message;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (message.lastHeardAt != null)
              _buildInfoRow('Last Heard', _formatDate(message.lastHeardAt!)),
            if (message.heardDuration != null)
              _buildInfoRow('Heard Duration',
                  _formatDuration(message.heardDuration!),),
            if (message.totalHeardDuration != null)
              _buildInfoRow('Total Heard Duration',
                  _formatDuration(message.totalHeardDuration!),),
            if (message.lastUpdatedAt != null)
              _buildInfoRow('Last Updated',
                  _formatDate(message.lastUpdatedAt!),),
            _buildInfoRow('Workspace IDs',
                message.workspaceIds.join(', ')),
            _buildInfoRow('Channel IDs',
                message.channelIds.join(', ')),
            _buildInfoRow('Conversation ID', message.conversationId),
            _buildInfoRow('User ID', message.userId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period ${date.month}/${date.day}/${date.year % 100}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
