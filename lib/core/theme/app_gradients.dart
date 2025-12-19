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
      Color.fromARGB(255, 139, 144, 151), // Darker pink
      Color.fromARGB(255, 133, 149, 176), // Dark gray instead of white
    ],
    stops: [0.0, 0.3, 1.0],
  );

  static const LinearGradient ownerMessage = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(230, 83, 85, 169), // AppColors.primary with 0.9 alpha
      Color.fromARGB(179, 77, 79, 167), // AppColors.primary with 0.7 alpha
      Color.fromARGB(204, 75, 38, 86), // AppColors.primary with 0.8 alpha
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
