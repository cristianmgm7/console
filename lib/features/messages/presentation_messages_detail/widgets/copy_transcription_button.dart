import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyTranscriptionButton extends StatelessWidget {
  const CopyTranscriptionButton({
    required this.transcription,
    super.key,
  });

  final String transcription;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.copy,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: transcription));
        // Show a snackbar or toast to indicate copy success
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transcription copied to clipboard',
                style: AppTextStyle.bodyMedium.copyWith(color: AppColors.surface),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      tooltip: 'Copy transcription',
    );
  }
}
