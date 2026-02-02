import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light; // Par défaut en mode clair
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du thème: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      ThemeMode newMode;
      switch (_themeMode) {
        case ThemeMode.light:
          newMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          newMode = ThemeMode.light; // Retour direct au mode clair (mode système commenté)
          break;
        case ThemeMode.system: // Mode système temporairement désactivé
          newMode = ThemeMode.light;
          break;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, newMode.index);
      
      _themeMode = newMode;
      notifyListeners();
      
      print('Thème changé vers: $_themeMode');
    } catch (e) {
      print('Erreur lors du changement de thème: $e');
    }
  }

  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system: // Mode système temporairement désactivé
        return Icons.brightness_auto;
    }
  }

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Mode Clair';
      case ThemeMode.dark:
        return 'Mode Sombre';
      case ThemeMode.system: // Mode système temporairement désactivé
        return 'Mode Système';
    }
  }
}
