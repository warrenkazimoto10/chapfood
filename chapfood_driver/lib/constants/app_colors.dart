import 'package:flutter/material.dart';

/// Système de couleurs amélioré pour ChapFood Driver
class AppColors {
  // Couleurs principales ChapFood (basées sur le logo)
  static const Color primaryRed = Color(0xFFE53E3E); // Rouge principal ChapFood
  static const Color primaryOrange = Color(0xFFFF6B35); // Orange ChapFood
  static const Color primaryRedLight = Color(0xFFFC8181);
  static const Color primaryRedDark = Color(0xFFC53030);
  
  // Couleurs de fond
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF1A1A1A); // Alias pour compatibilité
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2D2D2D);
  
  // Couleurs d'accent
  static const Color accentGreen = Color(0xFF38A169);
  static const Color accentBlue = Color(0xFF3182CE);
  static const Color accentOrange = Color(0xFFDD6B20);
  static const Color accentPurple = Color(0xFF805AD5);
  static const Color accentYellow = Color(0xFFED8936); // Alias pour compatibilité
  
  // Couleurs de statut
  static const Color successGreen = Color(0xFF48BB78);
  static const Color successColor = Color(0xFF48BB78); // Alias pour compatibilité
  static const Color warningYellow = Color(0xFFED8936);
  static const Color errorRed = Color(0xFFF56565);
  static const Color errorColor = Color(0xFFF56565); // Alias pour compatibilité
  static const Color infoBlue = Color(0xFF4299E1);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFFF7FAFC);
  static const Color deepBlack = Color(0xFF000000); // Alias pour compatibilité
  static const Color mediumGray = Color(0xFF718096); // Alias pour compatibilité
  
  // Couleurs de bordure
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF4A5568);
  static const Color lightGray = Color(0xFFE2E8F0);
  
  // Gradients ChapFood
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryRed, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryRed, primaryRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    colors: [primaryRed, primaryRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient loginGradient = LinearGradient(
    colors: [primaryRed, primaryRedDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentBlue, infoBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [accentOrange, warningYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Ombres
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryRed.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  // Couleurs pour les thèmes
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF2D3748);
  
  // Couleurs d'état pour les notifications
  static const Color notificationSuccess = successGreen;
  static const Color notificationWarning = warningYellow;
  static const Color notificationError = errorRed;
  static const Color notificationInfo = infoBlue;
}