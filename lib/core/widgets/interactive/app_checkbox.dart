import 'package:carbon_voice_console/core/theme/app_animations.dart';
import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:flutter/material.dart';

class AppCheckbox extends StatefulWidget {
  const AppCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
    this.checkColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? checkColor;

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.spring),
    );

    if (widget.value) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(AppCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        // Ignore: unawaited_futures - animation is fire and forget
        _controller.forward();
      } else {
        // Ignore: unawaited_futures - animation is fire and forget
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.primary;
    final checkColor = widget.checkColor ?? AppColors.surface;
    final isDisabled = widget.onChanged == null;

    return GestureDetector(
      onTap: isDisabled ? null : () => widget.onChanged?.call(!widget.value),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          curve: AppAnimations.easeInOut,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: widget.value
                ? (isDisabled ? AppColors.disabled : activeColor)
                : AppColors.transparent,
            border: Border.all(
              color: widget.value
                  ? (isDisabled ? AppColors.disabled : activeColor)
                  : (isDisabled ? AppColors.disabled : AppColors.border),
              width: 2,
            ),
            borderRadius: AppBorders.small,
          ),
          child: widget.value
              ? Icon(
                  AppIcons.check,
                  size: 14,
                  color: checkColor,
                )
              : null,
        ),
      ),
    );
  }
}
