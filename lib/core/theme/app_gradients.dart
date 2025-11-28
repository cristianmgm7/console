import 'package:flutter/material.dart';
import 'app_colors.dart';

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
