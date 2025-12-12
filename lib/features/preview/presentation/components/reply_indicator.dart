import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Widget that displays a reply indicator showing which message this is a reply to
class ReplyIndicator extends StatelessWidget {
  const ReplyIndicator({
    required this.parentMessageText,
    super.key,
  });

  final String parentMessageText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),  
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This is a reply to: ${parentMessageText.length > 100 ? '${parentMessageText.substring(0, 100)}...' : parentMessageText}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
