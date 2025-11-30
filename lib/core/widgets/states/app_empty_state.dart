import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });

  factory AppEmptyState.noMessages({
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      icon: AppIcons.inbox,
      title: 'No messages',
      subtitle: 'No messages found in this conversation',
      action: onRetry != null
          ? AppButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          : null,
    );
  }

  factory AppEmptyState.loading({
    String? title,
    String? subtitle,
  }) {
    return AppEmptyState(
      icon: AppIcons.dashboard,
      title: title ?? 'Loading dashboard...',
      subtitle: subtitle ?? 'Please wait while we load your data',
    );
  }

  factory AppEmptyState.error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      icon: AppIcons.error,
      title: 'Error loading messages',
      subtitle: message,
      action: onRetry != null
          ? AppButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          : null,
    );
  }

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
