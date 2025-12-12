import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar_grid.dart';
import 'package:flutter/material.dart';

/// Component that displays the participants section with avatars
class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({
    required this.conversation,
    super.key,
  });

  final ConversationUiModel conversation;

  @override
  Widget build(BuildContext context) {
    final participants = _mapParticipants(conversation);

    return Column(
      children: [
        const SizedBox(height: 12),
        ParticipantAvatarGrid(participants: participants),
      ],
    );
  }

  List<ParticipantAvatar> _mapParticipants(ConversationUiModel conversation) {
    return conversation.participants.map((participant) {
      return ParticipantAvatar(
        id: participant.id,
        fullName: participant.fullName,
        avatarUrl: participant.avatarUrl,
      );
    }).toList();
  }
}
