import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_event.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_state.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays a single message in the preview visualization
class PreviewMessageItem extends StatelessWidget {
  const PreviewMessageItem({
    required this.message,
    required this.participants,
    super.key,
  });

  final MessageUiModel message;
  final List<ConversationParticipantUiModel> participants;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,

      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _getCreatorParticipant().avatarUrl != null
                  ? NetworkImage(_getCreatorParticipant().avatarUrl!)
                  : null,
              child: _getCreatorParticipant().avatarUrl == null
                  ? Text(
                      _getInitials(_getCreatorParticipant().fullName),
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator name and timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCreatorName(),
                        style: AppTextStyle.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateTimeFormatters.formatDate(message.createdAt),
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Duration and audio controls
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeFormatters.formatDuration(message.duration),
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (message.hasPlayableAudio) ...[
                        const SizedBox(width: 12),
                        BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                          builder: (context, audioState) {
                            final isCurrentMessage = audioState is AudioPlayerReady && audioState.messageId == message.id;
                            final isPlaying = isCurrentMessage && audioState.isPlaying;

                            return IconButton(
                              onPressed: () {
                                final bloc = context.read<AudioPlayerBloc>();
                                if (isPlaying) {
                                  bloc.add(const PauseAudio());
                                } else if (isCurrentMessage) {
                                  bloc.add(const PlayAudio());
                                } else {
                                  final audioModel = message.playableAudioModel;
                                  if (audioModel != null) {
                                    bloc.add(LoadAudio(
                                      messageId: message.id,
                                      waveformData: audioModel.waveformData,
                                    ));
                                    bloc.add(const PlayAudio());
                                  }
                                }
                              },
                              icon: Icon(
                                isPlaying ? Icons.pause_circle : Icons.play_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Message summary/text
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: AppTextStyle.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Collaborators info
                  if (participants.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Collaborators: ${_getCollaboratorsText(participants)}',
                            style: AppTextStyle.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
      (p) => p.id == message.creatorId,
      orElse: () => ConversationParticipantUiModel(
        id: message.creatorId,
        fullName: message.creatorId, // fallback to ID if not found
        avatarUrl: null,
      ),
    );
  }

  String _getCreatorName() {
    return _getCreatorParticipant().fullName;
  }

  String _getCollaboratorsText(List<ConversationParticipantUiModel> participants) {
    // Exclude the message creator from collaborators
    final collaborators = participants
        .where((p) => p.id != message.creatorId)
        .map((p) => p.fullName)
        .toList();

    if (collaborators.isEmpty) return 'None';
    if (collaborators.length <= 2) {
      return collaborators.join(', ');
    } else {
      return '${collaborators.take(2).join(', ')} +${collaborators.length - 2} more';
    }
  }
}
