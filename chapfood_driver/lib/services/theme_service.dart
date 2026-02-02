import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Initialise le service de thème
  static Future<ThemeService> initialize() async {
    final service = ThemeService();
    await service._loadTheme();
    return service;
  }
  
  /// Charge le thème sauvegardé
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement thème: $e');
      _themeMode = ThemeMode.light;
    }
  }
  
  /// Sauvegarde le thème
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      print('❌ Erreur sauvegarde thème: $e');
    }
  }
  
  /// Change le thème
  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      await _saveTheme();
      notifyListeners();
    }
  }
  
  /// Bascule entre le thème clair et sombre
  Future<void> toggleTheme() async {
    final newTheme = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }
  
  /// Définit le thème clair
  Future<void> setLightTheme() async {
    await setTheme(ThemeMode.light);
  }
  
  /// Définit le thème sombre
  Future<void> setDarkTheme() async {
    await setTheme(ThemeMode.dark);
  }
  
  /// Définit le thème système
  Future<void> setSystemTheme() async {
    await setTheme(ThemeMode.system);
  }
  
  /// Obtient la couleur de fond de la carte selon le thème
  Color getMapBackgroundColor() {
    return _themeMode == ThemeMode.dark 
      ? const Color(0xFF1A1A1A) 
      : const Color(0xFFFAFAFA);
  }
  
  /// Obtient la couleur du texte selon le thème
  Color getTextColor() {
    return _themeMode == ThemeMode.dark 
      ? const Color(0xFFF7FAFC) 
      : const Color(0xFF1A202C);
  }
}