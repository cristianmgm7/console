import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_gradients.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/preview/presentation/components/message_date.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/audio_controls.dart';
import 'package:flutter/material.dart';

/// Component for displaying message text content
class MessageContent extends StatefulWidget {
  const MessageContent({
    required this.message,
    this.isOwner = false,
    super.key,
  });

  final MessageUiModel message;
  final bool isOwner;

  @override
  State<MessageContent> createState() => _MessageContentState();
}

class _MessageContentState extends State<MessageContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.message.textModels.isEmpty) return const SizedBox.shrink();

    // Find the transcript text model
    final transcriptModel = widget.message.textModels.firstWhere(
      (model) => model.type == 'transcript',
      orElse: () => widget.message.textModels.first, // Fallback to first if no transcript found
    );

    // Check if text is long enough to need truncation (more than 200 characters or 3 lines)
    final isLongText = transcriptModel.text.length > 500 || transcriptModel.text.split('\n').length > 3;
    final displayText = !_isExpanded && isLongText
        ? _truncateText(transcriptModel.text)
        : transcriptModel.text;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: widget.isOwner ? AppGradients.ownerMessage : null,
        color: widget.isOwner ? null : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
      spacing: 16,
      children: [
        Text(
          displayText,
          style: widget.isOwner
              ? AppTextStyle.bodyMediumBlack.copyWith(color: AppColors.onPrimary)
              : AppTextStyle.bodyMediumBlack,
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AudioControls(message: widget.message, isOwner: widget.isOwner),
              if (isLongText) ...[
                _buildExpandButton(),
              ] else ...[
                const Spacer(),
              ],
              MessageDate(createdAt: widget.message.createdAt, isOwner: widget.isOwner),
            ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(60, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        _isExpanded ? 'Show Less' : 'Show More',
        style: AppTextStyle.bodySmall.copyWith(
          color: widget.isOwner
              ? AppColors.onPrimary.withValues(alpha: 0.8)
              : AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _truncateText(String text) {
    // Try to truncate at word boundary around 150 characters
    if (text.length <= 150) return text;

    final truncated = text.substring(0, 150);
    final lastSpaceIndex = truncated.lastIndexOf(' ');

    if (lastSpaceIndex > 100) {
      return '${truncated.substring(0, lastSpaceIndex)}...';
    } else {
      return '$truncated...';
    }
  }
}
