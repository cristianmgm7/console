import 'package:carbon_voice_console/core/theme/app_animations.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppIconButtonSize { small, medium, large }

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = AppIconButtonSize.medium,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
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

  Future<void> _handleTapDown(TapDownDetails details) async {
    // Ignore: unawaited_futures - animation is fire and forget
    await _controller.forward();
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    // Ignore: unawaited_futures - animation is fire and forget
    await _controller.reverse();
  }

  Future<void> _handleTapCancel() async {
    // Ignore: unawaited_futures - animation is fire and forget
    await _controller.reverse();
  }

  double get _iconSize {
    return switch (widget.size) {
      AppIconButtonSize.small => 16,
      AppIconButtonSize.medium => 20,
      AppIconButtonSize.large => 24,
    };
  }

  double get _containerSize {
    return switch (widget.size) {
      AppIconButtonSize.small => 32,
      AppIconButtonSize.medium => 40,
      AppIconButtonSize.large => 48,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final foregroundColor = widget.foregroundColor ?? AppColors.textPrimary;
    final backgroundColor = widget.backgroundColor ?? AppColors.transparent;

    final button = MouseRegion(
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
            width: _containerSize,
            height: _containerSize,
            decoration: BoxDecoration(
              color: _isHovered && !isDisabled
                  ? (backgroundColor == AppColors.transparent
                      ? foregroundColor.withValues(alpha: 0.08)
                      : _darkenColor(backgroundColor, 0.1))
                  : backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: _iconSize,
              color: isDisabled ? AppColors.disabled : foregroundColor,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip,
        child: button,
      );
    }

    return button;
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
