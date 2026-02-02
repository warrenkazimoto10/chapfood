import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les revenus et l'historique des livraisons
class RevenueService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère l'historique des livraisons d'un livreur
  static Future<List<Map<String, dynamic>>> getDriverDeliveryHistory(int driverId) async {
    try {
      print('📊 Récupération de l\'historique des livraisons pour le livreur $driverId');
      
      final response = await _supabase
          .from('order_driver_assignments')
          .select('''
            id,
            delivered_at,
            order_id,
            orders!inner(
              id,
              customer_name,
              total_amount,
              delivery_fee,
              status,
              delivered_at
            )
          ''')
          .eq('driver_id', driverId)
          .not('delivered_at', 'is', null)
          .order('delivered_at', ascending: false);

      print('📈 Historique récupéré: ${response.length} livraisons');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// Calcule les revenus totaux d'un livreur
  static Future<Map<String, dynamic>> getDriverRevenueStats(int driverId) async {
    try {
      print('💰 Calcul des revenus pour le livreur $driverId');
      
      // Récupérer toutes les livraisons terminées
      final deliveries = await getDriverDeliveryHistory(driverId);
      
      if (deliveries.isEmpty) {
        return {
          'totalRevenue': 0.0,
          'totalDeliveries': 0,
          'averageDelivery': 0.0,
          'thisWeekRevenue': 0.0,
          'thisMonthRevenue': 0.0,
        };
      }

      // Calculer les statistiques
      double totalRevenue = 0.0;
      int totalDeliveries = deliveries.length;
      double thisWeekRevenue = 0.0;
      double thisMonthRevenue = 0.0;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      for (final delivery in deliveries) {
        final order = delivery['orders'] as Map<String, dynamic>;
        final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
        final deliveredAt = DateTime.parse(delivery['delivered_at'] as String);
        
        totalRevenue += deliveryFee;
        
        // Revenus de cette semaine
        if (deliveredAt.isAfter(weekStart)) {
          thisWeekRevenue += deliveryFee;
        }
        
        // Revenus de ce mois
        if (deliveredAt.isAfter(monthStart)) {
          thisMonthRevenue += deliveryFee;
        }
      }

      final stats = {
        'totalRevenue': totalRevenue,
        'totalDeliveries': totalDeliveries,
        'averageDelivery': totalDeliveries > 0 ? totalRevenue / totalDeliveries : 0.0,
        'thisWeekRevenue': thisWeekRevenue,
        'thisMonthRevenue': thisMonthRevenue,
      };

      print('📊 Statistiques calculées: $stats');
      return stats;
    } catch (e) {
      print('❌ Erreur calcul revenus: $e');
      return {
        'totalRevenue': 0.0,
        'totalDeliveries': 0,
        'averageDelivery': 0.0,
        'thisWeekRevenue': 0.0,
        'thisMonthRevenue': 0.0,
      };
    }
  }

  /// Récupère les détails d'une livraison spécifique
  static Future<Map<String, dynamic>?> getDeliveryDetails(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            customer_name,
            customer_phone,
            delivery_address,
            total_amount,
            delivery_fee,
            status,
            delivered_at,
            order_driver_assignments!inner(
              driver_id,
              delivered_at
            )
          ''')
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      print('❌ Erreur récupération détails livraison: $e');
      return null;
    }
  }

  /// Met à jour les revenus du livreur après une livraison
  static Future<void> updateDriverRevenue(int driverId, double deliveryFee) async {
    try {
      print('💰 Mise à jour des revenus du livreur $driverId: +$deliveryFee FCFA');
      
      // Récupérer les statistiques actuelles
      final currentStats = await _supabase
          .from('drivers')
          .select('total_deliveries')
          .eq('id', driverId)
          .single();

      final currentDeliveries = currentStats['total_deliveries'] as int? ?? 0;
      
      // Mettre à jour le nombre total de livraisons
      await _supabase
          .from('drivers')
          .update({
            'total_deliveries': currentDeliveries + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      print('✅ Revenus du livreur mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour revenus: $e');
    }
  }
}

