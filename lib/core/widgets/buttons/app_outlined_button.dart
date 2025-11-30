import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_animations.dart';
import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';

enum AppOutlinedButtonSize { small, medium, large }

class AppOutlinedButton extends StatefulWidget {
  const AppOutlinedButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.size = AppOutlinedButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppOutlinedButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final Color? borderColor;
  final Color? foregroundColor;

  @override
  State<AppOutlinedButton> createState() => _AppOutlinedButtonState();
}

class _AppOutlinedButtonState extends State<AppOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: AppAnimations.scaleDown,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // Ignore: unawaited_futures - animation is fire and forget
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    // Ignore: unawaited_futures - animation is fire and forget
    _controller.reverse();
  }

  void _handleTapCancel() {
    // Ignore: unawaited_futures - animation is fire and forget
    _controller.reverse();
  }

  EdgeInsets get _padding {
    return switch (widget.size) {
      AppOutlinedButtonSize.small => const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      AppOutlinedButtonSize.medium => const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      AppOutlinedButtonSize.large => const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
    };
  }

  TextStyle get _textStyle {
    return switch (widget.size) {
      AppOutlinedButtonSize.small => AppTextStyle.labelMedium,
      AppOutlinedButtonSize.medium => AppTextStyle.labelLarge,
      AppOutlinedButtonSize.large => AppTextStyle.titleSmall,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final borderColor =
        widget.borderColor ?? AppColors.primary;
    final foregroundColor =
        widget.foregroundColor ?? AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            curve: AppAnimations.easeInOut,
            width: widget.fullWidth ? double.infinity : null,
            padding: _padding,
            decoration: BoxDecoration(
              color: _isHovered && !isDisabled
                  ? foregroundColor.withOpacity(0.05)
                  : AppColors.transparent,
              border: Border.all(
                color: isDisabled ? AppColors.disabled : borderColor,
                width: 1.5,
              ),
              borderRadius: AppBorders.small,
            ),
            child: DefaultTextStyle(
              style: _textStyle.copyWith(
                color: isDisabled ? AppColors.disabled : foregroundColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              child: widget.isLoading
                  ? SizedBox(
                      height: _textStyle.fontSize,
                      width: _textStyle.fontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor,
                        ),
                      ),
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
