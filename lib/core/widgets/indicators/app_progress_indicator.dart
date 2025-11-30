import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_colors.dart';

enum AppProgressIndicatorType { circular, linear }

enum AppProgressIndicatorSize { small, medium, large }

class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({
    super.key,
    this.type = AppProgressIndicatorType.circular,
    this.size = AppProgressIndicatorSize.medium,
    this.value,
    this.color,
    this.backgroundColor,
  });

  final AppProgressIndicatorType type;
  final AppProgressIndicatorSize size;
  final double? value;
  final Color? color;
  final Color? backgroundColor;

  double get _strokeWidth {
    return switch (size) {
      AppProgressIndicatorSize.small => 2,
      AppProgressIndicatorSize.medium => 3,
      AppProgressIndicatorSize.large => 4,
    };
  }

  double get _circularSize {
    return switch (size) {
      AppProgressIndicatorSize.small => 16,
      AppProgressIndicatorSize.medium => 24,
      AppProgressIndicatorSize.large => 32,
    };
  }

  double get _linearHeight {
    return switch (size) {
      AppProgressIndicatorSize.small => 4,
      AppProgressIndicatorSize.medium => 6,
      AppProgressIndicatorSize.large => 8,
    };
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).colorScheme.primary;

    return switch (type) {
      AppProgressIndicatorType.circular => SizedBox(
          width: _circularSize,
          height: _circularSize,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: _strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: backgroundColor ?? AppColors.border,
          ),
        ),
      AppProgressIndicatorType.linear => ClipRRect(
          borderRadius: BorderRadius.circular(_linearHeight / 2),
          child: SizedBox(
            height: _linearHeight,
            child: LinearProgressIndicator(
              value: value,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              backgroundColor: backgroundColor ?? AppColors.border,
            ),
          ),
        ),
    };
  }
}
