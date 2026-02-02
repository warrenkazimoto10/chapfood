import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/order_model.dart';
import 'revenue_service.dart';

class OrderService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Écouter les nouvelles commandes prêtes pour la livraison
  static Stream<List<OrderModel>> listenToReadyOrders() {
    print('🔔 OrderService: Initialisation du stream de commandes');
    final controller = StreamController<List<OrderModel>>();

    // D'abord, récupérer les commandes existantes
    getReadyOrdersTest().then((orders) {
      print('🔔 OrderService: ${orders.length} commandes initiales trouvées');
      controller.add(orders);
    });

    // Ensuite, écouter les changements
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
            print('🔔 OrderService: Changement détecté dans les commandes');
            print('🔔 OrderService: Payload: ${payload.newRecord}');

            try {
              final orders = await getReadyOrdersTest();
              print(
                '🔔 OrderService: ${orders.length} commandes après changement',
              );
              controller.add(orders);
            } catch (e) {
              print('🔔 OrderService: Erreur lors de la récupération: $e');
            }
          },
        )
        .subscribe();

    return controller.stream;
  }

  // Méthode de test pour vérifier les commandes sans Realtime
  static Future<List<OrderModel>> getReadyOrdersTest() async {
    try {
      print('🔍 Test récupération commandes ready_for_delivery...');

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('status', 'ready_for_delivery')
          .order('created_at', ascending: false);

      print('📊 Réponse Supabase: ${response.length} commandes trouvées');

      final orders = (response as List)
          .map((data) => OrderModel.fromJson(data))
          .toList();

      for (final order in orders) {
        print(
          '  - Commande ${order.id}: ${order.customerName} - ${order.status}',
        );
      }

      return orders;
    } catch (e) {
      print('❌ Erreur récupération commandes: $e');
      return [];
    }
  }

  // Accepter une commande (verrouillage automatique)
  static Future<bool> acceptOrder(int orderId, int driverId) async {
    try {
      // Ne PAS changer le statut ici pour ne pas casser le flux resto:
      // pending -> accepted -> ready_for_delivery (géré côté restaurant)
      // Ici on ne fait qu'assigner le livreur sur une commande déjà `ready_for_delivery`
      final response = await _supabase
          .from('orders')
          .update({
            'driver_id': driverId,
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', 'ready_for_delivery')
          .select();

      if (response.isNotEmpty) {
        print('✅ Commande $orderId acceptée par le livreur $driverId');

        // Insérer l'assignation dans order_driver_assignments
        await _supabase.from('order_driver_assignments').insert({
          'order_id': orderId,
          'driver_id': driverId,
          'assigned_at': DateTime.now().toIso8601String(),
        });

        return true;
      } else {
        print('❌ Commande $orderId déjà acceptée par un autre livreur');
        return false;
      }
    } catch (e) {
      print('❌ Erreur acceptation commande: $e');
      return false;
    }
  }

  // Récupérer les détails d'une commande
  static Future<OrderModel?> getOrderDetails(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            customer_name,
            customer_phone,
            delivery_address,
            delivery_lat,
            delivery_lng,
            subtotal,
            total_amount,
            payment_method,
            status,
            ready_at,
            created_at,
            updated_at
          ''')
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur récupération détails commande: $e');
      return null;
    }
  }

  // Marquer comme récupérée
  static Future<bool> markAsPickedUp(int orderId, int driverId) async {
    try {
      print('📦 Marquer la commande #$orderId comme récupérée');

      // Mettre à jour l'assignation
      await _supabase
          .from('order_driver_assignments')
          .update({'picked_up_at': DateTime.now().toIso8601String()})
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

      print('✅ Commande #$orderId marquée comme récupérée');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la marque de récupération: $e');
      return false;
    }
  }

  // Marquer comme arrivé au point de livraison
  static Future<bool> markAsArrived(int orderId, int driverId) async {
    try {
      print('📍 Marquer la commande #$orderId comme arrivée');

      // Mettre à jour l'assignation avec arrived_at
      await _supabase
          .from('order_driver_assignments')
          .update({'arrived_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId)
          .eq('driver_id', driverId);

      print('✅ Commande #$orderId marquée comme arrivée');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la marque d\'arrivée: $e');
      return false;
    }
  }

  // Marquer une commande comme livrée
  static Future<bool> completeDelivery(int orderId) async {
    try {
      // Récupérer les informations de la commande pour obtenir le driver_id et delivery_fee
      final orderResponse = await _supabase
          .from('orders')
          .select('delivery_fee')
          .eq('id', orderId)
          .single();

      final assignmentResponse = await _supabase
          .from('order_driver_assignments')
          .select('driver_id')
          .eq('order_id', orderId)
          .single();

      final deliveryFee =
          (orderResponse['delivery_fee'] as num?)?.toDouble() ?? 0.0;
      final driverId = assignmentResponse['driver_id'] as int;

      // Mettre à jour le statut de la commande
      await _supabase
          .from('orders')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Mettre à jour l'assignation
      await _supabase
          .from('order_driver_assignments')
          .update({'delivered_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId);

      // Mettre à jour les revenus du livreur
      await RevenueService.updateDriverRevenue(driverId, deliveryFee);

      print(
        '✅ Commande $orderId marquée comme livrée - Revenus: $deliveryFee FCFA',
      );
      return true;
    } catch (e) {
      print('❌ Erreur finalisation livraison: $e');
      return false;
    }
  }

  // Récupérer la commande actuelle du livreur
  static Future<OrderModel?> getCurrentDriverOrder(int driverId) async {
    try {
      final response = await _supabase
          .from('order_driver_assignments')
          .select('''
            order_id,
            assigned_at
          ''')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response != null) {
        return await getOrderDetails(response['order_id']);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération commande actuelle: $e');
      return null;
    }
  }

  // Vérifier si le livreur a une commande en cours
  static Future<bool> hasActiveOrder(int driverId) async {
    try {
      final response = await _supabase
          .from('order_driver_assignments')
          .select('id, delivered_at')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response != null) {
        // Vérifier si delivered_at est null (commande active)
        return response['delivered_at'] == null;
      }
      return false;
    } catch (e) {
      print('❌ Erreur vérification commande active: $e');
      return false;
    }
  }
}
