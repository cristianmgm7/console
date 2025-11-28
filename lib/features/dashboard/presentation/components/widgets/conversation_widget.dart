import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:flutter/material.dart';

class ConversationWidget extends StatelessWidget {
  const ConversationWidget({
    required this.conversation, required this.onRemove, super.key,
  });

  final Conversation conversation;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: AppPillContainer(
        backgroundColor: AppColors.surface.withValues(alpha: 0.5),
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                conversation.name,
                style: AppTextStyle.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            AppIconButton(
              icon: AppIcons.close,
              onPressed: onRemove,
              size: AppIconButtonSize.small,
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
