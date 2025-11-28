import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_animations.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';

class AppSwitch extends StatefulWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeInOut),
    );

    if (widget.value) {
      _controller.value = 1;
    }

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    final activeColor =
        widget.activeColor ?? Theme.of(context).colorScheme.primary;
    _colorAnimation = ColorTween(
      begin: AppColors.border,
      end: activeColor,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(AppSwitch oldWidget) {
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
    if (widget.activeColor != oldWidget.activeColor) {
      _updateColorAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onChanged == null;

    return GestureDetector(
      onTap: isDisabled ? null : () => widget.onChanged?.call(!widget.value),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppColors.disabled
                  : _colorAnimation.value ?? AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Align(
              alignment: Alignment(
                _positionAnimation.value * 2 - 1,
                0,
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
