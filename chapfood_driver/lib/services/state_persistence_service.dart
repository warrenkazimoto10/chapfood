import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/active_delivery_state.dart';

/// Service pour gérer la persistance de l'état de livraison active
class StatePersistenceService {
  static const String _activeDeliveryKey = 'active_delivery_state';
  static const String _driverLatKey = 'driver_lat';
  static const String _driverLngKey = 'driver_lng';

  /// Sauvegarder l'état de livraison active
  static Future<void> saveActiveDelivery(ActiveDeliveryState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.toJson());
      await prefs.setString(_activeDeliveryKey, json);
      print('💾 État de livraison sauvegardé: Commande #${state.orderId}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de l\'état: $e');
    }
  }

  /// Restaurer l'état au démarrage
  static Future<ActiveDeliveryState?> restoreActiveDelivery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_activeDeliveryKey);

      if (json == null || json.isEmpty) {
        print('📭 Aucun état de livraison sauvegardé');
        return null;
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final state = ActiveDeliveryState.fromJson(data);

      // Vérifier si l'état est encore valide
      if (!state.isValid) {
        print('⏰ État de livraison expiré, nettoyage...');
        await clearActiveDelivery();
        return null;
      }

      print('✅ État de livraison restauré: Commande #${state.orderId}');
      return state;
    } catch (e) {
      print('❌ Erreur lors de la restauration de l\'état: $e');
      // Nettoyer les données corrompues
      await clearActiveDelivery();
      return null;
    }
  }

  /// Vérifier la cohérence avec la base de données
  static Future<bool> validateActiveDelivery(int orderId) async {
    try {
      final supabase = Supabase.instance.client;

      // Vérifier d'abord dans la table orders
      final orderResponse = await supabase
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse == null) {
        print('❌ Commande #$orderId introuvable dans la DB');
        await clearActiveDelivery(); // Nettoyer l'état invalide
        return false;
      }

      final status = orderResponse['status'] as String;
      print('📋 Statut de la commande #$orderId: $status');

      // Si la commande est livrée ou annulée, l'état n'est plus valide
      if (status == 'delivered' || status == 'cancelled') {
        print(
          '⚠️ Commande #$orderId est $status, nettoyage de l\'état invalide...',
        );
        await clearActiveDelivery(); // Nettoyer l'état invalide
        return false;
      }

      // Vérifier aussi dans order_driver_assignments pour s'assurer que delivered_at est null
      final assignmentResponse = await supabase
          .from('order_driver_assignments')
          .select('delivered_at, driver_id')
          .eq('order_id', orderId)
          .maybeSingle();

      if (assignmentResponse == null) {
        print(
          '⚠️ Assignation supprimée pour commande #$orderId, nettoyage de l\'état...',
        );
        await clearActiveDelivery();
        return false;
      }

      final deliveredAt = assignmentResponse['delivered_at'];
      if (deliveredAt != null) {
        print(
          '⚠️ Commande #$orderId a un delivered_at, nettoyage de l\'état...',
        );
        await clearActiveDelivery();
        return false;
      }

      print('✅ Commande #$orderId valide (statut: $status)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la validation: $e');
      // En cas d'erreur, nettoyer l'état pour éviter les problèmes
      await clearActiveDelivery();
      return false;
    }
  }

  /// Nettoyer l'état sauvegardé
  static Future<void> clearActiveDelivery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeDeliveryKey);
      print('🧹 État de livraison nettoyé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Sauvegarder la position du livreur
  static Future<void> saveDriverLocation(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_driverLatKey, lat);
      await prefs.setDouble(_driverLngKey, lng);
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la position: $e');
    }
  }

  /// Restaurer la position du livreur
  static Future<Map<String, double>?> restoreDriverLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_driverLatKey);
      final lng = prefs.getDouble(_driverLngKey);

      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la restauration de la position: $e');
      return null;
    }
  }
}
