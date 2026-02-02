import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de suivi en temps réel style Uber avec vraies positions
/// Récupère les positions réelles du livreur depuis la base de données
class UberStyleTrackingService {
  static final UberStyleTrackingService _instance =
      UberStyleTrackingService._internal();
  factory UberStyleTrackingService() => _instance;
  UberStyleTrackingService._internal();

  Timer? _positionTimer;
  StreamController<DriverPosition>? _positionController;
  bool _isTracking = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  bool _isRealtimeMode =
      true; // Mode Realtime par défaut, fallback vers polling si échec

  // Position actuelle du livreur
  double _currentLat = 5.3563;
  double _currentLng = -4.0363;
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0;
  DateTime? _lastPositionUpdate;

  // Route et progression
  List<Map<String, double>> _routePoints = [];
  int _currentRouteIndex = 0;
  double _routeProgress = 0.0; // Progression entre 0.0 et 1.0
  double _segmentProgress = 0.0; // Progression dans le segment actuel

  // Paramètres de simulation réaliste
  static const double _minSpeed = 5.0; // km/h minimum
  static const double _maxSpeed = 45.0; // km/h maximum
  static const double _averageSpeed = 25.0; // km/h moyenne
  static const Duration _updateInterval = Duration(
    seconds: 3,
  ); // Mise à jour toutes les 3 secondes en mode polling

  // ID du livreur et de la commande pour récupérer les vraies positions
  int? _driverId;

  // Timer pour vérifier que le Realtime fonctionne toujours
  Timer? _realtimeHealthCheckTimer;
  DateTime? _lastRealtimeUpdate;

  /// Stream des positions du livreur
  Stream<DriverPosition> get positionStream {
    _positionController ??= StreamController<DriverPosition>.broadcast();
    return _positionController!.stream;
  }

  /// Démarre le suivi en temps réel avec vraies positions
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _positionController ??= StreamController<DriverPosition>.broadcast();

    debugPrint('🚚 Suivi Uber-style démarré avec vraies positions');

    // Tenter de démarrer en mode Realtime
    if (_driverId != null) {
      _startRealtimeTracking();
    } else {
      debugPrint('⚠️ ID du livreur non défini, utilisation du mode polling');
      _isRealtimeMode = false;
      _startPollingMode();
    }

    // Émettre la position initiale
    _emitCurrentPosition();
  }

  /// Démarre le suivi en mode Realtime (temps réel véritable)
  void _startRealtimeTracking() {
    try {
      debugPrint('🔄 Tentative de connexion Realtime pour driver $_driverId');

      _realtimeChannel = _supabase
          .channel('driver_location_$_driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'drivers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: _driverId,
            ),
            callback: (payload) {
              _onRealtimePositionUpdate(payload.newRecord);
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Connexion Realtime établie avec succès');
              _isRealtimeMode = true;
              _lastRealtimeUpdate = DateTime.now();
              _startRealtimeHealthCheck();
            } else if (status == RealtimeSubscribeStatus.closed ||
                status == RealtimeSubscribeStatus.channelError) {
              debugPrint('❌ Échec connexion Realtime: $error');
              debugPrint('🔄 Basculement vers mode polling');
              _isRealtimeMode = false;
              _stopRealtimeHealthCheck();
              _startPollingMode();
              // Tentative de reconnexion après 5 secondes
              Future.delayed(const Duration(seconds: 5), () {
                if (_isTracking && _driverId != null && !_isRealtimeMode) {
                  debugPrint('🔄 Tentative de reconnexion Realtime...');
                  _startRealtimeTracking();
                }
              });
            }
          });

      // Récupérer la position initiale immédiatement
      _updateDriverPositionFromDB();
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage Realtime: $e');
      debugPrint('🔄 Basculement vers mode polling');
      _isRealtimeMode = false;
      _startPollingMode();
    }
  }

  /// Démarre le suivi en mode polling (fallback)
  void _startPollingMode() {
    // Annuler le timer existant s'il y en a un
    _positionTimer?.cancel();

    // Démarrer le timer de mise à jour en mode polling
    _isRealtimeMode = false;
    _positionTimer = Timer.periodic(_updateInterval, (_) {
      _updateDriverPositionFromDB();
    });

    debugPrint(
      '📊 Mode polling activé (mise à jour toutes les ${_updateInterval.inSeconds}s)',
    );
  }

  /// Gère les mises à jour de position en temps réel
  void _onRealtimePositionUpdate(Map<String, dynamic> data) {
    try {
      if (data['current_lat'] == null || data['current_lng'] == null) {
        debugPrint('⚠️ Position reçue incomplète');
        return;
      }

      final newLat = (data['current_lat'] as num).toDouble();
      final newLng = (data['current_lng'] as num).toDouble();
      final now = DateTime.now();

      debugPrint('📍 Position Realtime reçue: $newLat, $newLng');
      _isRealtimeMode = true;

      // Calculer la vitesse basée sur le déplacement
      if (_currentLat != 0 && _currentLng != 0 && _lastPositionUpdate != null) {
        final distance = _calculateDistance(
          _currentLat,
          _currentLng,
          newLat,
          newLng,
        );
        final timeDiff =
            now.difference(_lastPositionUpdate!).inSeconds / 3600.0;
        if (timeDiff > 0) {
          _currentSpeed = (distance / 1000 / timeDiff).clamp(
            _minSpeed,
            _maxSpeed,
          );
        }
      }

      // Mettre à jour la position
      _currentLat = newLat;
      _currentLng = newLng;
      _lastPositionUpdate = now;
      _lastRealtimeUpdate = now; // Marquer la dernière update Realtime

      // Calculer la progression sur la route
      _updateRouteProgress();

      // Émettre la nouvelle position
      _emitCurrentPosition();

      debugPrint('🚗 Vitesse: ${_currentSpeed.toStringAsFixed(1)} km/h');
    } catch (e) {
      debugPrint('❌ Erreur traitement position Realtime: $e');
    }
  }

  /// Met à jour la position du livreur depuis la base de données
  Future<void> _updateDriverPositionFromDB() async {
    if (!_isTracking || _driverId == null) return;

    try {
      // Récupérer la position actuelle du livreur depuis la base de données
      final response = await _supabase
          .from('drivers')
          .select('current_lat, current_lng, updated_at')
          .eq('id', _driverId!)
          .maybeSingle();

      if (response != null &&
          response['current_lat'] != null &&
          response['current_lng'] != null) {
        final newLat = (response['current_lat'] as num).toDouble();
        final newLng = (response['current_lng'] as num).toDouble();

        // Calculer la vitesse basée sur le déplacement
        if (_currentLat != 0 && _currentLng != 0) {
          final distance = _calculateDistance(
            _currentLat,
            _currentLng,
            newLat,
            newLng,
          );
          final timeDiff =
              _updateInterval.inSeconds / 3600.0; // Conversion en heures
          _currentSpeed = distance / 1000 / timeDiff; // Conversion en km/h
          _currentSpeed = _currentSpeed.clamp(_minSpeed, _maxSpeed);
        }

        // Mettre à jour la position
        _currentLat = newLat;
        _currentLng = newLng;

        // Calculer la progression sur la route
        _updateRouteProgress();

        debugPrint('📍 Position réelle récupérée: $_currentLat, $_currentLng');
        debugPrint(
          '🚗 Vitesse calculée: ${_currentSpeed.toStringAsFixed(1)} km/h',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la position: $e');
    }

    // Émettre la nouvelle position
    _emitCurrentPosition();
  }

  /// Met à jour la progression sur la route
  void _updateRouteProgress() {
    if (_routePoints.length < 2) return;

    // Calculer la distance totale de la route
    double totalDistance = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        _routePoints[i]['lat']!,
        _routePoints[i]['lng']!,
        _routePoints[i + 1]['lat']!,
        _routePoints[i + 1]['lng']!,
      );
    }

    // Calculer la distance parcourue depuis le début
    double distanceTraveled = 0.0;
    for (int i = 0; i < _currentRouteIndex; i++) {
      distanceTraveled += _calculateDistance(
        _routePoints[i]['lat']!,
        _routePoints[i]['lng']!,
        _routePoints[i + 1]['lat']!,
        _routePoints[i + 1]['lng']!,
      );
    }

    // Ajouter la distance dans le segment actuel
    if (_currentRouteIndex < _routePoints.length - 1) {
      distanceTraveled += _calculateDistance(
        _routePoints[_currentRouteIndex]['lat']!,
        _routePoints[_currentRouteIndex]['lng']!,
        _currentLat,
        _currentLng,
      );
    }

    // Calculer la progression
    _routeProgress = totalDistance > 0
        ? (distanceTraveled / totalDistance).clamp(0.0, 1.0)
        : 0.0;

    // Mettre à jour l'index de route
    _updateCurrentRouteIndex();
  }

  /// Met à jour l'index de route actuel
  void _updateCurrentRouteIndex() {
    if (_routePoints.length < 2) return;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _routePoints.length; i++) {
      final distance = _calculateDistance(
        _currentLat,
        _currentLng,
        _routePoints[i]['lat']!,
        _routePoints[i]['lng']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    _currentRouteIndex = closestIndex;
  }

  /// Calcule la distance entre deux points en mètres
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

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

  /// Émet la position actuelle
  void _emitCurrentPosition() {
    if (!_isTracking) return;

    final effectiveSpeed = _currentSpeed <= 0 ? _averageSpeed : _currentSpeed;

    final position = DriverPosition(
      latitude: _currentLat,
      longitude: _currentLng,
      heading: _currentHeading,
      speed: effectiveSpeed,
      timestamp: DateTime.now(),
      routeProgress: _routeProgress,
      currentRouteIndex: _currentRouteIndex,
      totalRoutePoints: _routePoints.length,
    );

    _positionController?.add(position);
  }

  /// Arrête le suivi
  void stopTracking() {
    _isTracking = false;
    _positionTimer?.cancel();
    _positionTimer = null;
    _stopRealtimeHealthCheck();

    // Nettoyer le channel Realtime
    if (_realtimeChannel != null) {
      try {
        _supabase.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
        debugPrint('🔌 Canal Realtime fermé');
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la fermeture du canal Realtime: $e');
      }
    }

    debugPrint('🚚 Suivi Uber-style arrêté');
  }

  /// Démarre la vérification de santé du Realtime
  void _startRealtimeHealthCheck() {
    _stopRealtimeHealthCheck();
    _realtimeHealthCheckTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) {
      if (!_isTracking || !_isRealtimeMode) {
        timer.cancel();
        return;
      }

      // Si aucune update Realtime depuis 15 secondes, basculer en polling
      if (_lastRealtimeUpdate == null ||
          DateTime.now().difference(_lastRealtimeUpdate!) >
              const Duration(seconds: 15)) {
        debugPrint(
          '⚠️ Aucune update Realtime depuis 15s, basculement en polling',
        );
        _isRealtimeMode = false;
        _stopRealtimeHealthCheck();
        _startPollingMode();
        // Tentative de reconnexion
        Future.delayed(const Duration(seconds: 5), () {
          if (_isTracking && _driverId != null && !_isRealtimeMode) {
            debugPrint('🔄 Reconnexion Realtime après timeout...');
            _startRealtimeTracking();
          }
        });
      }
    });
  }

  /// Arrête la vérification de santé du Realtime
  void _stopRealtimeHealthCheck() {
    _realtimeHealthCheckTimer?.cancel();
    _realtimeHealthCheckTimer = null;
  }

  /// Réinitialise le suivi
  void resetTracking() {
    stopTracking();
    _currentRouteIndex = 0;
    _routeProgress = 0.0;
    _segmentProgress = 0.0;
    _currentSpeed = 0.0;

    if (_routePoints.isNotEmpty) {
      _currentLat = _routePoints.first['lat']!;
      _currentLng = _routePoints.first['lng']!;
    }

    debugPrint('🚚 Suivi Uber-style réinitialisé');
  }

  /// Définit une nouvelle route
  void setRoute(List<Map<String, double>> routePoints) {
    _routePoints.clear();
    _routePoints.addAll(routePoints);

    // Initialiser la position au premier point
    if (_routePoints.isNotEmpty) {
      _currentLat = _routePoints.first['lat']!;
      _currentLng = _routePoints.first['lng']!;
    }

    resetTracking();

    debugPrint('🚚 Nouvelle route définie: ${routePoints.length} points');
  }

  /// Définit l'ID du livreur pour récupérer ses vraies positions
  void setDriverId(int driverId) {
    _driverId = driverId;
    debugPrint('🚚 ID du livreur défini: $driverId');
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

  /// Obtient le temps estimé d'arrivée (ETA)
  Duration getEstimatedTimeOfArrival() {
    if (_currentSpeed <= 0 || _routePoints.length < 2) {
      return const Duration(minutes: 0);
    }

    // Calculer la distance restante
    double remainingDistance = 0.0;

    // Distance du segment actuel
    if (_currentRouteIndex < _routePoints.length - 1) {
      final currentPoint = _routePoints[_currentRouteIndex];
      final nextPoint = _routePoints[_currentRouteIndex + 1];
      final segmentDistance = _calculateDistance(
        currentPoint['lat']!,
        currentPoint['lng']!,
        nextPoint['lat']!,
        nextPoint['lng']!,
      );
      remainingDistance += segmentDistance * (1.0 - _segmentProgress);
    }

    // Distance des segments restants
    for (int i = _currentRouteIndex + 1; i < _routePoints.length - 1; i++) {
      final currentPoint = _routePoints[i];
      final nextPoint = _routePoints[i + 1];
      remainingDistance += _calculateDistance(
        currentPoint['lat']!,
        currentPoint['lng']!,
        nextPoint['lat']!,
        nextPoint['lng']!,
      );
    }

    // Calculer le temps en minutes
    final timeInHours = remainingDistance / (_currentSpeed * 1000);
    final timeInMinutes = (timeInHours * 60).round();

    return Duration(minutes: timeInMinutes);
  }

  /// Obtient la distance restante en kilomètres
  double getRemainingDistance() {
    if (_routePoints.length < 2) return 0.0;

    double remainingDistance = 0.0;

    // Distance du segment actuel
    if (_currentRouteIndex < _routePoints.length - 1) {
      final currentPoint = _routePoints[_currentRouteIndex];
      final nextPoint = _routePoints[_currentRouteIndex + 1];
      final segmentDistance = _calculateDistance(
        currentPoint['lat']!,
        currentPoint['lng']!,
        nextPoint['lat']!,
        nextPoint['lng']!,
      );
      remainingDistance += segmentDistance * (1.0 - _segmentProgress);
    }

    // Distance des segments restants
    for (int i = _currentRouteIndex + 1; i < _routePoints.length - 1; i++) {
      final currentPoint = _routePoints[i];
      final nextPoint = _routePoints[i + 1];
      remainingDistance += _calculateDistance(
        currentPoint['lat']!,
        currentPoint['lng']!,
        nextPoint['lat']!,
        nextPoint['lng']!,
      );
    }

    return remainingDistance / 1000; // Conversion en kilomètres
  }

  /// Vérifie si le livreur est arrivé à destination
  bool get hasArrived {
    return _currentRouteIndex >= _routePoints.length - 1 &&
        _segmentProgress >= 1.0;
  }

  /// Dispose des ressources
  void dispose() {
    stopTracking();
    _positionController?.close();
    _positionController = null;
    debugPrint('🧹 Ressources UberStyleTrackingService libérées');
  }

  /// Indique si le service est en mode temps réel
  bool get isRealtimeMode => _isRealtimeMode;

  /// Indique si le tracking est actif
  bool get isTracking => _isTracking;

  /// Force le rechargement en mode Realtime
  void retryRealtimeConnection() {
    if (_driverId == null) {
      debugPrint('⚠️ Impossible de reconnecter: driverId est null');
      return;
    }

    debugPrint(
      '🔄 Nouvelle tentative de connexion Realtime pour driver $_driverId...',
    );

    // Nettoyer l'ancien channel s'il existe
    if (_realtimeChannel != null) {
      try {
        _supabase.removeChannel(_realtimeChannel!);
      } catch (e) {
        debugPrint('⚠️ Erreur lors du nettoyage de l\'ancien channel: $e');
      }
      _realtimeChannel = null;
    }

    _stopRealtimeHealthCheck();
    _positionTimer?.cancel();

    if (_isTracking) {
      _startRealtimeTracking();
    } else {
      // Si le tracking n'est pas démarré, le démarrer
      startTracking();
    }
  }
}

/// Modèle de données pour la position du livreur (réutilisé)
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
    if (routeProgress < 0.1) {
      return 'Préparation';
    } else if (routeProgress < 0.3) {
      return 'En route';
    } else if (routeProgress < 0.7) {
      return 'En livraison';
    } else if (routeProgress < 0.9) {
      return 'Presque arrivé';
    } else {
      return 'Arrivé';
    }
  }
}
