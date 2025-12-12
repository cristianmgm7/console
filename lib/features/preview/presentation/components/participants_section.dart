import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar_grid.dart';
import 'package:flutter/material.dart';

/// Component that displays the participants section with avatars
class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({
    required this.conversation,
    super.key,
  });

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final participants = _mapParticipants(conversation);

    return Column(
      children: [
        Text(
          'Participants',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ParticipantAvatarGrid(participants: participants),
      ],
    );
  }

  List<ParticipantAvatar> _mapParticipants(Conversation conversation) {
    if (conversation.collaborators == null || conversation.collaborators!.isEmpty) {
      return [];
    }

    return conversation.collaborators!.map((collaborator) {
      final fullName = '${collaborator.firstName ?? ''} ${collaborator.lastName ?? ''}'.trim();
      return ParticipantAvatar(
        id: collaborator.userGuid ?? 'unknown-user',
        fullName: fullName.isEmpty ? collaborator.userGuid ?? 'Unknown' : fullName,
        avatarUrl: collaborator.imageUrl,
      );
    }).toList();
  }
}
