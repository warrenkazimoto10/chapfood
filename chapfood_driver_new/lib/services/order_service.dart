import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/order_model.dart';

class OrderService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Écouter les nouvelles commandes prêtes pour la livraison
  /// Filtre: status = 'ready_for_delivery' AND driver_id IS NULL
  static Stream<List<OrderModel>> listenToReadyOrders() {
    // ignore: avoid_print
    print('🔔 OrderService: Initialisation du stream de commandes');
    
    final controller = StreamController<List<OrderModel>>();

    // D'abord, récupérer les commandes existantes
    getReadyOrders().then((orders) {
      // ignore: avoid_print
      print('🔔 OrderService: ${orders.length} commandes initiales trouvées');
      controller.add(orders);
    });

    // Ensuite, écouter les changements en temps réel
    _supabase
        .channel('ready_orders')
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
            // ignore: avoid_print
            print('🔔 OrderService: Changement détecté dans les commandes');
            print('🔔 OrderService: Payload: ${payload.newRecord}');

            try {
              final orders = await getReadyOrders();
              // ignore: avoid_print
              print('🔔 OrderService: ${orders.length} commandes après changement');
              controller.add(orders);
            } catch (e) {
              // ignore: avoid_print
              print('🔔 OrderService: Erreur lors de la récupération: $e');
            }
          },
        )
        .subscribe();

    return controller.stream;
  }

  /// Récupérer les commandes ready_for_delivery sans driver assigné
  static Future<List<OrderModel>> getReadyOrders() async {
    try {
      // ignore: avoid_print
      print('🔍 Récupération commandes ready_for_delivery...');

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('status', 'ready_for_delivery')
          .isFilter('driver_id', null)
          .order('created_at', ascending: false);

      // ignore: avoid_print
      print('📊 Réponse Supabase: ${response.length} commandes trouvées');

      final orders = (response as List)
          .map((data) => OrderModel.fromJson(data))
          .toList();

      for (final order in orders) {
        // ignore: avoid_print
        print('  - Commande ${order.id}: ${order.customerName} - ${order.status.displayName}');
      }

      return orders;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur récupération commandes: $e');
      return [];
    }
  }

  /// Accepter une commande (verrouillage optimiste)
  /// Retourne false si déjà prise par un autre driver
  static Future<bool> acceptOrder(int orderId, int driverId) async {
    try {
      // ignore: avoid_print
      print('✋ Tentative d\'acceptation commande $orderId par driver $driverId');

      final response = await _supabase
          .from('orders')
          .update({
            'driver_id': driverId,
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', 'ready_for_delivery')
          .isFilter('driver_id', null)
          .select();

      if (response.isNotEmpty) {
        // ignore: avoid_print
        print('✅ Commande $orderId acceptée par le livreur $driverId');
        return true;
      } else {
        // ignore: avoid_print
        print('❌ Commande $orderId déjà acceptée par un autre livreur');
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur acceptation commande: $e');
      return false;
    }
  }

  /// Marquer comme récupérée au restaurant
  static Future<bool> markAsPickedUp(int orderId) async {
    try {
      // ignore: avoid_print
      print('📦 Marquer la commande #$orderId comme récupérée');

      await _supabase
          .from('orders')
          .update({
            'status': 'in_transit',
            'picked_up_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // ignore: avoid_print
      print('✅ Commande #$orderId marquée comme récupérée');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur lors de la marque de récupération: $e');
      return false;
    }
  }

  /// Marquer comme livrée
  static Future<bool> markAsDelivered(int orderId) async {
    try {
      // ignore: avoid_print
      print('✅ Marquer la commande #$orderId comme livrée');

      await _supabase
          .from('orders')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // ignore: avoid_print
      print('✅ Commande #$orderId marquée comme livrée');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur finalisation livraison: $e');
      return false;
    }
  }

  /// Récupérer les détails d'une commande
  static Future<OrderModel?> getOrderDetails(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur récupération détails commande: $e');
      return null;
    }
  }
}
