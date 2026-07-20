import 'package:flutter/material.dart';

/// App brand color palette — values sourced from the TaskFlow design doc
/// (`TaskFlow.dc.html`). Member names are kept stable for backwards
/// compatibility; new screens should prefer `context.palette` (see
/// [AppPalette]) which is fully theme-aware. These constants map to the
/// light-theme tokens.
class AppColors {
  AppColors._();

  // ─── Brand / Accent ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2F6BFF);       // --accent (light)
  static const Color primaryLight = Color(0xFF5B8CFF);  // --accent (dark)
  static const Color primaryDark = Color(0xFF1E4FD6);   // pressed accent

  static const Color secondary = Color(0xFF7C3AED);     // violet accents
  static const Color accent = Color(0xFF2F6BFF);

  // ─── Neutrals (mapped to design tokens) ───────────────────────────────────
  static const Color grey50 = Color(0xFFF5F6F9);   // --surface-2
  static const Color grey100 = Color(0xFFECEEF2);  // --surface-3
  static const Color grey200 = Color(0xFFE0E2E9);  // --border-2
  static const Color grey400 = Color(0xFF98A0AD);  // --text-3
  static const Color grey600 = Color(0xFF5B616E);  // --text-2
  static const Color grey800 = Color(0xFF2A2F3A);
  static const Color grey900 = Color(0xFF171A21);  // --text

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22A35B);
  static const Color warning = Color(0xFFE08A13);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF2F6BFF);

  // ─── Task Priority Colors ─────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF6A7280);
  static const Color priorityMedium = Color(0xFF5B616E);
  static const Color priorityHigh = Color(0xFFE08A13);
  static const Color priorityCritical = Color(0xFFE5484D);

  // ─── Task Status Colors ───────────────────────────────────────────────
  static const Color statusTodo = Color(0xFF6A7280);
  static const Color statusDoing = Color(0xFF2F6BFF);
  static const Color statusReview = Color(0xFFE08A13);
  static const Color statusDone = Color(0xFF22A35B);

  // ─── Background ──────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFE9EBF1);
  static const Color backgroundDark = Color(0xFF0A0B0E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF15171D);
}
