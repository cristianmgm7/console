import 'dart:ui' as ui;

import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A themed text field component that follows the app's design system
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.onTapOutside,
    this.mouseCursor,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.contentInsertionConfiguration,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scribbleEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    // Custom properties for theming
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.borderColor,
    this.fillColor,
    this.textColor,
    this.hintColor,
    this.errorColor,
    this.labelColor,
  });

  // Standard TextField properties
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final ContentInsertionConfiguration? contentInsertionConfiguration;
  final Clip clipBehavior;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool enableIMEPersonalizedLearning;

  // Custom theming properties
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? borderColor;
  final Color? fillColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? errorColor;
  final Color? labelColor;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ??
        (_isFocused ? AppColors.primary : AppColors.border);

    final inputDecoration = widget.decoration?.copyWith(
      labelText: widget.label,
      hintText: widget.hint,
      errorText: widget.errorText,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      labelStyle: AppTextStyle.bodyMedium.copyWith(
        color: widget.labelColor ?? AppColors.textSecondary,
      ),
      hintStyle: AppTextStyle.bodyMedium.copyWith(
        color: widget.hintColor ?? AppColors.textSecondary.withValues(alpha: 0.6),
      ),
      errorStyle: AppTextStyle.bodySmall.copyWith(
        color: widget.errorColor ?? AppColors.error,
      ),
      helperStyle: AppTextStyle.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: widget.fillColor ?? AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: borderColor,
          width: _isFocused ? 2.0 : 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.errorColor ?? AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.errorColor ?? AppColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ) ?? InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      errorText: widget.errorText,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      labelStyle: AppTextStyle.bodyMedium.copyWith(
        color: widget.labelColor ?? AppColors.textSecondary,
      ),
      hintStyle: AppTextStyle.bodyMedium.copyWith(
        color: widget.hintColor ?? AppColors.textSecondary.withValues(alpha: 0.6),
      ),
      errorStyle: AppTextStyle.bodySmall.copyWith(
        color: widget.errorColor ?? AppColors.error,
      ),
      helperStyle: AppTextStyle.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: widget.fillColor ?? AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: borderColor,
          width: _isFocused ? 2.0 : 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.borderColor ?? AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.errorColor ?? AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorders.small,
        borderSide: BorderSide(
          color: widget.errorColor ?? AppColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: inputDecoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: widget.style ?? AppTextStyle.bodyMedium.copyWith(
        color: widget.textColor ?? AppColors.textPrimary,
      ),
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onAppPrivateCommand: widget.onAppPrivateCommand,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor ?? AppColors.primary,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      dragStartBehavior: widget.dragStartBehavior,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      mouseCursor: widget.mouseCursor,
      buildCounter: widget.buildCounter,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      contentInsertionConfiguration: widget.contentInsertionConfiguration,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      scribbleEnabled: widget.scribbleEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    );
  }
}
