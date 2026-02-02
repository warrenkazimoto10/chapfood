// Configuration de l'application ChapFood Driver
class AppConfig {
  // URLs et clés API
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String mapboxAccessToken = 'YOUR_MAPBOX_ACCESS_TOKEN';
  
  // Configuration de l'application
  static const String appName = 'ChapFood Driver';
  static const String appVersion = '1.0.0';
  
  // Configuration des couleurs
  static const int primaryColorValue = 0xFFE94560; // Rouge ChapFood
  static const int secondaryColorValue = 0xFFFFD700; // Or ChapFood
  static const int darkColorValue = 0xFF1A1A2E; // Bleu foncé
  
  // Configuration de la localisation
  static const double defaultLatitude = 5.2038; // Grand Bassam
  static const double defaultLongitude = -4.1339;
  static const double defaultZoom = 15.0;
  
  // Configuration des notifications
  static const Duration notificationTimeout = Duration(seconds: 5);
  static const int maxNotifications = 50;
  
  // Configuration du suivi de position
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const double locationAccuracyThreshold = 50.0; // mètres
  
  // Configuration des commandes
  static const int maxOrdersPerPage = 20;
  static const Duration orderRefreshInterval = Duration(seconds: 30);
  
  // Configuration de l'interface
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Messages d'erreur
  static const String networkErrorMessage = 'Erreur de connexion réseau';
  static const String locationErrorMessage = 'Impossible d\'obtenir votre position';
  static const String authenticationErrorMessage = 'Erreur d\'authentification';
  static const String generalErrorMessage = 'Une erreur est survenue';
  
  // Messages de succès
  static const String loginSuccessMessage = 'Connexion réussie';
  static const String logoutSuccessMessage = 'Déconnexion réussie';
  static const String orderUpdateSuccessMessage = 'Commande mise à jour';
  
  // Configuration des permissions
  static const List<String> requiredPermissions = [
    'location',
    'notification',
  ];
}
