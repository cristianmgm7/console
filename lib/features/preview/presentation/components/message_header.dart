import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:flutter/material.dart';

/// Header component displaying user avatar and name for a message
class MessageHeader extends StatelessWidget {
  const MessageHeader({
    required this.participants,
    required this.creatorId,
    super.key,
  });

  final List<ConversationParticipantUiModel> participants;
  final String creatorId;

  @override
  Widget build(BuildContext context) {
    final creator = _getCreatorParticipant();

    return Row(
      children: [
        // Creator avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: creator.avatarUrl != null
              ? NetworkImage(creator.avatarUrl!)
              : null,
          child: creator.avatarUrl == null
              ? Text(
                  _getInitials(creator.fullName),
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Creator name
        Text(
          creator.fullName,
          style: AppTextStyle.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  ConversationParticipantUiModel _getCreatorParticipant() {
    // Find creator from participants list
    return participants.firstWhere(
      (p) => p.id == creatorId,
      orElse: () => ConversationParticipantUiModel(
        id: creatorId,
        fullName: creatorId, // fallback to ID if not found
        avatarUrl: null,
      ),
    );
  }
}
