import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  // Display styles
  static TextStyle displayLarge = GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Headline styles
  static TextStyle headlineLarge = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.35,
    letterSpacing: 0.5,
  );

  static TextStyle headlineMedium = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle headlineSmall = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  // Title styles
  static TextStyle titleLarge = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle titleMedium = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static TextStyle titleSmall = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Body styles
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // Label styles
  static TextStyle labelLarge = GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.15,
  );

  static TextStyle labelSmall = GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.2,
  );
}
