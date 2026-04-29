// lib/shared/providers/theme_provider.dart
/// Presentation-layer theme mode controller for light and dark themes.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({required SharedPreferences sharedPreferences})
      : _sharedPreferences = sharedPreferences {
    _themeMode = _readThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _sharedPreferences;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) {
    if (_themeMode == themeMode) {
      return;
    }
    _themeMode = themeMode;
    _sharedPreferences.setString(_themeModeKey, themeMode.name);
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _sharedPreferences.setString(_themeModeKey, _themeMode.name);
    notifyListeners();
  }

  ThemeMode _readThemeMode() {
    final String? saved = _sharedPreferences.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }
}
