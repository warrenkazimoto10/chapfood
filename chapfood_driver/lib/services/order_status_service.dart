import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';

/// Service pour la synchronisation temps réel des statuts de commandes
class OrderStatusService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Écouter les changements d'une commande spécifique
  static Stream<OrderModel> watchOrder(int orderId) {
    final controller = StreamController<OrderModel>.broadcast();

    _supabase
        .channel('order_status_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            try {
              final orderData = payload.newRecord;
              final order = OrderModel.fromJson(orderData);
              controller.add(order);
            } catch (e) {
              print('❌ Erreur lors de la mise à jour du stream: $e');
              controller.addError(e);
            }
          },
        )
        .subscribe();

    // Récupérer l'état initial
    _getOrderInitialState(orderId)
        .then((order) {
          if (order != null) {
            controller.add(order);
          }
        })
        .catchError((e) {
          controller.addError(e);
        });

    return controller.stream;
  }

  /// Écouter les nouvelles commandes disponibles
  static Stream<List<OrderModel>> watchAvailableOrders() {
    print('🔔 Initialisation du stream watchAvailableOrders');
    final controller = StreamController<List<OrderModel>>.broadcast();

    _supabase
        .channel('available_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'ready_for_delivery',
          ),
          callback: (payload) async {
            print('🔔 Changement détecté dans les commandes');
            try {
              // Récupérer toutes les commandes disponibles
              final orders = await _getAvailableOrders();
              print('📦 Envoi de ${orders.length} commandes dans le stream');
              controller.add(orders);
            } catch (e) {
              print(
                '❌ Erreur lors de la mise à jour des commandes disponibles: $e',
              );
              controller.addError(e);
            }
          },
        )
        .subscribe();

    // Récupérer l'état initial
    print('🔍 Récupération de l\'état initial des commandes...');
    _getAvailableOrders()
        .then((orders) {
          print('📦 État initial: ${orders.length} commandes trouvées');
          controller.add(orders);
        })
        .catchError((e) {
          print('❌ Erreur lors de la récupération de l\'état initial: $e');
          controller.addError(e);
        });

    return controller.stream;
  }

  /// Écouter les changements de statut du livreur
  static Stream<DriverModel> watchDriverStatus(int driverId) {
    final controller = StreamController<DriverModel>.broadcast();

    _supabase
        .channel('driver_status_$driverId')
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
            try {
              final driverData = payload.newRecord;
              final driver = DriverModel.fromJson(driverData);
              controller.add(driver);
            } catch (e) {
              print('❌ Erreur lors de la mise à jour du statut du livreur: $e');
              controller.addError(e);
            }
          },
        )
        .subscribe();

    // Récupérer l'état initial
    _getDriverInitialState(driverId)
        .then((driver) {
          if (driver != null) {
            controller.add(driver);
          }
        })
        .catchError((e) {
          controller.addError(e);
        });

    return controller.stream;
  }

  /// Récupérer l'état initial d'une commande
  static Future<OrderModel?> _getOrderInitialState(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return OrderModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'état initial: $e');
      return null;
    }
  }

  /// Récupérer les commandes disponibles
  static Future<List<OrderModel>> _getAvailableOrders() async {
    try {
      print('🔍 Recherche des commandes disponibles...');
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('status', 'ready_for_delivery')
          .order('created_at', ascending: false);

      print(
        '📋 Commandes avec status ready_for_delivery: ${(response as List).length}',
      );

      // Filtrer pour ne garder que celles sans driver_id
      final availableOrders = (response as List)
          .where((data) {
            final driverId = data['driver_id'];
            print('🔍 Commande #${data['id']}: driver_id = $driverId');
            return driverId == null;
          })
          .map((data) => OrderModel.fromJson(data as Map<String, dynamic>))
          .toList();

      print(
        '✅ Commandes disponibles (sans driver_id): ${availableOrders.length}',
      );
      return availableOrders;
    } catch (e) {
      print('❌ Erreur lors de la récupération des commandes disponibles: $e');
      return [];
    }
  }

  /// Récupérer l'état initial d'un livreur
  static Future<DriverModel?> _getDriverInitialState(int driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('*')
          .eq('id', driverId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DriverModel.fromJson(response);
    } catch (e) {
      print(
        '❌ Erreur lors de la récupération de l\'état initial du livreur: $e',
      );
      return null;
    }
  }
}
