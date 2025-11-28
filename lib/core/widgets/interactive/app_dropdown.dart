import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

/// A themed dropdown button component that follows the app's design system.
///
/// Usage:
/// - For forms with labels: Use with `label` parameter in a Column layout
/// - For inline usage (like in app bars): Wrap with `SizedBox` and set `isExpanded: true`
/// - For constrained layouts: Set `isExpanded: false` and provide width via parent container
/// - The component automatically adapts its layout based on whether a label is provided
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.label,
    this.isExpanded = true,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.padding,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? label;
  final bool isExpanded;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dropdownWidget = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        border: Border.all(
          color: borderColor ?? AppColors.border,
        ),
        borderRadius: borderRadius ?? AppBorders.small,
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        hint: hint,
        isExpanded: isExpanded,
        underline: const SizedBox.shrink(),
        icon: Icon(
          AppIcons.chevronDown,
          size: 20,
          color: iconColor ?? AppColors.textSecondary,
        ),
        style: AppTextStyle.bodyMedium.copyWith(
          color: textColor ?? AppColors.textPrimary,
        ),
        dropdownColor: AppColors.surface,
      ),
    );

    // If there's a label, use Column layout with constrained size
    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle(
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            child: label!,
          ),
          const SizedBox(height: 8),
          dropdownWidget,
        ],
      );
    }

    // If no label, just return the dropdown widget directly
    return dropdownWidget;
  }
}
