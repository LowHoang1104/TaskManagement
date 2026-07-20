import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newTheme;
    await _prefs.setInt(_themeKey, newTheme.index);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _prefs.setInt(_themeKey, mode.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Accent color used to build both light & dark themes. Mirrors the accent
/// picker in the TaskFlow design doc ("Tweaks" panel). Persisted to prefs.
class AccentNotifier extends StateNotifier<Color> {
  static const _accentKey = 'accent_color';

  /// Accent swatches offered by the design doc.
  static const List<Color> options = [
    Color(0xFF2F6BFF),
    Color(0xFF2563EB),
    Color(0xFF0EA5E9),
    Color(0xFF6D5EFC),
  ];

  final SharedPreferences _prefs;

  AccentNotifier(this._prefs) : super(options.first) {
    final stored = _prefs.getInt(_accentKey);
    if (stored != null) state = Color(stored);
  }

  Future<void> setAccent(Color color) async {
    state = color;
    await _prefs.setInt(_accentKey, color.toARGB32());
  }
}

final accentProvider = StateNotifierProvider<AccentNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentNotifier(prefs);
});
