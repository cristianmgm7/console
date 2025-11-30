import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Base container for all dashboard side panels
class BasePanel extends StatelessWidget {
  const BasePanel({
    required this.child,
    this.width = 320,
    this.showBorder = true,
    super.key,
  });

  final Widget child;
  final double width;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      child: AppContainer(
        backgroundColor: AppColors.surface,
        border: showBorder
            ? const Border(
                left: BorderSide(color: AppColors.border),
              )
            : null,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
