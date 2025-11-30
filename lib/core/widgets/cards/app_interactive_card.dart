import 'package:flutter/material.dart';

import 'package:carbon_voice_console/core/theme/app_animations.dart';
import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_dimensions.dart';
import 'package:carbon_voice_console/core/theme/app_shadows.dart';

class AppInteractiveCard extends StatefulWidget {
  const AppInteractiveCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = true,
    this.hoverElevation = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool elevation;
  final bool hoverElevation;

  @override
  State<AppInteractiveCard> createState() => _AppInteractiveCardState();
}

class _AppInteractiveCardState extends State<AppInteractiveCard>
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
    if (widget.onTap != null) {
      // Ignore: unawaited_futures - animation is fire and forget
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      // Ignore: unawaited_futures - animation is fire and forget
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      // Ignore: unawaited_futures - animation is fire and forget
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? AppColors.surface;
    final borderRadius = widget.borderRadius ?? AppBorders.card;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            curve: AppAnimations.easeInOut,
            padding: widget.padding ??
                const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: _isHovered ? _lightenColor(backgroundColor, 0.02) : backgroundColor,
              borderRadius: borderRadius,
              boxShadow: _isHovered && widget.hoverElevation
                  ? [
                      AppShadows.diffused,
                      AppShadows.colored(Theme.of(context).colorScheme.primary),
                    ]
                  : widget.elevation
                      ? [AppShadows.diffused]
                      : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
