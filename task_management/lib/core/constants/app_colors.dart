import 'package:flutter/material.dart';

/// App brand color palette.
/// Usage: AppColors.primary, AppColors.surface, etc.
class AppColors {
  AppColors._();

  // ─── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);       // Indigo 500
  static const Color primaryLight = Color(0xFFA5B4FC);  // Indigo 300
  static const Color primaryDark = Color(0xFF4338CA);   // Indigo 700

  static const Color secondary = Color(0xFF06B6D4);     // Cyan 500
  static const Color accent = Color(0xFFF59E0B);        // Amber 500

  // ─── Neutrals ────────────────────────────────────────────────────────────
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);  // Green 500
  static const Color warning = Color(0xFFF59E0B);  // Amber 500
  static const Color error = Color(0xFFEF4444);    // Red 500
  static const Color info = Color(0xFF3B82F6);     // Blue 500

  // ─── Task Priority Colors ─────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityCritical = Color(0xFF7C3AED);

  // ─── Task Status Colors ───────────────────────────────────────────────
  static const Color statusTodo = Color(0xFF9CA3AF);
  static const Color statusDoing = Color(0xFF3B82F6);
  static const Color statusReview = Color(0xFFF59E0B);
  static const Color statusDone = Color(0xFF10B981);

  // ─── Background ──────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
}
