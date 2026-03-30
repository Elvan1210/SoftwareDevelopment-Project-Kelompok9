import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides theme state management across the app with persistence
class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;

  static const String _themeKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider._internal() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme constraints: $e');
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_themeMode == ThemeMode.light) {
        await prefs.setString(_themeKey, 'light');
      } else if (_themeMode == ThemeMode.dark) {
        await prefs.setString(_themeKey, 'dark');
      } else {
        await prefs.setString(_themeKey, 'system');
      }
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Explicitly set the theme mode
  void setMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveTheme();
  }
  
  /// Toggles based on the current actual brightness computed by the UI
  void toggleTheme(bool isCurrentlyDark) async {
    _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _saveTheme();
  }
}
