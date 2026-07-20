import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Centralized TextStyle definitions using GoogleFonts (Manrope) — the display
/// typeface used throughout the TaskFlow design doc.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: AppSizes.textDisplay,
        fontWeight: FontWeight.w800,
        color: AppColors.grey900,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppSizes.textXxl,
        fontWeight: FontWeight.w800,
        color: AppColors.grey900,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppSizes.textXl,
        fontWeight: FontWeight.w800,
        color: AppColors.grey900,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppSizes.textLg,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppSizes.textLg,
        fontWeight: FontWeight.w500,
        color: AppColors.grey900,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppSizes.textMd,
        fontWeight: FontWeight.w500,
        color: AppColors.grey600,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppSizes.textSm,
        fontWeight: FontWeight.w600,
        color: AppColors.grey400,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppSizes.textMd,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppSizes.textXs,
        fontWeight: FontWeight.w700,
        color: AppColors.grey400,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme get textThemeDark => textTheme.apply(
        bodyColor: const Color(0xFFE9EBF0),
        displayColor: const Color(0xFFE9EBF0),
      );
}
