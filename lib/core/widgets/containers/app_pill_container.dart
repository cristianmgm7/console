import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_text_style.dart';

class AppPillContainer extends StatelessWidget {
  const AppPillContainer({
    required this.child,
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: DefaultTextStyle(
        style: AppTextStyle.labelSmall.copyWith(
          color: foregroundColor ?? Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}
