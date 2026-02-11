import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keySelectedTheme = 'selected_theme';

  /// Get the saved theme mode directly (synchronous if prefs already loaded, but SharedPreferences.getInstance is async)
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    return _indexToThemeMode(savedThemeIndex);
  }

  /// Save the theme mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, _themeModeToIndex(mode));
  }

  /// Get the saved selected theme
  Future<String?> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedTheme);
  }

  /// Save the selected theme
  Future<void> saveSelectedTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedTheme, theme);
  }

  // Helpers
  ThemeMode _indexToThemeMode(int index) {
    switch (index) {
      case 0:
        return ThemeMode.system;
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int _themeModeToIndex(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 0;
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
    }
  }
}
