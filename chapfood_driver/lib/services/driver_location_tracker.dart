import 'dart:async';
import 'package:logger/logger.dart';
import 'location_service.dart';
import 'driver_service.dart';

/// Service qui connecte la géolocalisation au DriverService
/// pour mettre à jour automatiquement la position du livreur
class DriverLocationTracker {
  static final DriverLocationTracker _instance =
      DriverLocationTracker._internal();
  factory DriverLocationTracker() => _instance;
  DriverLocationTracker._internal();

  final Logger _logger = Logger();
  final LocationService _locationService = LocationService();
  final DriverService _driverService = DriverService();

  StreamSubscription? _positionSubscription;
  int? _currentDriverId;
  bool _isTracking = false;

  /// Initialise le tracker de position
  Future<bool> initialize() async {
    try {
      // Initialiser le DriverService
      await _driverService.initialize();

      // Initialiser le LocationService
      final locationInitialized = await _locationService.initialize();
      if (!locationInitialized) {
        _logger.e('Impossible d\'initialiser la géolocalisation');
        return false;
      }

      _logger.i('DriverLocationTracker initialisé avec succès');
      return true;
    } catch (e) {
      _logger.e(
        'Erreur lors de l\'initialisation du DriverLocationTracker: $e',
      );
      return false;
    }
  }

  /// Démarre le suivi automatique de position pour un livreur
  Future<void> startTracking(int driverId) async {
    if (_isTracking && _currentDriverId == driverId) {
      _logger.d('Le suivi est déjà actif pour ce livreur');
      return;
    }

    try {
      // Arrêter le suivi précédent si nécessaire
      await stopTracking();

      _currentDriverId = driverId;
      _isTracking = true;

      // Démarrer le suivi de géolocalisation
      _locationService.startTracking();

      // Écouter les mises à jour de position
      _positionSubscription = _locationService.positionStream.listen(
        (position) => _onPositionUpdate(position),
        onError: (error) {
          _logger.e('Erreur dans le stream de position: $error');
        },
      );

      _logger.i('Suivi automatique démarré pour le livreur $driverId');
    } catch (e) {
      _logger.e('Erreur lors du démarrage du suivi: $e');
      _isTracking = false;
      _currentDriverId = null;
    }
  }

  /// Arrête le suivi automatique
  Future<void> stopTracking() async {
    try {
      _positionSubscription?.cancel();
      _positionSubscription = null;

      _locationService.stopTracking();

      _isTracking = false;
      _currentDriverId = null;

      _logger.i('Suivi automatique arrêté');
    } catch (e) {
      _logger.e('Erreur lors de l\'arrêt du suivi: $e');
    }
  }

  /// Gère les mises à jour de position
  Future<void> _onPositionUpdate(position) async {
    if (!_isTracking || _currentDriverId == null) {
      return;
    }

    try {
      _logger.d(
        'Mise à jour de position reçue: ${position.latitude}, ${position.longitude}',
      );

      // Envoyer la position au DriverService
      final success = await _driverService.updateDriverPosition(
        _currentDriverId!,
        position,
      );

      if (success) {
        _logger.i('Position mise à jour avec succès en base de données');
      } else {
        _logger.w('Échec de la mise à jour de position (stockage en local)');
      }
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour de position: $e');
    }
  }

  /// Met à jour le statut de disponibilité du livreur
  Future<bool> updateDriverStatus(bool isAvailable) async {
    if (_currentDriverId == null) {
      _logger.w('Aucun livreur en cours de suivi');
      return false;
    }

    try {
      final success = await _driverService.updateDriverStatus(
        _currentDriverId!,
        isAvailable,
      );
      if (success) {
        _logger.i(
          'Statut du livreur mis à jour: ${isAvailable ? "disponible" : "indisponible"}',
        );
      }
      return success;
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Synchronise les mises à jour stockées en local
  Future<void> syncOfflineUpdates() async {
    try {
      await _driverService.syncOfflineUpdates();
      _logger.i('Synchronisation des mises à jour hors ligne terminée');
    } catch (e) {
      _logger.e('Erreur lors de la synchronisation: $e');
    }
  }

  /// Obtient la position actuelle
  Future<dynamic> getCurrentPosition() async {
    return await _locationService.getCurrentPosition();
  }

  /// Vérifie si le suivi est actif
  bool get isTracking => _isTracking;

  /// Obtient l'ID du livreur en cours de suivi
  int? get currentDriverId => _currentDriverId;

  /// Libère les ressources
  Future<void> dispose() async {
    await stopTracking();
    _locationService.dispose();
    await _driverService.dispose();
  }
}




