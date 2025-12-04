import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReplyMessageHeader extends StatelessWidget {
  const ReplyMessageHeader({
    required this.replyToMessageId,
    this.onCancelReply,
    super.key,
  });

  final String? replyToMessageId;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    if (replyToMessageId == null) return const SizedBox.shrink();

    return BlocBuilder<MessageBloc, MessageState>(
      key: ValueKey(replyToMessageId), // Force rebuild when replyToMessageId changes
      builder: (context, state) {
        String? messagePreview;
        if (state is MessageLoaded) {
          final messages = state.messages.where((m) => m.id == replyToMessageId);
          if (messages.isNotEmpty) {
            final message = messages.first;
            // Get preview of the message text (first 50 characters)
            String textPreview;
            if (message.text != null && message.text!.isNotEmpty) {
              textPreview = message.text!.trim();
            } else if (message.transcriptText != null && message.transcriptText!.isNotEmpty) {
              textPreview = message.transcriptText!.trim();
            } else if (message.textModels.isNotEmpty && message.textModels.first.text.isNotEmpty) {
              textPreview = message.textModels.first.text.trim();
            } else if (message.isTextMessage) {
              textPreview = 'Text message';
            } else {
              textPreview = 'Voice message';
            }

            messagePreview = textPreview.length > 50
                ? '${textPreview.substring(0, 50)}...'
                : textPreview;
          } else {
            messagePreview = 'Message not found';
          }
        }

        return Container(
          width: 465,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.reply,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  messagePreview ?? 'Loading...',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onCancelReply ?? () {},
                icon: Icon(
                  AppIcons.close,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                tooltip: 'Cancel reply',
              ),
            ],
          ),
        );
      },
    );
  }
}
