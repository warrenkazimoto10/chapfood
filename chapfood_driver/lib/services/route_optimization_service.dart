import 'package:geolocator/geolocator.dart' as geo;
import 'osrm_routing_service.dart';

/// Service pour optimiser et recalculer les routes automatiquement
class RouteOptimizationService {
  /// Vérifie si le livreur s'est écarté de la route et recalcule si nécessaire
  static Future<OsrmRouteInfo?> checkAndRecalculateRoute({
    required geo.Position currentPosition,
    required List<geo.Position> routeCoordinates,
    required double
    maxDeviationMeters, // Distance maximale avant recalcul (par défaut 100m)
  }) async {
    // Trouver le point le plus proche sur la route
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < routeCoordinates.length; i++) {
      final distance = geo.Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        routeCoordinates[i].latitude,
        routeCoordinates[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Si le livreur s'est écarté de plus de maxDeviationMeters, recalculer
    if (minDistance > maxDeviationMeters) {
      print(
        '🔄 Livreur écarté de ${minDistance.toStringAsFixed(0)}m, recalcul de la route...',
      );

      // Trouver le point de destination (dernier point de la route)
      final destination = routeCoordinates.last;

      // Recalculer la route depuis la position actuelle (OSRM)
      return await OsrmRoutingService.getRouteWithInfo(
        originLat: currentPosition.latitude,
        originLng: currentPosition.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );
    }

    return null; // Pas besoin de recalculer
  }

  /// Calcule la distance restante sur la route
  static double calculateRemainingDistance({
    required geo.Position currentPosition,
    required List<geo.Position> routeCoordinates,
  }) {
    if (routeCoordinates.isEmpty) return 0.0;

    // Trouver le point le plus proche sur la route
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < routeCoordinates.length; i++) {
      final distance = geo.Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        routeCoordinates[i].latitude,
        routeCoordinates[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Calculer la distance totale depuis le point le plus proche jusqu'à la destination
    double totalDistance = 0.0;
    for (int i = nearestIndex; i < routeCoordinates.length - 1; i++) {
      totalDistance += geo.Geolocator.distanceBetween(
        routeCoordinates[i].latitude,
        routeCoordinates[i].longitude,
        routeCoordinates[i + 1].latitude,
        routeCoordinates[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  /// Calcule l'ETA basé sur la distance restante et la vitesse moyenne
  static Duration calculateETA({
    required double remainingDistance, // en mètres
    double averageSpeedKmh = 30.0, // Vitesse moyenne en km/h
  }) {
    // Convertir la vitesse en m/s
    final speedMs = (averageSpeedKmh * 1000) / 3600;

    // Calculer le temps en secondes
    final timeSeconds = (remainingDistance / speedMs).round();

    return Duration(seconds: timeSeconds);
  }
}
