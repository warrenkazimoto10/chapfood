import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';
import '../models/order_driver_assignment_model.dart';

class DeliveryTrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Timer? _trackingTimer;
  static RealtimeChannel? _driverChannel;
  static final StreamController<Map<String, dynamic>> _trackingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream pour écouter les mises à jour de livraison
  static Stream<Map<String, dynamic>> get trackingStream => _trackingController.stream;
  
  // Démarrer le suivi de livraison pour une commande
  static void startDeliveryTracking(int orderId) {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateDeliveryStatus(orderId);
    });
    
    // Mise à jour immédiate
    _updateDeliveryStatus(orderId);
  }
  
  // Arrêter le suivi
  static void stopDeliveryTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }
  
  // Mettre à jour le statut de livraison
  static Future<void> _updateDeliveryStatus(int orderId) async {
    try {
      // Récupérer les détails de la commande avec l'assignation du livreur
      final orderData = await _supabase
          .from('orders')
          .select('''
            *,
            order_driver_assignments(
              *,
              drivers(*)
            )
          ''')
          .eq('id', orderId)
          .single();
      
      final order = OrderModel.fromJson(orderData as Map<String, dynamic>);
      DriverModel? driver;
      OrderDriverAssignmentModel? assignment;
      
      if (orderData['order_driver_assignments'] != null && 
          orderData['order_driver_assignments'].isNotEmpty) {
        final assignmentData = orderData['order_driver_assignments'][0];
        assignment = OrderDriverAssignmentModel.fromJson(assignmentData as Map<String, dynamic>);
        
        if (assignmentData['drivers'] != null) {
          driver = DriverModel.fromJson(assignmentData['drivers'] as Map<String, dynamic>);
        }
      }
      
      // Émettre les données de suivi
      _trackingController.add({
        'order': order,
        'driver': driver,
        'assignment': assignment,
        'timestamp': DateTime.now(),
      });
      
    } catch (e) {
      print('Erreur lors de la mise à jour du suivi: $e');
    }
  }
  
  // Obtenir les détails de livraison pour une commande
  static Future<Map<String, dynamic>?> getDeliveryDetails(int orderId) async {
    try {
      final data = await _supabase
          .from('orders')
          .select('''
            *,
            order_driver_assignments(
              *,
              drivers(*)
            )
          ''')
          .eq('id', orderId)
          .single();
      
      final order = OrderModel.fromJson(data as Map<String, dynamic>);
      DriverModel? driver;
      OrderDriverAssignmentModel? assignment;
      
      if (data['order_driver_assignments'] != null && 
          data['order_driver_assignments'].isNotEmpty) {
        final assignmentData = data['order_driver_assignments'][0];
        assignment = OrderDriverAssignmentModel.fromJson(assignmentData as Map<String, dynamic>);
        
        if (assignmentData['drivers'] != null) {
          driver = DriverModel.fromJson(assignmentData['drivers'] as Map<String, dynamic>);
        }
      }
      
      return {
        'order': order,
        'driver': driver,
        'assignment': assignment,
      };
    } catch (e) {
      print('Erreur lors de la récupération des détails: $e');
      return null;
    }
  }
  
  // Écouter les changements de position du livreur en temps réel
  static void startRealtimeDriverTracking(int driverId) {
    _driverChannel = _supabase
        .channel('driver_location_$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: driverId,
          ),
          callback: (payload) {
            print('Position du livreur mise à jour: ${payload.newRecord}');
            // Mettre à jour le stream de suivi
            _trackingController.add({
              'driver_location_update': payload.newRecord,
              'timestamp': DateTime.now(),
            });
          },
        )
        .subscribe();
  }
  
  // Arrêter la souscription temps réel
  static void stopRealtimeDriverTracking() {
    try {
      if (_driverChannel != null) {
        _supabase.removeChannel(_driverChannel!);
        _driverChannel = null;
      }
    } catch (e) {
      print('Erreur lors de l\'arrêt du suivi du livreur: $e');
    }
  }
  
  // Nettoyer les ressources
  static void dispose() {
    stopDeliveryTracking();
    stopRealtimeDriverTracking();
    _trackingController.close();
  }
}
