import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

enum ThemeOption {
  system,
  light,
  dark,
  midnight,
  cozy,
  bright,
  ocean,
  forest,
}

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();
  ThemeOption _selectedTheme = ThemeOption.system;
  bool _isInitialized = false;

  ThemeOption get selectedTheme => _selectedTheme;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    final savedTheme = await _repository.getSelectedTheme();
    _selectedTheme = _parseThemeOption(savedTheme);
    _isInitialized = true;
    notifyListeners();
  }

  ThemeOption _parseThemeOption(String? value) {
    if (value == null) return ThemeOption.system;
    try {
      return ThemeOption.values.firstWhere(
        (e) => e.toString() == 'ThemeOption.$value',
        orElse: () => ThemeOption.system,
      );
    } catch (e) {
      return ThemeOption.system;
    }
  }

  Future<void> setTheme(ThemeOption theme) async {
    if (_selectedTheme == theme) return;
    
    _selectedTheme = theme;
    await _repository.saveSelectedTheme(theme.toString().split('.').last);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_selectedTheme) {
      case ThemeOption.system:
        return ThemeMode.system;
      case ThemeOption.light:
      case ThemeOption.bright:
      case ThemeOption.cozy:
        return ThemeMode.light;
      case ThemeOption.dark:
      case ThemeOption.midnight:
      case ThemeOption.ocean:
      case ThemeOption.forest:
        return ThemeMode.dark;
    }
  }

  String get currentThemeName {
    switch (_selectedTheme) {
      case ThemeOption.system:
        return 'System';
      case ThemeOption.light:
        return 'Light';
      case ThemeOption.dark:
        return 'Dark';
      case ThemeOption.midnight:
        return 'Midnight';
      case ThemeOption.cozy:
        return 'Cozy';
      case ThemeOption.bright:
        return 'Bright';
      case ThemeOption.ocean:
        return 'Ocean';
      case ThemeOption.forest:
        return 'Forest';
    }
  }

  IconData get currentThemeIcon {
    switch (_selectedTheme) {
      case ThemeOption.system:
        return Icons.brightness_auto;
      case ThemeOption.light:
        return Icons.brightness_7;
      case ThemeOption.dark:
        return Icons.brightness_4;
      case ThemeOption.midnight:
        return Icons.nightlight_round;
      case ThemeOption.cozy:
        return Icons.local_fire_department;
      case ThemeOption.bright:
        return Icons.wb_sunny;
      case ThemeOption.ocean:
        return Icons.water;
      case ThemeOption.forest:
        return Icons.forest;
    }
  }

  Color getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    switch (_selectedTheme) {
      case ThemeOption.system:
      case ThemeOption.light:
      case ThemeOption.dark:
        return const Color(0xFF10B981); // Green
      case ThemeOption.midnight:
        return const Color(0xFF8B5CF6); // Purple
      case ThemeOption.cozy:
        return const Color(0xFFEA580C); // Orange
      case ThemeOption.bright:
        return const Color(0xFFEC4899); // Pink
      case ThemeOption.ocean:
        return const Color(0xFF06B6D4); // Cyan
      case ThemeOption.forest:
        return const Color(0xFF059669); // Emerald
    }
  }
}
