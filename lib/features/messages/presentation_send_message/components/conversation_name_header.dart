import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationNameHeader extends StatelessWidget {
  const ConversationNameHeader({
    required this.channelId,
    super.key,
  });

  final String channelId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, state) {
        if (state is ConversationLoaded && state.selectedConversationIds.length == 1) {
          // Find conversation by channelId (which could be channelGuid or id)
          final conversations = state.conversations.where(
            (c) => c.channelGuid == channelId || c.id == channelId,
          );
          if (conversations.isNotEmpty) {
            final conversationName = conversations.first.name;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.message,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sending to: $conversationName',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
