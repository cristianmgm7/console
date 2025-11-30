import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

/// A custom popup menu item that follows the app's design system
class AppPopupMenuItem<T> extends PopupMenuItem<T> {
  const AppPopupMenuItem({
    required super.value,
    required super.child,
    super.key,
    super.enabled = true,
    super.height = 48,
    super.padding,
    super.textStyle,
  });

  /// Creates a standard menu item with icon and text
  factory AppPopupMenuItem.standard({
    required T value,
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    bool enabled = true,
    Key? key,
  }) {
    return AppPopupMenuItem<T>(
      key: key,
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled
                ? (iconColor ?? AppColors.textPrimary)
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyle.bodyMedium.copyWith(
              color: enabled
                  ? (textColor ?? AppColors.textPrimary)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a destructive menu item (for delete/archive actions)
  factory AppPopupMenuItem.destructive({
    required T value,
    required IconData icon,
    required String text,
    bool enabled = true,
    Key? key,
  }) {
    return AppPopupMenuItem<T>(
      key: key,
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyle.bodyMedium.copyWith(
              color: enabled ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a custom menu item with full control over content
  factory AppPopupMenuItem.custom({
    required T value,
    required Widget child,
    bool enabled = true,
    Key? key,
  }) {
    return AppPopupMenuItem<T>(
      key: key,
      value: value,
      enabled: enabled,
      child: child,
    );
  }
}
