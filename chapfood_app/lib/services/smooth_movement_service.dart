import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Service pour gérer les mouvements fluides des marqueurs sur la carte
class SmoothMovementService {
  static final Map<String, _MovementController> _controllers = {};
  
  /// Démarre un mouvement fluide vers une nouvelle position
  static void startSmoothMovement({
    required String markerId,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required Duration duration,
    required Function(double lat, double lng) onPositionUpdate,
    Curve curve = Curves.easeInOut,
  }) {
    // Annuler le mouvement précédent s'il existe
    _controllers[markerId]?.cancel();
    
    // Créer un nouveau contrôleur de mouvement
    final controller = _MovementController(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      duration: duration,
      onPositionUpdate: onPositionUpdate,
      curve: curve,
    );
    
    _controllers[markerId] = controller;
    controller.start();
  }
  
  /// Annule un mouvement en cours
  static void cancelMovement(String markerId) {
    _controllers[markerId]?.cancel();
    _controllers.remove(markerId);
  }
  
  /// Annule tous les mouvements
  static void cancelAllMovements() {
    for (final controller in _controllers.values) {
      controller.cancel();
    }
    _controllers.clear();
  }
  
  /// Calcule la distance entre deux points en mètres
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calcule la durée optimale pour un mouvement basé sur la distance
  static Duration calculateOptimalDuration(double distanceInMeters) {
    // Vitesse moyenne de déplacement (m/s)
    const double averageSpeed = 8.0; // ~30 km/h
    
    // Durée minimale et maximale
    const Duration minDuration = Duration(milliseconds: 500);
    const Duration maxDuration = Duration(seconds: 10);
    
    final double calculatedSeconds = distanceInMeters / averageSpeed;
    final Duration calculatedDuration = Duration(milliseconds: (calculatedSeconds * 1000).round());
    
    if (calculatedDuration < minDuration) return minDuration;
    if (calculatedDuration > maxDuration) return maxDuration;
    
    return calculatedDuration;
  }
  
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

/// Contrôleur pour gérer un mouvement fluide individuel
class _MovementController {
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final Duration duration;
  final Function(double lat, double lng) onPositionUpdate;
  final Curve curve;
  
  Timer? _timer;
  DateTime? _startTime;
  
  _MovementController({
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.duration,
    required this.onPositionUpdate,
    required this.curve,
  });
  
  void start() {
    _startTime = DateTime.now();
    
    // Utiliser un timer pour des mises à jour fluides
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(_startTime!);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      // Appliquer la courbe d'animation
      final curvedProgress = curve.transform(progress);
      
      // Interpoler la position
      final currentLat = _interpolate(fromLat, toLat, curvedProgress);
      final currentLng = _interpolate(fromLng, toLng, curvedProgress);
      
      // Mettre à jour la position
      onPositionUpdate(currentLat, currentLng);
      
      // Arrêter le timer si le mouvement est terminé
      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }
  
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
  
  double _interpolate(double start, double end, double progress) {
    return start + (end - start) * progress;
  }
}

/// Service pour gérer les animations de route
class RouteAnimationService {
  static Timer? _routeAnimationTimer;
  static int _currentRouteIndex = 0;
  static List<Map<String, double>> _routePoints = [];
  
  /// Anime le tracé de la route progressivement
  static void animateRoute({
    required List<Map<String, double>> routePoints,
    required Function(List<Map<String, double>> visiblePoints) onRouteUpdate,
    Duration interval = const Duration(milliseconds: 50),
  }) {
    _routePoints = routePoints;
    _currentRouteIndex = 0;
    
    _routeAnimationTimer?.cancel();
    _routeAnimationTimer = Timer.periodic(interval, (timer) {
      if (_currentRouteIndex < _routePoints.length) {
        final visiblePoints = _routePoints.take(_currentRouteIndex + 1).toList();
        onRouteUpdate(visiblePoints);
        _currentRouteIndex++;
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Arrête l'animation de route
  static void stopRouteAnimation() {
    _routeAnimationTimer?.cancel();
    _routeAnimationTimer = null;
  }
  
  /// Anime l'itinéraire avec un effet de "dessin progressif"
  static void animateRouteProgressive({
    required List<Map<String, double>> routePoints,
    required Function(List<Map<String, double>> visiblePoints) onRouteUpdate,
    Duration totalDuration = const Duration(seconds: 3),
  }) {
    _routePoints = routePoints;
    _currentRouteIndex = 0;
    
    final int totalSteps = routePoints.length;
    final Duration stepDuration = Duration(
      milliseconds: (totalDuration.inMilliseconds / totalSteps).round(),
    );
    
    _routeAnimationTimer?.cancel();
    _routeAnimationTimer = Timer.periodic(stepDuration, (timer) {
      if (_currentRouteIndex < _routePoints.length) {
        final visiblePoints = _routePoints.take(_currentRouteIndex + 1).toList();
        onRouteUpdate(visiblePoints);
        _currentRouteIndex++;
      } else {
        timer.cancel();
      }
    });
  }
}
