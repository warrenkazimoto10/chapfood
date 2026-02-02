import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/state_persistence_service.dart';

/// Service unifié pour la gestion GPS et itinéraires du livreur
class DriverLocationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static StreamSubscription<geo.Position>? _positionSubscription;
  static bool _isTracking = false;
  static int? _currentDriverId;

  /// Démarre le suivi GPS continu
  static Future<void> startLocationTracking(int driverId) async {
    if (_isTracking && _currentDriverId == driverId) {
      print('📍 Suivi GPS déjà actif pour le livreur $driverId');
      return;
    }

    try {
      await stopLocationTracking();

      _currentDriverId = driverId;
      _isTracking = true;

      // Vérifier les permissions
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Les services de localisation sont désactivés');
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          print('⚠️ Permissions de localisation refusées');
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        print('❌ Permissions de localisation refusées de façon permanente');
        return;
      }

      // Obtenir la position initiale
      final initialPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      // Mettre à jour la position initiale
      await _updateDriverPositionInDB(driverId, initialPosition);

      // Sauvegarder la position localement
      await StatePersistenceService.saveDriverLocation(
        initialPosition.latitude,
        initialPosition.longitude,
      );

      // Démarrer le stream de position
      _positionSubscription =
          geo.Geolocator.getPositionStream(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high,
              distanceFilter:
                  5, // Mettre à jour tous les 5 mètres (plus fréquent)
            ),
          ).listen(
            (position) async {
              print(
                '📍 Position GPS reçue: ${position.latitude}, ${position.longitude}',
              );
              await _updateDriverPositionInDB(driverId, position);
              await StatePersistenceService.saveDriverLocation(
                position.latitude,
                position.longitude,
              );
              print('✅ Position mise à jour dans Supabase');
            },
            onError: (error) {
              print('❌ Erreur dans le stream de position: $error');
            },
          );

      print('✅ Suivi GPS démarré pour le livreur $driverId');
    } catch (e) {
      print('❌ Erreur lors du démarrage du suivi GPS: $e');
      _isTracking = false;
      _currentDriverId = null;
    }
  }

  /// Arrête le suivi GPS
  static Future<void> stopLocationTracking() async {
    try {
      _positionSubscription?.cancel();
      _positionSubscription = null;
      _isTracking = false;
      _currentDriverId = null;
      print('🛑 Suivi GPS arrêté');
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt du suivi GPS: $e');
    }
  }

  /// Met à jour la position du livreur dans la base de données
  static Future<void> _updateDriverPositionInDB(
    int driverId,
    geo.Position position,
  ) async {
    try {
      final result = await _supabase
          .from('drivers')
          .update({
            'current_lat': position.latitude,
            'current_lng': position.longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId)
          .select();

      if (result.isNotEmpty) {
        print(
          '✅ Position DB mise à jour pour driver $driverId: ${position.latitude}, ${position.longitude}',
        );
      } else {
        print('⚠️ Aucune ligne mise à jour pour driver $driverId');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la position: $e');
      developer.log('Stack trace', error: e, stackTrace: StackTrace.current);
    }
  }

  /// Calcule la distance entre deux points (en mètres)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return geo.Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Obtient la position actuelle
  static Future<geo.Position?> getCurrentPosition() async {
    try {
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Vérifie si le suivi est actif
  static bool get isTracking => _isTracking;

  /// Obtient l'ID du livreur suivi
  static int? get currentDriverId => _currentDriverId;
}
