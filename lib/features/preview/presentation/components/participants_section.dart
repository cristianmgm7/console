import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/preview/presentation/models/preview_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/participant_avatar_grid.dart';
import 'package:flutter/material.dart';

/// Component that displays the participants section with avatars
class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({
    required this.previewUiModel,
    super.key,
  });

  final PreviewUiModel previewUiModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Participants',
          style: AppTextStyle.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ParticipantAvatarGrid(participants: previewUiModel.participants),
      ],
    );
  }
}
