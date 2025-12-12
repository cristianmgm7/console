import 'package:flutter/material.dart';

class AppColors {
  // Primary Backgrounds
  static const Color background = Color(0xFFF9FAFC); // bgOffWhite
  static const Color surface = Color(0xFFFFFFFF); // surfaceWhite
  static const Color divider = Color.fromARGB(57, 129, 129, 129); // surfaceSecondary
  static const Color accentBackground = Color.fromARGB(255, 150, 151, 223); // bgAccent
  
  // Primary Brand Colors
  static const Color primary = Color(0xFF5D5FEF); // Blurple Accent
  static const Color onPrimary = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E); // Dark Charcoal
  static const Color textSecondary = Color(0xFF8E8E93); // Cool Grey
  static const Color border = Color(0xFFE0E0E0); // Subtle border for light theme

  // Gradients (Aura)
  static const Color gradientPurple = Color(0xFFE6E6FA); // Lavender
  static const Color gradientPink = Color(0xFFF3E5F5);   // Soft Pink

  // Semantic colors (Standardized for light theme)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);

  // Action colors
  static const Color accent = Color(0xFF5D5FEF); // Same as primary for this theme
  static const Color highlight = Color(0xFFF3E5F5); // Pinkish highlight
  static const Color disabled = Color(0xFFBDBDBD);

  // Transparent colors
  static const Color transparent = Colors.transparent;
}
