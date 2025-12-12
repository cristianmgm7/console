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

  static const LinearGradient darkAura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 146, 122, 204), // Darker purple
      Color.fromARGB(255, 148, 112, 127), // Darker pink
      Color.fromARGB(255, 133, 149, 176), // Dark gray instead of white
    ],
    stops: [0.0, 0.3, 1.0],
  );
}
