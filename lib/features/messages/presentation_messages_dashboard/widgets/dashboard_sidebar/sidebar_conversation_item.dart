import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';

class SidebarConversationItem extends StatelessWidget {
  const SidebarConversationItem({
    required this.conversation,
    required this.isSelected,
    required this.colorIndex,
    required this.onTap,
    super.key,
  });

  final Conversation conversation;
  final bool isSelected;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: AppContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: isSelected ? AppColors.cardBackground : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          child: Row(
            children: [
              // Selection indicator
              Icon(
                isSelected ? AppIcons.check : AppIcons.add,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),

              // Conversation name
              Expanded(
                child: Text(
                  conversation.channelName ?? 'Unknown',
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Unread count badge (if any)
            if (conversation.unreadCount != null && conversation.unreadCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
