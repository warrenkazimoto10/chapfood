import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service pour obtenir les routes réelles depuis l'API Mapbox Directions
class MapboxDirectionsService {
  // Clé API Mapbox : définir via variable d'environnement ou .env (MAPBOX_ACCESS_TOKEN)
  // Ne jamais commiter de token réel. Exemple local : dotenv.env['MAPBOX_ACCESS_TOKEN']
  static String get _mapboxAccessToken =>
      const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  /// Obtient une route entre deux points en utilisant l'API Mapbox Directions
  static Future<List<List<double>>?> getRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      debugPrint('🗺️ Génération de route Mapbox:');
      debugPrint('📍 Départ: $startLatitude, $startLongitude');
      debugPrint('📍 Arrivée: $endLatitude, $endLongitude');

      // Construire l'URL de l'API Mapbox Directions
      final url =
          'https://api.mapbox.com/directions/v5/mapbox/$profile/$startLongitude,$startLatitude;$endLongitude,$endLatitude?'
          'access_token=$_mapboxAccessToken&'
          'geometries=geojson&'
          'steps=false&'
          'overview=full&'
          'continue_straight=false'; // Permet les virages pour éviter les routes droites

      // Faire la requête HTTP
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final routeData = jsonDecode(responseBody);

        // Extraire les coordonnées de la route
        if (routeData['routes'] != null && routeData['routes'].isNotEmpty) {
          final route = routeData['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convertir les coordonnées en format [[lng, lat], ...]
          final routeCoordinates = coordinates
              .map<List<double>>(
                (coord) => [
                  (coord[0] as num).toDouble(),
                  (coord[1] as num).toDouble(),
                ],
              )
              .toList();

          debugPrint(
            '✅ Route récupérée avec ${routeCoordinates.length} points',
          );
          debugPrint(
            '⏱️ Durée estimée: ${route['duration'] ?? 'N/A'} secondes',
          );
          debugPrint('📏 Distance: ${route['distance'] ?? 'N/A'} mètres');

          httpClient.close();
          return routeCoordinates;
        } else {
          throw Exception('Aucune route trouvée dans la réponse');
        }
      } else {
        throw Exception(
          'Erreur API Mapbox: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la génération de route: $e');
      return null;
    }
  }

  /// Obtient plusieurs routes alternatives
  static Future<List<List<List<double>>>?> getAlternativeRoutes({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String profile = 'driving',
    int alternatives = 3,
  }) async {
    try {
      final url =
          'https://api.mapbox.com/directions/v5/mapbox/$profile/$startLongitude,$startLatitude;$endLongitude,$endLatitude?'
          'access_token=$_mapboxAccessToken&'
          'geometries=geojson&'
          'steps=false&'
          'overview=full&'
          'alternatives=$alternatives';

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final routeData = jsonDecode(responseBody);

        final routes = routeData['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final alternativeRoutes = routes.map((route) {
            final geometry = route['geometry'];
            final coordinates = geometry['coordinates'] as List;
            return coordinates
                .map<List<double>>(
                  (coord) => [
                    (coord[0] as num).toDouble(),
                    (coord[1] as num).toDouble(),
                  ],
                )
                .toList();
          }).toList();

          debugPrint(
            '✅ ${alternativeRoutes.length} routes alternatives récupérées',
          );
          httpClient.close();
          return alternativeRoutes;
        }
      }

      httpClient.close();
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la génération de routes alternatives: $e');
      return null;
    }
  }

  /// Calcule la distance et la durée entre deux points
  static Future<Map<String, dynamic>?> getRouteInfo({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String profile = 'driving',
  }) async {
    try {
      final url =
          'https://api.mapbox.com/directions/v5/mapbox/$profile/$startLongitude,$startLatitude;$endLongitude,$endLatitude?'
          'access_token=$_mapboxAccessToken&'
          'steps=false&'
          'overview=false'; // Pas besoin de la géométrie complète

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final routeData = jsonDecode(responseBody);

        if (routeData['routes'] != null && routeData['routes'].isNotEmpty) {
          final route = routeData['routes'][0];

          httpClient.close();
          return {
            'distance': route['distance'], // en mètres
            'duration': route['duration'], // en secondes
            'duration_text': _formatDuration(route['duration']),
            'distance_text': _formatDistance(route['distance']),
          };
        }
      }

      httpClient.close();
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul des informations de route: $e');
      return null;
    }
  }

  /// Formate la durée en texte lisible
  static String _formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Formate la distance en texte lisible
  static String _formatDistance(double? meters) {
    if (meters == null) return 'N/A';

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }
}
