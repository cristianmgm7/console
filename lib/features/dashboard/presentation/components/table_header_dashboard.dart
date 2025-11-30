import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_state.dart';
import 'package:flutter/material.dart';

class DashboardTableHeader extends StatelessWidget {
  const DashboardTableHeader({
    required this.onToggleSelectAll,
    required this.messageState,
    required this.selectAll,
    super.key,
  });

  final MessageLoaded messageState;
  final bool selectAll;
  final void Function(int length, {bool? value}) onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: AppColors.surface.withValues(alpha: 0.3),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Select All Checkbox
            AppCheckbox(
              value: selectAll,
              onChanged: (value) => onToggleSelectAll(messageState.messages.length, value: value),
            ),

            const SizedBox(width: 8),

            // Headers
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  Text(
                    'Date',
                    style: AppTextStyle.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(AppIcons.chevronUp, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 140,
              child: Text(
                'Owner',
                style: AppTextStyle.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                'Message',
                style: AppTextStyle.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 16),
            const SizedBox(width: 60), // AI Action space
            const SizedBox(width: 16),

            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    'Dur',
                    style: AppTextStyle.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(AppIcons.unfoldMore, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),

            const SizedBox(width: 16),

            SizedBox(
              width: 90,
              child: Text(
                'Status',
                style: AppTextStyle.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 56), // Menu space
          ],
        ),
      ),
    );
  }
}
