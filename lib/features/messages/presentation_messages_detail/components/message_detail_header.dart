import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/widgets/user_info_widget.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:flutter/material.dart';

class MessageDetailHeader extends StatelessWidget {
  const MessageDetailHeader({
    required this.message,
    required this.user,
    required this.onClose,
    super.key,
  });

  final MessageUiModel message;
  final User user;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.gradientHeader,
      borderRadius: BorderRadius.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button and user info in the same row
          Row(
            children: [
              Expanded(
                child: UserInfoWidget(user: user),
              ),
              AppIconButton(
                icon: AppIcons.close,
                onPressed: onClose,
                tooltip: 'Close',
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 16),
          // Duration and send time
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.access_time,
                label: _formatDuration(message.audioModels.first.duration),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.send,
                label: _formatDate(message.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
