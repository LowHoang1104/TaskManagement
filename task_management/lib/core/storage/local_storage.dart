import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences
class _PrefKeys {
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String onboardingDone = 'onboarding_done';
  static const String lastWorkspaceId = 'last_workspace_id';
}

/// Wrapper around [SharedPreferences] for non-sensitive user preferences.
class LocalStorage {
  final SharedPreferences _prefs;

  const LocalStorage(this._prefs);

  // ─── Theme ────────────────────────────────────────────────────────────────
  bool get isDarkMode => _prefs.getBool(_PrefKeys.isDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _prefs.setBool(_PrefKeys.isDarkMode, value);

  // ─── Language ─────────────────────────────────────────────────────────────
  String get language => _prefs.getString(_PrefKeys.language) ?? 'vi';
  Future<void> setLanguage(String code) =>
      _prefs.setString(_PrefKeys.language, code);

  // ─── Onboarding ───────────────────────────────────────────────────────────
  bool get isOnboardingDone => _prefs.getBool(_PrefKeys.onboardingDone) ?? false;
  Future<void> setOnboardingDone() =>
      _prefs.setBool(_PrefKeys.onboardingDone, true);

  // ─── Last opened workspace ────────────────────────────────────────────────
  String? get lastWorkspaceId => _prefs.getString(_PrefKeys.lastWorkspaceId);
  Future<void> setLastWorkspaceId(String id) =>
      _prefs.setString(_PrefKeys.lastWorkspaceId, id);

  // ─── Clear all preferences ────────────────────────────────────────────────
  Future<void> clear() => _prefs.clear();
}
