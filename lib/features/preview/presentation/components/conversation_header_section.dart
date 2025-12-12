import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/domain/entities/conversation_entity.dart';
import 'package:flutter/material.dart';

/// Component that displays the conversation header with cover image, name, and description
class ConversationHeaderSection extends StatelessWidget {
  const ConversationHeaderSection({
    required this.conversation,
    super.key,
  });

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cover image
        if (conversation.imageUrl != null)
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(conversation.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (conversation.imageUrl != null) const SizedBox(height: 16),

        // Conversation name
        Text(
          conversation.channelName ?? 'Unknown Conversation',
          style: AppTextStyle.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Conversation description
        if (conversation.description?.isNotEmpty ?? false)
          Text(
            conversation.description!,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
