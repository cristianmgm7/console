import 'package:flutter/material.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? subAgentName; // For agent messages
  final String? subAgentIconName; // For agent messages (icon name)

  const ChatMessageBubble({
    required this.content,
    required this.role,
    required this.timestamp,
    this.subAgentName,
    this.subAgentIconName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Agent avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getIconData(subAgentIconName) ?? AppIcons.sparkles,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Message content
          Flexible(
            child: GlassContainer(
              opacity: 0.3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser && subAgentName != null) ...[
                      Text(
                        subAgentName!,
                        style: AppTextStyle.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Message text (TODO: Add markdown support in Phase 5)
                    Text(
                      content,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Timestamp
                    Text(
                      _formatTimestamp(timestamp),
                      style: AppTextStyle.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                AppIcons.user,
                size: 20,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }

  IconData? _getIconData(String? iconName) {
    if (iconName == null) return null;

    switch (iconName) {
      case 'github_logo':
        return AppIcons.sparkles; // Use sparkles for GitHub
      case 'chart_line':
        return AppIcons.sparkles; // Use sparkles for charts
      case 'chat':
        return AppIcons.message;
      default:
        return AppIcons.sparkles;
    }
  }
}
