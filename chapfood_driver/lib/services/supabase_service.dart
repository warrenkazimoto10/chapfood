import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';
import '../models/order_model.dart';
import '../models/driver_notification_model.dart';
import '../models/order_item_model.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Authentification du livreur
  static Future<DriverModel?> authenticateDriver(String phone, String password) async {
    try {
      // Rechercher le livreur par téléphone
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('phone', phone)
          .eq('is_active', true)
          .single();

      return DriverModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Erreur lors de l\'authentification du livreur: $e');
      return null;
    }
  }

  // Mettre à jour la position du livreur
  static Future<void> updateDriverLocation(int driverId, double lat, double lng) async {
    try {
      await _supabase
          .from('drivers')
          .update({
            'current_lat': lat,
            'current_lng': lng,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
    } catch (e) {
      print('Erreur lors de la mise à jour de la position: $e');
    }
  }

  // Mettre à jour le statut de disponibilité du livreur
  static Future<void> updateDriverAvailability(int driverId, bool isAvailable) async {
    try {
      await _supabase
          .from('drivers')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
    } catch (e) {
      print('Erreur lors de la mise à jour de la disponibilité: $e');
    }
  }

  // Obtenir les commandes assignées au livreur
  static Future<List<OrderModel>> getAssignedOrders(int driverId) async {
    try {
      final response = await _supabase
          .from('order_driver_assignments')
          .select('''
            *,
            orders(*)
          ''')
          .eq('driver_id', driverId)
          .order('assigned_at', ascending: false);

      List<OrderModel> orders = [];
      for (var assignment in response) {
        if (assignment['orders'] != null) {
          orders.add(OrderModel.fromJson(assignment['orders'] as Map<String, dynamic>));
        }
      }
      return orders;
    } catch (e) {
      print('Erreur lors de la récupération des commandes assignées: $e');
      return [];
    }
  }

  // Obtenir les détails d'une commande avec ses articles
  static Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*)
          ''')
          .eq('id', orderId)
          .single();

      final order = OrderModel.fromJson(response as Map<String, dynamic>);
      List<OrderItemModel> items = [];
      
      if (response['order_items'] != null) {
        for (var item in response['order_items']) {
          items.add(OrderItemModel.fromJson(item as Map<String, dynamic>));
        }
      }

      return {
        'order': order,
        'items': items,
      };
    } catch (e) {
      print('Erreur lors de la récupération des détails de la commande: $e');
      return null;
    }
  }

  // Marquer une commande comme récupérée
  static Future<void> markOrderAsPickedUp(int orderId, int driverId) async {
    try {
      // Mettre à jour l'assignation
      await _supabase
          .from('order_driver_assignments')
          .update({
            'picked_up_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId)
          .eq('driver_id', driverId);

      // Mettre à jour le statut de la commande
      await _supabase
          .from('orders')
          .update({
            'status': 'in_transit',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Erreur lors de la marque de récupération: $e');
    }
  }

  // Marquer une commande comme livrée
  static Future<void> markOrderAsDelivered(int orderId, int driverId) async {
    try {
      // Mettre à jour l'assignation
      await _supabase
          .from('order_driver_assignments')
          .update({
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId)
          .eq('driver_id', driverId);

      // Mettre à jour le statut de la commande
      await _supabase
          .from('orders')
          .update({
            'status': 'delivered',
            'actual_delivery_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Erreur lors de la marque de livraison: $e');
    }
  }

  // Obtenir les notifications du livreur
  static Future<List<DriverNotificationModel>> getDriverNotifications(int driverId) async {
    try {
      final response = await _supabase
          .from('driver_notifications')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      List<DriverNotificationModel> notifications = [];
      for (var notification in response) {
        notifications.add(DriverNotificationModel.fromJson(notification as Map<String, dynamic>));
      }
      return notifications;
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  // Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('driver_notifications')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('Erreur lors de la marque de notification lue: $e');
    }
  }

  // Écouter les notifications en temps réel
  static RealtimeChannel listenToDriverNotifications(int driverId, Function(DriverNotificationModel) onNotification) {
    return _supabase
        .channel('driver_notifications_$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'driver_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) {
            final notification = DriverNotificationModel.fromJson(payload.newRecord as Map<String, dynamic>);
            onNotification(notification);
          },
        )
        .subscribe();
  }

  // Écouter les mises à jour de commandes en temps réel
  static RealtimeChannel listenToOrderUpdates(int driverId, Function(OrderModel) onOrderUpdate) {
    return _supabase
        .channel('driver_orders_$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            // Vérifier si cette commande est assignée au livreur
            final orderId = payload.newRecord['id'] as int;
            _checkOrderAssignment(orderId, driverId).then((isAssigned) {
              if (isAssigned) {
                final order = OrderModel.fromJson(payload.newRecord as Map<String, dynamic>);
                onOrderUpdate(order);
              }
            });
          },
        )
        .subscribe();
  }

  // Vérifier si une commande est assignée au livreur
  static Future<bool> _checkOrderAssignment(int orderId, int driverId) async {
    try {
      final response = await _supabase
          .from('order_driver_assignments')
          .select()
          .eq('order_id', orderId)
          .eq('driver_id', driverId)
          .single();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Arrêter l'écoute des notifications
  static void stopListening(RealtimeChannel channel) {
    try {
      _supabase.removeChannel(channel);
    } catch (e) {
      print('Erreur lors de l\'arrêt de l\'écoute: $e');
    }
  }
}
