import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_dimensions.dart';
import 'package:carbon_voice_console/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? AppBorders.card,
        boxShadow: elevation ? [AppShadows.diffused] : null,
      ),
      child: child,
    );
  }
}
