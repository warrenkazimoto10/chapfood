import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      setState(() {
        _themeMode = ThemeMode.values[themeIndex];
      });
    } catch (e) {
      print('Erreur lors du chargement du thème: $e');
    }
  }
  
  Future<void> _toggleTheme() async {
    try {
      ThemeMode newMode;
      if (_themeMode == ThemeMode.light) {
        newMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        newMode = ThemeMode.system;
      } else {
        newMode = ThemeMode.light;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, newMode.index);
      
      setState(() {
        _themeMode = newMode;
      });
      
      // Notifier le parent pour changer le thème de l'app
      if (mounted) {
        // Optionnel: vous pouvez ajouter un callback ici pour notifier le parent
        print('Thème changé vers: $newMode');
      }
    } catch (e) {
      print('Erreur lors du changement de thème: $e');
    }
  }
  
  IconData get _themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Icon(
          _themeIcon,
          color: AppColors.getTextColor(context),
          size: 20,
        ),
      ),
    );
  }
}


