import 'package:flutter/material.dart';

/// TaskFlow design tokens, ported 1:1 from the `TaskFlow.dc.html` design doc
/// (the `:root` / `[data-theme="dark"]` CSS custom properties).
///
/// Exposed as a [ThemeExtension] so every screen can read the same semantic
/// tokens and re-theme live between light/dark and across accent colors:
///
/// ```dart
/// final p = context.palette;
/// Container(color: p.surface, ...);
/// ```
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  // Backgrounds & surfaces
  final Color bg;
  final Color panel;
  final Color surface;
  final Color surface2;
  final Color surface3;

  // Text
  final Color text;
  final Color text2;
  final Color text3;

  // Borders
  final Color border;
  final Color border2;

  // Accent
  final Color accent;
  final Color onAccent;

  // Device bezel (phone frame in mockups)
  final Color bezel;

  // Semantic status / priority palette (fixed hues from the design)
  final Color statusTodo;
  final Color statusProgress;
  final Color statusReview;
  final Color statusDone;

  final Color danger; // #e5484d — critical / overdue
  final Color warning; // #e08a13 — high / pending
  final Color success; // #22a35b — done
  final Color purple; // #7c3aed — avatar accents

  const AppPalette({
    required this.bg,
    required this.panel,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.border2,
    required this.accent,
    required this.onAccent,
    required this.bezel,
    required this.statusTodo,
    required this.statusProgress,
    required this.statusReview,
    required this.statusDone,
    required this.danger,
    required this.warning,
    required this.success,
    required this.purple,
  });

  /// `color-mix(in oklab, color X%, surface)` ≈ blend of [c] over [surface].
  /// Used for the soft chip / tag backgrounds throughout the design.
  Color tint(Color c, double amount) =>
      Color.lerp(surface, c, amount) ?? c;

  /// `--accent-weak` : 12% (light) accent over surface.
  Color get accentWeak => tint(accent, 0.14);

  /// `--accent-weak-2`
  Color get accentWeak2 => tint(accent, 0.18);

  // ── Light ────────────────────────────────────────────────────────────────
  static AppPalette light(Color accent) => AppPalette(
        bg: const Color(0xFFE9EBF1),
        panel: const Color(0xFFFFFFFF),
        surface: const Color(0xFFFFFFFF),
        surface2: const Color(0xFFF5F6F9),
        surface3: const Color(0xFFECEEF2),
        text: const Color(0xFF171A21),
        text2: const Color(0xFF5B616E),
        text3: const Color(0xFF98A0AD),
        border: const Color(0xFFECEDF1),
        border2: const Color(0xFFE0E2E9),
        accent: accent,
        onAccent: const Color(0xFFFFFFFF),
        bezel: const Color(0xFF0C0E13),
        statusTodo: const Color(0xFF6A7280),
        statusProgress: accent,
        statusReview: const Color(0xFFE08A13),
        statusDone: const Color(0xFF22A35B),
        danger: const Color(0xFFE5484D),
        warning: const Color(0xFFE08A13),
        success: const Color(0xFF22A35B),
        purple: const Color(0xFF7C3AED),
      );

  // ── Dark ─────────────────────────────────────────────────────────────────
  static AppPalette dark(Color accent) => AppPalette(
        bg: const Color(0xFF0A0B0E),
        panel: const Color(0xFF111318),
        surface: const Color(0xFF15171D),
        surface2: const Color(0xFF1B1E25),
        surface3: const Color(0xFF222630),
        text: const Color(0xFFE9EBF0),
        text2: const Color(0xFF98A0AD),
        text3: const Color(0xFF6A7280),
        border: const Color(0xFF262A33),
        border2: const Color(0xFF2F3540),
        accent: accent,
        onAccent: const Color(0xFF0A0B0E),
        bezel: const Color(0xFF26272C),
        statusTodo: const Color(0xFF6A7280),
        statusProgress: accent,
        statusReview: const Color(0xFFE08A13),
        statusDone: const Color(0xFF22A35B),
        danger: const Color(0xFFE5484D),
        warning: const Color(0xFFE08A13),
        success: const Color(0xFF22A35B),
        purple: const Color(0xFF7C3AED),
      );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? panel,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? text,
    Color? text2,
    Color? text3,
    Color? border,
    Color? border2,
    Color? accent,
    Color? onAccent,
    Color? bezel,
    Color? statusTodo,
    Color? statusProgress,
    Color? statusReview,
    Color? statusDone,
    Color? danger,
    Color? warning,
    Color? success,
    Color? purple,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      panel: panel ?? this.panel,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      bezel: bezel ?? this.bezel,
      statusTodo: statusTodo ?? this.statusTodo,
      statusProgress: statusProgress ?? this.statusProgress,
      statusReview: statusReview ?? this.statusReview,
      statusDone: statusDone ?? this.statusDone,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      purple: purple ?? this.purple,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      bezel: Color.lerp(bezel, other.bezel, t)!,
      statusTodo: Color.lerp(statusTodo, other.statusTodo, t)!,
      statusProgress: Color.lerp(statusProgress, other.statusProgress, t)!,
      statusReview: Color.lerp(statusReview, other.statusReview, t)!,
      statusDone: Color.lerp(statusDone, other.statusDone, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
    );
  }
}

/// Convenience accessor: `context.palette.accent`.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light(const Color(0xFF2F6BFF));
}
