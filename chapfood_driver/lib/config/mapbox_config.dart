import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration centralisée pour Mapbox
class MapboxConfig {
  // Clé d'accès Mapbox (à charger depuis .env)
  static String get accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // Styles de carte disponibles
  static const String styleStreets = 'mapbox://styles/mapbox/streets-v12';
  static const String styleOutdoors = 'mapbox://styles/mapbox/outdoors-v12';
  static const String styleLight = 'mapbox://styles/mapbox/light-v11';
  static const String styleDark = 'mapbox://styles/mapbox/dark-v11';
  static const String styleSatellite = 'mapbox://styles/mapbox/satellite-v9';
  static const String styleSatelliteStreets = 'mapbox://styles/mapbox/satellite-streets-v12';

  // Configuration par défaut
  static const double defaultZoom = 13.0;
  static const double defaultLat = 5.226313; // Restaurant ChapFood Grand Bassam
  static const double defaultLng = -3.768063;

  // Configuration des marqueurs
  static const double markerSize = 48.0;
  
  // Couleurs des marqueurs
  static const int driverMarkerColor = 0xFFFBBF24; // Jaune (yellow-500)
  static const int restaurantMarkerColor = 0xFFF97316; // Orange (orange-500)
  static const int clientMarkerColor = 0xFFEF4444; // Rouge (red-500)

  // Configuration de la route
  static const int routeColor = 0xFF3B82F6; // Bleu (blue-500)
  static const double routeWidth = 6.0;
  static const double routeOpacity = 0.95;

  // URL de base pour l'API Directions
  static const String directionsApiBaseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  
  /// Construit l'URL complète pour l'API Directions
  static String getDirectionsUrl({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String mode = 'driving',
    bool steps = true,
    String overview = 'full',
  }) {
    final coordinates = '$startLng,$startLat;$endLng,$endLat';
    return '$directionsApiBaseUrl/$mode/$coordinates'
        '?geometries=geojson'
        '&overview=$overview'
        '${steps ? '&steps=true' : ''}'
        '&access_token=$accessToken';
  }
}
