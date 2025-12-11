import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:flutter/material.dart';

/// Component that displays the conversation header with cover image, name, and description
class ConversationHeaderSection extends StatelessWidget {
  const ConversationHeaderSection({
    required this.previewUiModel,
    super.key,
  });

  final PreviewUiModel previewUiModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cover image
        if (previewUiModel.conversationCoverUrl != null)
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(previewUiModel.conversationCoverUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (previewUiModel.conversationCoverUrl != null) const SizedBox(height: 16),

        // Conversation name
        Text(
          previewUiModel.conversationName,
          style: AppTextStyle.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Conversation description
        if (previewUiModel.conversationDescription.isNotEmpty)
          Text(
            previewUiModel.conversationDescription,
            style: AppTextStyle.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
