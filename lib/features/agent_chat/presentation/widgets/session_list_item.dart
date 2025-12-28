import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';

class SessionListItem extends StatelessWidget {

  const SessionListItem({
    required this.sessionId,
    required this.title,
    required this.preview,
    required this.lastMessageTime,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    super.key,
  });
  final String sessionId;
  final String title;
  final String preview;
  final DateTime lastMessageTime;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
      title: Text(
        title,
        style: AppTextStyle.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            preview,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(lastMessageTime),
            style: AppTextStyle.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(AppIcons.delete, size: 18),
        color: AppColors.error,
        onPressed: onDelete,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
