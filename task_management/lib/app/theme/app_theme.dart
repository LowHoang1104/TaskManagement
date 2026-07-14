import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import 'app_palette.dart';
import 'app_text_styles.dart';

/// Builds the light/dark [ThemeData] for TaskFlow from the design tokens.
///
/// Both themes are parameterized by [accent] so the app can re-theme live from
/// the accent picker (mirrors the "Tweaks" panel in the design doc).
class AppTheme {
  AppTheme._();

  static const Color _defaultAccent = Color(0xFF2F6BFF);
  static const Color _defaultAccentDark = Color(0xFF5B8CFF);

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData light({Color accent = _defaultAccent}) {
    final p = AppPalette.light(accent);
    return _base(Brightness.light, p, AppTextStyles.textTheme);
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData dark({Color accent = _defaultAccentDark}) {
    final p = AppPalette.dark(accent);
    return _base(Brightness.dark, p, AppTextStyles.textThemeDark);
  }

  static ThemeData _base(Brightness brightness, AppPalette p, TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [p],
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
      ).copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        secondary: p.accent,
        error: p.danger,
        surface: p.surface,
        onSurface: p.text,
      ),
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.surface,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: p.text2),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: p.surface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: BorderSide(color: p.border2, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border2, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border2, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.danger, width: 1.8),
        ),
        labelStyle: TextStyle(color: p.text3),
        hintStyle: TextStyle(color: p.text3),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}
