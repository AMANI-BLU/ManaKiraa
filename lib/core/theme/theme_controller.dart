import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static final ThemeController _instance = ThemeController._internal();

  factory ThemeController() {
    return _instance;
  }

  static ThemeController get instance => _instance;

  ThemeController._internal() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    if (value != mode) {
      value = mode;
    }
  }

  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDarkMode => value == ThemeMode.dark;
  bool get isSystemMode => value == ThemeMode.system;
}
