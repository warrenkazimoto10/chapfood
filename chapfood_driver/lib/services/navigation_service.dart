import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'osrm_routing_service.dart';

/// Service pour gérer le mode navigation avec itinéraire et caméra 3D
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // État du mode navigation
  bool _isNavigationActive = false;
  List<Map<String, dynamic>> _currentRoute = [];
  List<double> _bearingHistory = [];

  // Getters
  bool get isNavigationActive => _isNavigationActive;
  List<Map<String, double>> get currentRouteCoordinates => _currentRoute
      .map(
        (routePoint) => {
          'latitude': routePoint['latitude'] as double,
          'longitude': routePoint['longitude'] as double,
        },
      )
      .toList();

  /// Active le mode navigation
  void startNavigation({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    _isNavigationActive = true;
    print('🚀 Mode navigation activé');

    // Calculer l'itinéraire
    await _calculateRoute(startLat, startLng, endLat, endLng);
  }

  /// Désactive le mode navigation
  void stopNavigation() {
    _isNavigationActive = false;
    _currentRoute.clear();
    _bearingHistory.clear();
    print('🛑 Mode navigation désactivé');
  }

  /// Calcule l'itinéraire entre deux points
  Future<void> _calculateRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      // Utiliser OSRM (OpenStreetMap) pour le routage
      final routeInfo = await OsrmRoutingService.getRouteWithInfo(
        originLat: startLat,
        originLng: startLng,
        destLat: endLat,
        destLng: endLng,
      );

      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        _currentRoute = routeInfo.coordinates
            .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
            .toList();

        print('🛣️ Itinéraire calculé: ${_currentRoute.length} points');
        print('📏 Distance: ${routeInfo.formattedDistance}');
        print('⏱️ Durée: ${routeInfo.formattedDuration}');
      } else {
        print('❌ Aucun itinéraire trouvé, génération d\'une route simple');
        // En cas d'erreur API, générer une route simple
        _currentRoute = _decodePolylineSimple(
          startLat,
          startLng,
          endLat,
          endLng,
        );
      }
    } catch (e) {
      print('❌ Exception calcul itinéraire: $e');
      // En cas d'exception, générer une route simple
      _currentRoute = _decodePolylineSimple(startLat, startLng, endLat, endLng);
    }
  }

  /// Génère une route simple entre deux points (pour démo)
  List<Map<String, dynamic>> _decodePolylineSimple(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    List<Map<String, dynamic>> coordinates = [];

    try {
      // Générer plus de points pour une ligne plus lisse et courbe
      final int steps = 50; // Plus de points pour un rendu fluide

      for (int i = 0; i <= steps; i++) {
        final ratio = i / steps;

        // Créer une légère courbe pour simuler le suivi de route
        double curveFactor = 0.0001; // Modulation de la courbe
        double latOffset = math.sin(ratio * math.pi) * curveFactor;
        double lngOffset =
            math.cos(ratio * math.pi) * curveFactor * (endLng - startLng);

        coordinates.add({
          'latitude': startLat + (endLat - startLat) * ratio + latOffset,
          'longitude': startLng + (endLng - startLng) * ratio + lngOffset,
        });
      }

      print('🛣️ Route courbe générée: ${coordinates.length} points');
    } catch (e) {
      print('❌ Erreur génération route: $e');
    }

    return coordinates;
  }

  /// Décode un polyline en coordonnées latitude/longitude
  List<Map<String, dynamic>> _decodePolyline(String polyline) {
    List<Map<String, dynamic>> coordinates = [];

    try {
      // Simulation de points d'itinéraire (à remplacer par le vrai décodage)
      final startLat = 0.0; // Remplacer par vraies coordonnées start
      final startLng = 0.0;
      final endLat = 1.0; // Remplacer par vraies coordonnées end
      final endLng = 1.0;

      for (double i = 0; i <= 10; i++) {
        coordinates.add({
          'latitude': startLat + (endLat - startLat) * (i / 10),
          'longitude': startLng + (endLng - startLng) * (i / 10),
        });
      }
    } catch (e) {
      print('❌ Erreur décodage polyline: $e');
    }

    return coordinates;
  }

  /// Calcule le bearing (direction) entre deux points
  double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = math.pi / 180 * (lng2 - lng1);
    final lat1Rad = math.pi / 180 * lat1;
    final lat2Rad = math.pi / 180 * lat2;

    final y = math.sin(dLng) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;

    return (bearing + 360) % 360; // Normaliser à 0-360°
  }

  /// Calcule le zoom dynamique basé sur la vitesse
  double calculateDynamicZoom(double speedKmH) {
    if (speedKmH > 30) return 15.0; // Route rapide
    if (speedKmH > 15) return 16.0; // Route normale
    if (speedKmH > 5) return 17.0; // Circulation lente
    return 18.0; // Arrêt/stationnement
  }

  /// Génère une géometrie GeoJSON pour l'itinéraire
  Map<String, dynamic> generateRouteGeoJson() {
    if (_currentRoute.isEmpty)
      return {'type': 'FeatureCollection', 'features': []};

    final coordinates = _currentRoute
        .map(
          (point) => [
            point['longitude'] as double,
            point['latitude'] as double,
          ],
        )
        .toList();

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
          'properties': {
            // Couleurs ChapFood avec gradient
            'stroke': '#E53E3E',
            'stroke-width': 8,
            'stroke-opacity': 0.9,
            // Style moderne avec effet de lueur
            'fill': '#FF6B35',
            'fill-opacity': 0.1,
          },
        },
      ],
    };
  }

  /// Génère une route mise à jour en temps réel (restante)
  List<Map<String, dynamic>> getUpdatedRoutePoints(
    double currentLat,
    double currentLng,
  ) {
    if (_currentRoute.isEmpty) return [];

    // Trouver l'index le plus proche de la position actuelle
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < _currentRoute.length; i++) {
      final point = _currentRoute[i];
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;

      final distance = _calculateDistance(currentLat, currentLng, lat, lng);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Retourner seulement les points restants
    List<Map<String, dynamic>> remainingPoints = [];
    for (int i = nearestIndex; i < _currentRoute.length; i++) {
      remainingPoints.add(_currentRoute[i]);
    }

    return remainingPoints;
  }

  /// Obtenir le prochain point d'itinéraire proche d'une position
  Map<String, double>? getNextRoutePoint(double currentLat, double currentLng) {
    if (_currentRoute.isEmpty) return null;

    double minDistance = double.infinity;
    Map<String, dynamic>? closestPoint;
    int currentIndex = 0;

    for (int i = 0; i < _currentRoute.length; i++) {
      final point = _currentRoute[i];
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;

      final distance = _calculateDistance(currentLat, currentLng, lat, lng);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
        currentIndex = i;
      }
    }

    // Retourner le point suivant sur l'itinéraire
    int nextIndex = math.min(currentIndex + 5, _currentRoute.length - 1);
    final nextPoint = _currentRoute[nextIndex];
    return {
      'latitude': nextPoint['latitude'] as double,
      'longitude': nextPoint['longitude'] as double,
    };
  }

  /// Calcule la distance entre deux points (approximation)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double R = 6371000; // Rayon de la Terre en mètres
    final dLat = math.pi / 180 * (lat2 - lat1);
    final dLng = math.pi / 180 * (lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(math.pi / 180 * lat1) *
            math.cos(math.pi / 180 * lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
