import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:logger/logger.dart';

class SmoothMovementService {
  static final SmoothMovementService _instance = SmoothMovementService._internal();
  factory SmoothMovementService() => _instance;
  SmoothMovementService._internal();

  final Logger _logger = Logger();
  
  // Configuration pour le mouvement fluide
  static const int _updateIntervalMs = 100; // Mise à jour toutes les 100ms
  static const double _minDistanceForUpdate = 1.0; // 1 mètre minimum
  static const double _maxSpeedKmh = 80.0; // Vitesse max pour interpolation
  
  Timer? _interpolationTimer;
  geo.Position? _lastRealPosition;
  geo.Position? _targetPosition;
  DateTime? _lastUpdateTime;
  
  final StreamController<geo.Position> _positionController = StreamController<geo.Position>.broadcast();
  
  // Getters
  Stream<geo.Position> get positionStream => _positionController.stream;
  geo.Position? get currentPosition => _targetPosition ?? _lastRealPosition;

  /// Démarre le service de mouvement fluide
  void startSmoothTracking(Stream<geo.Position> realPositionStream) {
    _logger.i('🚀 Démarrage du service de mouvement fluide');
    
    realPositionStream.listen((realPosition) {
      _handleNewRealPosition(realPosition);
    });
  }

  /// Arrête le service
  void stopSmoothTracking() {
    _interpolationTimer?.cancel();
    _interpolationTimer = null;
    _logger.i('⏹️ Arrêt du service de mouvement fluide');
  }

  /// Gère une nouvelle position réelle du GPS
  void _handleNewRealPosition(geo.Position realPosition) {
    final now = DateTime.now();
    
    // Si c'est la première position ou si on a bougé suffisamment
    if (_lastRealPosition == null || 
        _calculateDistance(_lastRealPosition!, realPosition) >= _minDistanceForUpdate) {
      
      _logger.d('📍 Nouvelle position réelle: ${realPosition.latitude}, ${realPosition.longitude}');
      
      // Si on avait une position cible, on commence l'interpolation depuis la position actuelle
      if (_targetPosition != null) {
        _lastRealPosition = _targetPosition;
      } else {
        _lastRealPosition = realPosition;
      }
      
      _targetPosition = realPosition;
      _lastUpdateTime = now;
      
      // Démarrer l'interpolation si elle n'est pas déjà en cours
      if (_interpolationTimer == null) {
        _startInterpolation();
      }
    }
  }

  /// Démarre l'interpolation entre les positions
  void _startInterpolation() {
    _interpolationTimer = Timer.periodic(
      Duration(milliseconds: _updateIntervalMs),
      (timer) {
        _interpolatePosition();
      },
    );
  }

  /// Interpole la position entre la dernière et la cible
  void _interpolatePosition() {
    if (_lastRealPosition == null || _targetPosition == null || _lastUpdateTime == null) {
      return;
    }

    final now = DateTime.now();
    final elapsedMs = now.difference(_lastUpdateTime!).inMilliseconds;
    
    // Calculer la distance et la vitesse
    final distance = _calculateDistance(_lastRealPosition!, _targetPosition!);
    final speed = _calculateSpeed(_lastRealPosition!, _targetPosition!, elapsedMs);
    
    // Si on est très proche de la cible, on s'y rend directement
    if (distance < 0.5) {
      _emitPosition(_targetPosition!);
      _lastRealPosition = _targetPosition;
      _targetPosition = null;
      _interpolationTimer?.cancel();
      _interpolationTimer = null;
      return;
    }
    
    // Calculer le facteur d'interpolation basé sur la vitesse
    final interpolationFactor = _calculateInterpolationFactor(distance, speed, elapsedMs);
    
    // Interpoler la position
    final interpolatedPosition = _interpolateBetweenPositions(
      _lastRealPosition!,
      _targetPosition!,
      interpolationFactor,
    );
    
    _emitPosition(interpolatedPosition);
    
    // Si on a atteint la cible, arrêter l'interpolation
    if (interpolationFactor >= 1.0) {
      _lastRealPosition = _targetPosition;
      _targetPosition = null;
      _interpolationTimer?.cancel();
      _interpolationTimer = null;
    }
  }

  /// Calcule le facteur d'interpolation
  double _calculateInterpolationFactor(double distance, double speed, int elapsedMs) {
    // Plus la vitesse est élevée, plus l'interpolation est rapide
    final speedFactor = math.min(speed / _maxSpeedKmh, 1.0);
    
    // Facteur basé sur le temps écoulé
    final timeFactor = elapsedMs / 1000.0; // Convertir en secondes
    
    // Facteur basé sur la distance
    final distanceFactor = math.min(distance / 50.0, 1.0); // 50m max pour interpolation
    
    // Combiner les facteurs
    final baseFactor = timeFactor * 0.1; // 10% par seconde
    final speedMultiplier = 1.0 + (speedFactor * 2.0); // Jusqu'à 3x plus rapide à haute vitesse
    final distanceMultiplier = 1.0 + (distanceFactor * 1.0); // Jusqu'à 2x plus rapide pour longues distances
    
    return math.min(baseFactor * speedMultiplier * distanceMultiplier, 1.0);
  }

  /// Interpole entre deux positions
  geo.Position _interpolateBetweenPositions(
    geo.Position from,
    geo.Position to,
    double factor,
  ) {
    final lat = from.latitude + (to.latitude - from.latitude) * factor;
    final lng = from.longitude + (to.longitude - from.longitude) * factor;
    
    // Interpoler aussi l'altitude et la précision si disponibles
    final altitude = from.altitude + (to.altitude - from.altitude) * factor;
    final accuracy = from.accuracy + (to.accuracy - from.accuracy) * factor;
    
    return geo.Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: altitude,
      altitudeAccuracy: from.altitudeAccuracy,
      heading: _interpolateHeading(from.heading, to.heading, factor),
      headingAccuracy: from.headingAccuracy,
      speed: _interpolateSpeed(from.speed, to.speed, factor),
      speedAccuracy: from.speedAccuracy,
    );
  }

  /// Interpole la direction (gère le passage par 0°/360°)
  double _interpolateHeading(double from, double to, double factor) {
    if (from.isNaN || to.isNaN) return from;
    
    double diff = to - from;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    
    return (from + diff * factor) % 360;
  }

  /// Interpole la vitesse
  double _interpolateSpeed(double from, double to, double factor) {
    if (from.isNaN || to.isNaN) return from;
    return from + (to - from) * factor;
  }

  /// Calcule la distance entre deux positions
  double _calculateDistance(geo.Position from, geo.Position to) {
    return geo.Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calcule la vitesse entre deux positions
  double _calculateSpeed(geo.Position from, geo.Position to, int elapsedMs) {
    if (elapsedMs <= 0) return 0.0;
    
    final distance = _calculateDistance(from, to);
    final timeHours = elapsedMs / (1000.0 * 3600.0); // Convertir en heures
    
    if (timeHours <= 0) return 0.0;
    
    return distance / 1000.0 / timeHours; // km/h
  }

  /// Émet une position interpolée
  void _emitPosition(geo.Position position) {
    _positionController.add(position);
  }

  /// Force une position immédiate (pour le centrage de carte)
  void forcePosition(geo.Position position) {
    _lastRealPosition = position;
    _targetPosition = null;
    _interpolationTimer?.cancel();
    _interpolationTimer = null;
    _emitPosition(position);
  }

  /// Libère les ressources
  void dispose() {
    stopSmoothTracking();
    _positionController.close();
  }
}

