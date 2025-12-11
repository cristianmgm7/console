import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays message selection count with validation indicator
class MessageSelectionCounter extends StatelessWidget {
  const MessageSelectionCounter({
    required this.selectedCount,
    required this.minCount,
    required this.maxCount,
    super.key,
  });

  final int selectedCount;
  final int minCount;
  final int maxCount;

  bool get isValid => selectedCount >= minCount && selectedCount <= maxCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isValid ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.info,
            size: 16,
            color: isValid ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '$selectedCount / $maxCount selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
