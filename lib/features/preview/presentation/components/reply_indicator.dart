import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Widget that displays a reply indicator showing which message this is a reply to
class ReplyIndicator extends StatelessWidget {
  const ReplyIndicator({
    required this.parentMessageText,
    this.isDarkTheme = false,
    super.key,
  });

  final String parentMessageText;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme
        ? AppColors.surface.withValues(alpha: 0.2)
        : AppColors.surface.withValues(alpha: 0.7);
    final borderColor = isDarkTheme
        ? AppColors.divider.withValues(alpha: 0.1)
        : AppColors.divider.withValues(alpha: 0.3);
    final iconColor = isDarkTheme
        ? AppColors.onPrimary.withValues(alpha: 0.7)
        : AppColors.primary.withValues(alpha: 0.7);
    final textColor = isDarkTheme
        ? AppColors.onPrimary.withValues(alpha: 0.7)
        : AppColors.textPrimary.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'This is a reply to: ${parentMessageText.length > 100 ? '${parentMessageText.substring(0, 100)}...' : parentMessageText}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
