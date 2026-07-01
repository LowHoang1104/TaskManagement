import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Centralized TextStyle definitions using GoogleFonts (Inter).
class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: AppSizes.textDisplay,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppSizes.textXxl,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppSizes.textXl,
        fontWeight: FontWeight.w600,
        color: AppColors.grey800,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppSizes.textLg,
        fontWeight: FontWeight.w600,
        color: AppColors.grey800,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppSizes.textLg,
        fontWeight: FontWeight.w400,
        color: AppColors.grey800,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppSizes.textMd,
        fontWeight: FontWeight.w400,
        color: AppColors.grey600,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppSizes.textSm,
        fontWeight: FontWeight.w400,
        color: AppColors.grey400,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppSizes.textMd,
        fontWeight: FontWeight.w600,
        color: AppColors.grey800,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppSizes.textXs,
        fontWeight: FontWeight.w500,
        color: AppColors.grey400,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme get textThemeDark => textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      );
}
