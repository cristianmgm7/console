import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/conversations/presentation/models/conversation_ui_model.dart';
import 'package:flutter/material.dart';

/// Component that displays the conversation header with cover image, name, and description
class ConversationHeaderSection extends StatelessWidget {
  const ConversationHeaderSection({
    required this.conversation,
    super.key,
  });

  final ConversationUiModel conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cover image
        if (conversation.coverImageUrl != null)
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(conversation.coverImageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (conversation.coverImageUrl != null) const SizedBox(height: 16),

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
    );
  }
}
