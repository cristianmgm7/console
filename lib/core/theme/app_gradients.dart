import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient aura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientPurple,
      AppColors.gradientPink,
      Colors.white,
    ],
    stops: [0.0, 0.3, 1.0],
  );
}
