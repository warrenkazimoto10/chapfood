class AppConstants {
  // Durées
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration debounceDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration locationUpdateInterval = Duration(seconds: 5);

  // Distances
  static const double distanceFilter = 5.0; // 5 mètres
  static const double targetMarkerSize = 48.0; // Taille du marker en pixels

  // Zoom
  static const double defaultZoom = 15.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 10.0;

  // Carte (OSM / flutter_map)
  static const String markerImageName = "driver-marker";
  static const String defaultMarkerImage = "marker-15";

  // Supabase
  static const String driversTable = 'drivers';
  static const String ordersTable = 'orders';
  static const String orderDriverAssignmentsTable = 'order_driver_assignments';

  // Realtime Channels
  static const String driverPositionsChannel = 'driver_positions';
  static const String orderNotificationsChannel = 'order_notifications';

  // Cache
  static const String offlineBoxName = 'driver_updates';
  static const int maxOfflineUpdates = 100;

  // UI
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 25.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 60.0;

  // Animations
  static const double scaleAnimationValue = 0.95;
  static const Duration fadeAnimationDuration = Duration(milliseconds: 200);

  // Network
  static const Duration networkTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;

  // Location
  static const double locationAccuracy = 5.0; // mètres
  static const Duration locationTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPhoneNumberLength = 15;
  static const int deliveryCodeLength = 6;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Error Messages
  static const String networkErrorMessage = 'Problème de connexion réseau';
  static const String locationErrorMessage =
      'Impossible d\'obtenir votre position';
  static const String permissionErrorMessage =
      'Permissions de localisation refusées';
  static const String genericErrorMessage = 'Une erreur est survenue';

  // Success Messages
  static const String statusUpdateSuccessMessage =
      'Statut mis à jour avec succès';
  static const String positionUpdateSuccessMessage = 'Position mise à jour';
  static const String orderAcceptedMessage = 'Commande acceptée';
  static const String deliveryCompletedMessage = 'Livraison terminée';
}
