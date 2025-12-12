import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar.dart';
import 'package:flutter/material.dart';

/// Displays participant avatars and names in a grid layout
class ParticipantAvatarGrid extends StatelessWidget {
  const ParticipantAvatarGrid({
    required this.participants,
    super.key,
  });

  final List<ParticipantAvatar> participants;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: participants.map((participant) {
        return _buildParticipantItem(context, participant);
      }).toList(),
    );
  }

  Widget _buildParticipantItem(
    BuildContext context,
    ParticipantAvatar participant,
  ) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: participant.avatarUrl != null
                ? NetworkImage(participant.avatarUrl!)
                : null,
            child: participant.avatarUrl == null
                ? Text(
                    _getInitials(participant.fullName),
                    style: AppTextStyle.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            participant.fullName,
            style: AppTextStyle.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
