import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';

class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal();

  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache local pour mode hors ligne
  late Box _offlineBox;
  bool _isInitialized = false;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser Hive pour le cache local
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DriverUpdateAdapter());
      }
      _offlineBox = await Hive.openBox('driver_updates');
      _isInitialized = true;
      _logger.i('DriverService initialisé');
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation du DriverService: $e');
    }
  }

  /// Met à jour le statut du driver
  Future<bool> updateDriverStatus(int driverId, bool isAvailable) async {
    try {
      final updateData = {
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      };

      _logger.d(
        'Tentative de mise à jour du statut: $isAvailable pour driver ID: $driverId',
      );

      final response = await _supabase
          .from('drivers')
          .update(updateData)
          .eq('id', driverId)
          .select();

      _logger.i('Statut mis à jour avec succès: $isAvailable');
      _logger.d('Réponse Supabase: $response');

      return true;
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du statut: $e');
      _logger.d('Type d\'erreur: ${e.runtimeType}');

      // Stocker en local pour synchronisation ultérieure
      await _storeOfflineUpdate('status', {
        'driver_id': driverId,
        'is_available': isAvailable,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return false;
    }
  }

  /// Met à jour la position du driver
  Future<bool> updateDriverPosition(int driverId, geo.Position position) async {
    try {
      final updateData = {
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('drivers').update(updateData).eq('id', driverId);

      _logger.d(
        'Position envoyée à Supabase: ${position.latitude}, ${position.longitude}',
      );
      return true;
    } catch (e) {
      _logger.e('Erreur lors de l\'envoi de la position à Supabase: $e');

      // Stocker en local pour synchronisation ultérieure
      await _storeOfflineUpdate('position', {
        'driver_id': driverId,
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return false;
    }
  }

  /// Écoute les mises à jour des autres drivers
  RealtimeChannel listenToOtherDrivers(
    int currentDriverId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    try {
      final channel = _supabase
          .channel('driver_positions')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'drivers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.neq,
              column: 'id',
              value: currentDriverId.toString(),
            ),
            callback: (payload) {
              _logger.d('Position d\'un autre driver reçue: $payload');

              final data = payload.newRecord;
              if (data != null &&
                  data['current_lat'] != null &&
                  data['current_lng'] != null) {
                onUpdate(data);
              }
            },
          )
          .subscribe();

      _logger.i('Écoute des positions Supabase démarrée');
      return channel;
    } catch (e) {
      _logger.e('Erreur lors du démarrage de l\'écoute Supabase: $e');
      rethrow;
    }
  }

  /// Stocke une mise à jour en local pour synchronisation ultérieure
  Future<void> _storeOfflineUpdate(
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      final key =
          '${type}_${data['driver_id']}_${DateTime.now().millisecondsSinceEpoch}';
      await _offlineBox.put(key, data);
      _logger.d('Mise à jour stockée en local: $type');
    } catch (e) {
      _logger.e('Erreur lors du stockage local: $e');
    }
  }

  /// Synchronise les mises à jour stockées en local
  Future<void> syncOfflineUpdates() async {
    try {
      final keys = _offlineBox.keys.toList();
      _logger.i('Synchronisation de ${keys.length} mises à jour en local');

      for (final key in keys) {
        final data = _offlineBox.get(key) as Map<String, dynamic>?;
        if (data == null) continue;

        final type = key.toString().split('_')[0];
        final driverId = data['driver_id'] as int;

        bool success = false;
        switch (type) {
          case 'status':
            success = await updateDriverStatus(
              driverId,
              data['is_available'] as bool,
            );
            break;
          case 'position':
            final position = geo.Position(
              latitude: data['current_lat'] as double,
              longitude: data['current_lng'] as double,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                data['timestamp'] as int,
              ),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
            success = await updateDriverPosition(driverId, position);
            break;
        }

        if (success) {
          await _offlineBox.delete(key);
          _logger.d('Mise à jour synchronisée: $key');
        }
      }
    } catch (e) {
      _logger.e('Erreur lors de la synchronisation: $e');
    }
  }

  /// Obtient les informations d'un driver
  Future<Map<String, dynamic>?> getDriverInfo(int driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('id', driverId)
          .maybeSingle();

      return response;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des infos driver: $e');
      return null;
    }
  }

  /// Vérifie la connexion réseau
  Future<bool> checkNetworkConnection() async {
    try {
      // Test simple de connexion
      await _supabase.from('drivers').select().limit(1);
      return true;
    } catch (e) {
      _logger.w('Pas de connexion réseau: $e');
      return false;
    }
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await _offlineBox.close();
  }
}

/// Adapter Hive pour les mises à jour de driver
class DriverUpdateAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final int typeId = 0;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    final map = <String, dynamic>{};
    final length = reader.readInt();
    for (int i = 0; i < length; i++) {
      final key = reader.readString();
      final value = reader.read();
      map[key] = value;
    }
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeInt(obj.length);
    obj.forEach((key, value) {
      writer.writeString(key);
      writer.write(value);
    });
  }
}
