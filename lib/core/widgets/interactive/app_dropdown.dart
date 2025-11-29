import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/material.dart';

/// A themed dropdown menu component that follows the app's design system.
///
/// Usage:
/// - For forms with labels: Use with `label` parameter in a Column layout
/// - For inline usage (like in app bars): Wrap with `SizedBox` and set `isExpanded: true`
/// - For constrained layouts: Set `isExpanded: false` and provide width via parent container
/// - The component automatically adapts its layout based on whether a label is provided
class AppDropdown<T> extends StatefulWidget {
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
    this.dropdownKey,
    super.key,
    this.alignment = Alignment.topCenter,
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
  final Key? dropdownKey;
  final Alignment? alignment;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  late T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selectedValue = widget.value;
    }
  }

  // Convert DropdownMenuItem to DropdownMenuEntry
  List<DropdownMenuEntry<T>> _convertToMenuEntries() {
    return widget.items
        .where((item) => item.value != null) // Filter out null values
        .map((item) {
      // Extract text and icon from the child widget
      var label = item.value?.toString() ?? '';
      Widget? leadingIcon;

      // Try to extract text and icon from common widget patterns
      if (item.child is Row) {
        final row = item.child as Row;
        if (row.children.length >= 2 &&
            row.children[0] is Icon &&
            row.children[1] is SizedBox &&
            row.children.length >= 3 &&
            row.children[2] is Text) {
          // Pattern: Icon + SizedBox + Text
          leadingIcon = row.children[0] as Icon;
          label = (row.children[2] as Text).data ?? '';
        }
      } else if (item.child is Text) {
        // Simple text case
        label = (item.child as Text).data ?? '';
      }

      return DropdownMenuEntry<T>(
        value: item.value as T,
        label: label,
        leadingIcon: leadingIcon,
      );
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    // Extract hint text from hint widget
    String? hintText;
    final hint = widget.hint;
    if (hint is Text) {
      hintText = hint.data;
    } else if (hint is Row) {
      final row = hint;
      // Try to extract text from Row pattern: Icon + SizedBox + Text
      if (row.children.length >= 3 &&
          row.children[0] is Icon &&
          row.children[1] is SizedBox &&
          row.children[2] is Text) {
        hintText = (row.children[2] as Text).data;
      }
    }

    final dropdownWidget = DropdownMenu<T>(
      key: widget.dropdownKey,
      initialSelection: _selectedValue,
      onSelected: (T? value) {
        setState(() {
          _selectedValue = value;
        });
        widget.onChanged?.call(value);
      },
      dropdownMenuEntries: _convertToMenuEntries(),
      hintText: hintText,
      expandedInsets: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      textStyle: AppTextStyle.bodyMedium.copyWith(
        color: widget.textColor ?? AppColors.textPrimary,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(widget.backgroundColor ?? AppColors.surface),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? AppBorders.small,
            side: BorderSide(
              color: widget.borderColor ?? AppColors.border,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? AppBorders.small,
          borderSide: BorderSide(
            color: widget.borderColor ?? AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? AppBorders.small,
          borderSide: BorderSide(
            color: widget.borderColor ?? AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius ?? AppBorders.small,
          borderSide: BorderSide(
            color: widget.borderColor ?? AppColors.border,
          ),
        ),
        filled: true,
        fillColor: widget.backgroundColor ?? AppColors.surface,
        contentPadding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );

    // If there's a label, use Column layout with constrained size
    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle(
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            child: widget.label!,
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
