import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color primaryOrange = Color(0xFFFF6B35);
  
  // Couleurs inversées pour mode sombre (rouge devient jaune, jaune devient rouge)
  static const Color darkModeRed = Color(0xFFFFD700); // Jaune en mode sombre
  static const Color darkModeYellow = Color(0xFFE53E3E); // Rouge en mode sombre
  
  // Couleurs de fond
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color lightCardBackground = Color(0xFFF8F9FA);
  
  // Couleurs pour mode sombre
  static const Color darkSurface = Color(0xFF0F0F0F);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2D2D2D);
  
  // Couleurs pour mode clair
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F5F5);
  static const Color lightBorder = Color(0xFFE0E0E0);
  
  // Gradients adaptatifs
  static LinearGradient getSplashGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark ? [
        const Color(0xFF0F0F0F),
        const Color(0xFF1A1A1A),
        const Color(0xFF2D2D2D),
      ] : [
        const Color(0xFFF8F9FA),
        const Color(0xFFE9ECEF),
        const Color(0xFFDEE2E6),
      ],
    );
  }
  
  static LinearGradient getButtonGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark ? [
        const Color(0xFFFF6B35),
        darkModeRed, // Jaune en mode sombre
      ] : [
        const Color(0xFFFF6B35),
        primaryRed,
      ],
    );
  }
  
  static LinearGradient getSeparatorGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark ? [
        darkModeYellow, // Rouge en mode sombre
        darkModeRed, // Jaune en mode sombre
      ] : [
        primaryYellow,
        primaryRed,
      ],
    );
  }
  
  // Couleurs de service
  static const Color restaurantColor = Color(0xFFFFB3BA);
  static const Color truckFoodColor = Color(0xFFFFE5B3);
  static const Color supermarketColor = Color(0xFFB3FFB3);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  // Couleurs adaptatives
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkSurface 
        : lightSurface;
  }
  
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCard 
        : lightCard;
  }
  
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorder 
        : lightBorder;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black87;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[300]! 
        : Colors.grey[600]!;
  }
  
  // Couleurs principales adaptatives
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkModeRed // Jaune en mode sombre
        : primaryRed;
  }
  
  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkModeYellow // Rouge en mode sombre
        : primaryYellow;
  }
  
  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkModeRed // Jaune en mode sombre
        : primaryOrange;
  }
  
  // Couleurs de texte adaptatives
  static Color getTextDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF2D2D2D);
  }
  
  // Couleurs de fond adaptatives
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : lightSurface;
  }
  
  static Color getLightCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCard 
        : lightCardBackground;
  }
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
}
