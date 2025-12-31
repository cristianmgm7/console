import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/chat_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget { // For agent messages (icon name)

  const ChatMessageBubble({
    required this.content,
    required this.role,
    required this.timestamp,
    this.subAgentName,
    this.subAgentIcon,
    super.key,
  });
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? subAgentName; // For agent messages
  final String? subAgentIcon;

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                _getIconData(subAgentIcon) ?? AppIcons.sparkles,
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
                padding: const EdgeInsets.all(16),
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

                    // Message text with markdown support
                    MarkdownBody(
                      data: content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        h1: AppTextStyle.headlineLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: AppTextStyle.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: AppTextStyle.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        h4: AppTextStyle.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        h5: AppTextStyle.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        h6: AppTextStyle.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.bold),
                        em: const TextStyle(fontStyle: FontStyle.italic),
                        codeblockPadding: const EdgeInsets.all(12),
                        code: AppTextStyle.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          backgroundColor: AppColors.surface,
                          color: AppColors.textPrimary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        listBullet: AppTextStyle.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
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
    return '$hour:${timestamp.minute.toString().padLeft(2, '0')} $period';
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
