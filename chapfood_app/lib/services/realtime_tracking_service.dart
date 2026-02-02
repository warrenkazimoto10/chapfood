import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service de suivi en temps réel du livreur
/// Simule le mouvement fluide comme Google Maps
class RealtimeTrackingService {
  static final RealtimeTrackingService _instance =
      RealtimeTrackingService._internal();
  factory RealtimeTrackingService() => _instance;
  RealtimeTrackingService._internal();

  Timer? _positionTimer;
  StreamController<DriverPosition>? _positionController;
  bool _isTracking = false;

  // Position actuelle du livreur
  double _currentLat = 5.3563; // Latitude d'Abidjan
  double _currentLng = -4.0363; // Longitude d'Abidjan
  double _currentHeading = 0.0; // Direction en degrés
  double _currentSpeed = 0.0; // Vitesse en km/h

  // Route simulée (points de passage)
  final List<Map<String, double>> _routePoints = [
    {'lat': 5.3563, 'lng': -4.0363}, // Restaurant
    {'lat': 5.3600, 'lng': -4.0300},
    {'lat': 5.3650, 'lng': -4.0250},
    {'lat': 5.3700, 'lng': -4.0200}, // Destination
  ];

  int _currentRouteIndex = 0;
  double _routeProgress = 0.0; // Progression entre 0.0 et 1.0

  /// Stream des positions du livreur
  Stream<DriverPosition> get positionStream {
    _positionController ??= StreamController<DriverPosition>.broadcast();
    return _positionController!.stream;
  }

  /// Démarre le suivi en temps réel (mode statique pour éviter la simulation)
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _positionController ??= StreamController<DriverPosition>.broadcast();

    // Émettre la position actuelle une seule fois (pas de simulation)
    _emitCurrentPosition();

    debugPrint('🚚 Suivi temps réel démarré (mode statique)');
  }

  /// Émet la position actuelle sans simulation
  void _emitCurrentPosition() {
    if (!_isTracking) return;

    // Créer l'objet position avec vitesse à 0
    final position = DriverPosition(
      latitude: _currentLat,
      longitude: _currentLng,
      heading: _currentHeading,
      speed: 0.0, // Vitesse à 0 car le livreur est statique
      timestamp: DateTime.now(),
      routeProgress: _routeProgress,
      currentRouteIndex: _currentRouteIndex,
      totalRoutePoints: _routePoints.length,
    );

    // Émettre la position
    _positionController?.add(position);
  }

  /// Arrête le suivi
  void stopTracking() {
    _isTracking = false;
    _positionTimer?.cancel();
    _positionTimer = null;

    debugPrint('🚚 Suivi temps réel arrêté');
  }

  // Méthode supprimée car nous utilisons le mode statique

  /// Calcule la direction (bearing) entre deux points
  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * (pi / 180);
    final lat1Rad = lat1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);

    final y = sin(dLng) * cos(lat2Rad);
    final x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLng);

    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360; // Normaliser entre 0 et 360
  }

  /// Réinitialise le suivi
  void resetTracking() {
    stopTracking();
    _currentRouteIndex = 0;
    _routeProgress = 0.0;
    _currentLat = 5.3563;
    _currentLng = -4.0363;
    _currentHeading = 0.0;
    _currentSpeed = 0.0;

    debugPrint('🚚 Suivi réinitialisé');
  }

  /// Définit une nouvelle route
  void setRoute(List<Map<String, double>> routePoints) {
    _routePoints.clear();
    _routePoints.addAll(routePoints);
    resetTracking();

    debugPrint('🚚 Nouvelle route définie: ${routePoints.length} points');
  }

  /// Obtient la position actuelle
  DriverPosition getCurrentPosition() {
    return DriverPosition(
      latitude: _currentLat,
      longitude: _currentLng,
      heading: _currentHeading,
      speed: _currentSpeed,
      timestamp: DateTime.now(),
      routeProgress: _routeProgress,
      currentRouteIndex: _currentRouteIndex,
      totalRoutePoints: _routePoints.length,
    );
  }

  /// Vérifie si le suivi est actif
  bool get isTracking => _isTracking;

  /// Obtient la progression de la route (0.0 à 1.0)
  double get routeProgress => _routeProgress;

  /// Obtient l'index du point actuel
  int get currentRouteIndex => _currentRouteIndex;

  /// Obtient le nombre total de points
  int get totalRoutePoints => _routePoints.length;

  /// Libère les ressources
  void dispose() {
    stopTracking();
    _positionController?.close();
    _positionController = null;

    debugPrint('🚚 Service de suivi libéré');
  }
}

/// Modèle de données pour la position du livreur
class DriverPosition {
  final double latitude;
  final double longitude;
  final double heading; // Direction en degrés (0-360)
  final double speed; // Vitesse en km/h
  final DateTime timestamp;
  final double routeProgress; // Progression entre 0.0 et 1.0
  final int currentRouteIndex;
  final int totalRoutePoints;

  DriverPosition({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
    required this.routeProgress,
    required this.currentRouteIndex,
    required this.totalRoutePoints,
  });

  /// Calcule la distance depuis le restaurant
  double getDistanceFromRestaurant() {
    // Position du restaurant
    const restaurantLat = 5.3563;
    const restaurantLng = -4.0363;

    return _calculateDistance(
      restaurantLat,
      restaurantLng,
      latitude,
      longitude,
    );
  }

  /// Calcule la distance jusqu'à la destination
  double getDistanceToDestination() {
    // Position de destination (dernier point de route)
    const destinationLat = 5.3700;
    const destinationLng = -4.0200;

    return _calculateDistance(
      latitude,
      longitude,
      destinationLat,
      destinationLng,
    );
  }

  /// Calcule la distance entre deux points en kilomètres
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Obtient le statut de livraison
  String getDeliveryStatus() {
    if (routeProgress < 0.3) {
      return 'En route vers vous';
    } else if (routeProgress < 0.8) {
      return 'Proche de chez vous';
    } else if (routeProgress < 1.0) {
      return 'Arrivé dans votre quartier';
    } else {
      return 'Arrivé à destination';
    }
  }

  /// Obtient le temps estimé d'arrivée
  String getEstimatedArrival() {
    final distance = getDistanceToDestination();

    // Éviter la division par zéro
    if (speed <= 0 || !speed.isFinite) {
      return 'Position statique';
    }

    final timeInMinutes = (distance / speed * 60).round();

    // Vérifier que le résultat est valide
    if (!timeInMinutes.isFinite || timeInMinutes.isNaN) {
      return 'Calcul impossible';
    }

    if (timeInMinutes < 1) {
      return 'Arrivé';
    } else if (timeInMinutes < 60) {
      return '$timeInMinutes min';
    } else {
      final hours = timeInMinutes ~/ 60;
      final minutes = timeInMinutes % 60;
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'DriverPosition(lat: $latitude, lng: $longitude, heading: ${heading.toStringAsFixed(1)}°, speed: ${speed.toStringAsFixed(1)} km/h, progress: ${(routeProgress * 100).toStringAsFixed(1)}%)';
  }
}
