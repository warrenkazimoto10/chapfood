import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/order_driver_assignment_model.dart';
import 'order_service.dart';
import 'delivery_code_service.dart';
import 'state_persistence_service.dart';
import '../models/active_delivery_state.dart';

/// Service pour gérer le cycle de vie complet d'une livraison active
class ActiveDeliveryService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Vérifier si une livraison est en cours pour un livreur
  static Future<OrderModel?> getActiveDelivery(int driverId) async {
    print('🔍 getActiveDelivery appelé pour driver_id: $driverId');
    try {
      // Récupérer toutes les assignations du livreur avec timeout
      print('📋 Récupération des assignations pour le livreur $driverId...');
      final assignmentResponse = await _supabase
          .from('order_driver_assignments')
          .select('order_id, picked_up_at, arrived_at, delivered_at')
          .eq('driver_id', driverId)
          .timeout(const Duration(seconds: 8));

      final assignments = assignmentResponse as List;
      print('📦 Assignations trouvées: ${assignments.length}');

      // Filtrer pour trouver celle sans delivered_at
      Map<String, dynamic>? activeAssignment;
      try {
        activeAssignment =
            assignments.firstWhere(
                  (assignment) => assignment['delivered_at'] == null,
                )
                as Map<String, dynamic>?;
      } catch (e) {
        // Aucune assignation active trouvée
        activeAssignment = null;
      }

      if (activeAssignment == null) {
        print(
          'ℹ️ Aucune assignation active trouvée (toutes sont livrées ou supprimées)',
        );
        // Nettoyer l'état au cas où il y aurait une assignation supprimée
        await StatePersistenceService.clearActiveDelivery();
        return null;
      }

      final orderId = activeAssignment['order_id'] as int;
      print('✅ Assignation active trouvée pour commande #$orderId');

      // Vérifier que l'assignation existe toujours dans la DB
      final assignmentCheck = await _supabase
          .from('order_driver_assignments')
          .select('id')
          .eq('order_id', orderId)
          .eq('driver_id', driverId)
          .maybeSingle();

      if (assignmentCheck == null) {
        print(
          '⚠️ Assignation supprimée pour commande #$orderId, nettoyage de l\'état...',
        );
        await StatePersistenceService.clearActiveDelivery();
        return null;
      }

      // Récupérer les détails de la commande avec timeout
      print('📦 Récupération des détails de la commande #$orderId...');
      final order = await OrderService.getOrderDetails(orderId).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print(
            '⚠️ Timeout lors de la récupération des détails de la commande',
          );
          return null;
        },
      );

      if (order != null) {
        print(
          '📋 Commande trouvée: #${order.id}, status: ${order.status.value}',
        );
        // Vérifier que la commande n'est pas livrée ou annulée
        if (order.status.value == 'delivered' ||
            order.status.value == 'cancelled') {
          print(
            '⚠️ Commande #${order.id} déjà livrée ou annulée, nettoyage de l\'état...',
          );
          // Nettoyer l'état sauvegardé si la commande est livrée
          await StatePersistenceService.clearActiveDelivery();
          return null;
        }
        print('✅ Commande active valide: #${order.id}');
      } else {
        print(
          '❌ Détails de la commande non trouvés (commande peut-être supprimée)',
        );
        // Nettoyer l'état si la commande n'existe plus
        await StatePersistenceService.clearActiveDelivery();
      }

      return order;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la livraison active: $e');
      return null;
    }
  }

  /// Marquer comme récupérée
  static Future<bool> markAsPickedUp(int orderId, int driverId) async {
    try {
      print('📦 Marquer la commande #$orderId comme récupérée');

      // Mettre à jour l'assignation
      await _supabase
          .from('order_driver_assignments')
          .update({'picked_up_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId)
          .eq('driver_id', driverId);

      // Mettre à jour le statut de la commande à 'picked_up' (reste en picked_up, ne passe pas à in_transit)
      await _supabase
          .from('orders')
          .update({
            'status': 'picked_up',
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

  /// Marquer comme arrivé au point de livraison
  static Future<bool> markAsArrived(int orderId, int driverId) async {
    try {
      print('📍 Marquer la commande #$orderId comme arrivée');

      // Mettre à jour l'assignation avec arrived_at
      await _supabase
          .from('order_driver_assignments')
          .update({'arrived_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId)
          .eq('driver_id', driverId);

      // Mettre à jour l'état sauvegardé localement
      final order = await OrderService.getOrderDetails(orderId);
      if (order != null) {
        final state = ActiveDeliveryState.fromOrder(
          order,
          hasPickedUp: true,
          hasArrived: true,
        );
        await StatePersistenceService.saveActiveDelivery(state);
      }

      print('✅ Commande #$orderId marquée comme arrivée');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la marque d\'arrivée: $e');
      return false;
    }
  }

  /// Finaliser la livraison (avec code ou QR)
  static Future<bool> completeDelivery(
    int orderId,
    int driverId, {
    String? deliveryCode,
    String? qrCode,
  }) async {
    try {
      print('✅ Finalisation de la livraison #$orderId');

      // Si un code de livraison est fourni, le valider
      if (deliveryCode != null && deliveryCode.isNotEmpty) {
        final isValid = await DeliveryCodeService.validateDeliveryCode(
          orderId,
          deliveryCode,
        );

        if (!isValid) {
          print('❌ Code de livraison invalide');
          return false;
        }

        // Confirmer la livraison avec le code
        final isConfirmed = await DeliveryCodeService.confirmDelivery(
          orderId,
          deliveryCode,
          'driver_$driverId',
        );

        if (!isConfirmed) {
          print('❌ Échec de la confirmation avec le code');
          return false;
        }
      } else if (qrCode != null && qrCode.isNotEmpty) {
        // Valider le QR code (format: "order:123")
        if (!qrCode.startsWith('order:')) {
          print('❌ Format QR code invalide');
          return false;
        }

        final qrOrderId = int.tryParse(qrCode.replaceFirst('order:', ''));
        if (qrOrderId != orderId) {
          print('❌ QR code ne correspond pas à la commande');
          return false;
        }
      } else {
        print('❌ Aucun code ou QR code fourni');
        return false;
      }

      // Marquer comme livrée
      final success = await OrderService.completeDelivery(orderId);

      if (success) {
        // Nettoyer l'état sauvegardé
        await StatePersistenceService.clearActiveDelivery();
        print('✅ Livraison #$orderId finalisée avec succès');
      }

      return success;
    } catch (e) {
      print('❌ Erreur lors de la finalisation: $e');
      return false;
    }
  }

  /// Écouter les changements de statut en temps réel
  static Stream<OrderModel> watchActiveDelivery(int orderId) {
    final controller = StreamController<OrderModel>.broadcast();

    _supabase
        .channel('active_delivery_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) async {
            try {
              final orderData = payload.newRecord;
              final order = OrderModel.fromJson(orderData);
              controller.add(order);
            } catch (e) {
              print('❌ Erreur lors de la mise à jour du stream: $e');
            }
          },
        )
        .subscribe();

    // Également écouter les changements dans order_driver_assignments
    _supabase
        .channel('active_delivery_assignment_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_driver_assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) async {
            try {
              // Récupérer la commande mise à jour
              final order = await OrderService.getOrderDetails(orderId);
              if (order != null) {
                controller.add(order);
              }
            } catch (e) {
              print('❌ Erreur lors de la mise à jour du stream: $e');
            }
          },
        )
        .subscribe();

    return controller.stream;
  }

  /// Obtenir les informations de l'assignation (picked_up_at, arrived_at, etc.)
  static Future<OrderDriverAssignmentModel?> getAssignmentInfo(
    int orderId,
  ) async {
    try {
      final response = await _supabase
          .from('order_driver_assignments')
          .select('*')
          .eq('order_id', orderId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return OrderDriverAssignmentModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'assignation: $e');
      return null;
    }
  }
}
