import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_dimensions.dart';

class AppContainer extends StatelessWidget {
  const AppContainer({
    required this.child,
    super.key,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? AppBorders.small,
        border: border,
      ),
      child: child,
    );
  }
}
