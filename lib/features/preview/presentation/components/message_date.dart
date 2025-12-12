import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/utils/date_time_formatters.dart';
import 'package:flutter/material.dart';

/// Component for displaying message creation date
class MessageDate extends StatelessWidget {
  const MessageDate({
    required this.createdAt,
    super.key,
  });

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateTimeFormatters.formatDate(createdAt),
      style: AppTextStyle.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}
