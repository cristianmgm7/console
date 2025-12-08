import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationCoverArt extends StatelessWidget {
  const ConversationCoverArt({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, state) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: _buildCoverArt(state),
        );
      },
    );
  }

  Widget _buildCoverArt(ConversationState state) {
    if (state is ConversationLoaded) {
      // Find the conversation by ID
      final conversation = state.conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => const Conversation(
          id: '',
          name: '',
          workspaceId: '',
        ),
      );

      // If conversation found and has imageUrl, display it
      if (conversation.id.isNotEmpty && conversation.imageUrl != null && conversation.imageUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(3), // Slightly less than container border radius
          child: Image.network(
            conversation.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to conversation icon if image fails to load
              return Icon(
                AppIcons.conversation,
                size: 20,
                color: AppColors.textSecondary,
              );
            },
          ),
        );
      }
    }

    // Default: show conversation icon
    return Icon(
      AppIcons.conversation,
      size: 20,
      color: AppColors.textSecondary,
    );
  }
}
