import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le thème de l'application
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // On retourne false par défaut si system
      // La vraie détection se fait via MediaQuery dans le widget
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Charger le mode thème depuis SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeKey);

      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement thème: $e');
    }
  }

  /// Définir le mode thème
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;

      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.system:
          modeString = 'system';
          break;
      }

      await prefs.setString(_themeKey, modeString);
      debugPrint('✅ Thème sauvegardé: $modeString');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde thème: $e');
    }
  }

  /// Basculer entre clair et sombre
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
