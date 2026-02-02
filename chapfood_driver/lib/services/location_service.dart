import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:logger/logger.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Logger _logger = Logger();
  StreamSubscription<geo.Position>? _positionStream;
  final StreamController<geo.Position> _positionController = StreamController<geo.Position>.broadcast();
  
  // Configuration
  static const double _distanceFilter = 5.0; // 5 mètres
  static const Duration _debounceDuration = Duration(seconds: 3);
  
  Timer? _debounceTimer;
  geo.Position? _lastSentPosition;
  
  // Getters
  Stream<geo.Position> get positionStream => _positionController.stream;
  geo.Position? get lastPosition => _lastSentPosition;

  /// Initialise le service de géolocalisation
  Future<bool> initialize() async {
    try {
      // Vérifier les permissions
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Les services de localisation sont désactivés');
        return false;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          _logger.w('Les permissions de localisation sont refusées');
          return false;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        _logger.e('Les permissions de localisation sont refusées de façon permanente');
        return false;
      }

      // Obtenir la position initiale
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      
      _lastSentPosition = position;
      _positionController.add(position);
      _logger.i('Position initiale obtenue: ${position.latitude}, ${position.longitude}');
      
      return true;
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation de la géolocalisation: $e');
      return false;
    }
  }

  /// Démarre le suivi de position en temps réel
  void startTracking() {
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: _distanceFilter.toInt(),
      ),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        _logger.e('Erreur dans le suivi de position: $error');
      },
    );
    
    _logger.i('Suivi de position démarré');
  }

  /// Arrête le suivi de position
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _debounceTimer?.cancel();
    _logger.i('Suivi de position arrêté');
  }

  /// Gère les mises à jour de position avec debounce
  void _onPositionUpdate(geo.Position position) {
    _logger.d('Position mise à jour: ${position.latitude}, ${position.longitude}');
    
    // Annuler le timer précédent
    _debounceTimer?.cancel();
    
    // Programmer un nouveau timer
    _debounceTimer = Timer(_debounceDuration, () {
      _processPositionUpdate(position);
    });
  }

  /// Traite la mise à jour de position après debounce
  void _processPositionUpdate(geo.Position position) {
    // Vérifier si la position a significativement changé
    if (_lastSentPosition != null) {
      final distance = geo.Geolocator.distanceBetween(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // Ne pas envoyer si le déplacement est inférieur à 5 mètres
      if (distance < _distanceFilter) {
        _logger.d('Position ignorée (déplacement < ${_distanceFilter}m)');
        return;
      }
    }
    
    _lastSentPosition = position;
    _positionController.add(position);
    _logger.i('Position traitée et envoyée: ${position.latitude}, ${position.longitude}');
  }

  /// Obtient la position actuelle
  Future<geo.Position?> getCurrentPosition() async {
    try {
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
    } catch (e) {
      _logger.e('Erreur lors de l\'obtention de la position actuelle: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return geo.Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Vérifie si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await geo.Geolocator.isLocationServiceEnabled();
  }

  /// Vérifie les permissions de localisation
  Future<geo.LocationPermission> checkPermission() async {
    return await geo.Geolocator.checkPermission();
  }

  /// Demande les permissions de localisation
  Future<geo.LocationPermission> requestPermission() async {
    return await geo.Geolocator.requestPermission();
  }

  /// Libère les ressources
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}