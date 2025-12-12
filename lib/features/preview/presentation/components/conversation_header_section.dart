import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/participants_section.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/statistics_section.dart';
import 'package:flutter/material.dart';

/// Component that displays the conversation header with cover image, name, and description
/// Uses a 2x2 GridView layout: top-left(cover), top-right(title), bottom-left(stats), bottom-right(participants)
class ConversationHeaderSection extends StatelessWidget {
  const ConversationHeaderSection({
    required this.conversation,
    super.key,
  });

  final ConversationUiModel conversation;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 32,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Top-left: Cover art
        if (conversation.coverImageUrl != null)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(conversation.coverImageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        // Top-right: Title and description
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversation name
            Text(
              conversation.name,
              style: AppTextStyle.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Conversation description
            if (conversation.description.isNotEmpty)
              Text(
                conversation.description,
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),

        // Bottom-left: Statistics section
        StatisticsSection(
          conversation: conversation,
        ),

        // Bottom-right: Participants section
        if (conversation.hasParticipants)
          ParticipantsSection(conversation: conversation)
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
