import 'package:supabase_flutter/supabase_flutter.dart';

class DriverStatsService {
  static Future<Map<String, dynamic>> getDriverStats(int driverId) async {
    try {
      // Récupérer les commandes du driver pour aujourd'hui
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('driver_id', driverId)
          .gte('created_at', startOfDay.toIso8601String())
          .eq('status', 'delivered'); // Seulement les commandes livrées
      
      final orders = ordersResponse as List;
      
      // Calculer les statistiques
      final totalOrders = orders.length;
      final totalEarnings = orders.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] as num? ?? 0).toDouble(),
      );
      
      // Calculer le temps en ligne (mock pour l'instant, à implémenter avec un tracking réel)
      final hoursOnline = await _calculateHoursOnline(driverId);
      
      return {
        'total_orders': totalOrders,
        'total_earnings': totalEarnings,
        'hours_online': hoursOnline,
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error getting driver stats: $e');
      return {
        'total_orders': 0,
        'total_earnings': 0.0,
        'hours_online': 0.0,
      };
    }
  }
  
  static Future<double> _calculateHoursOnline(int driverId) async {
    // TODO: Implémenter un vrai tracking du temps en ligne
    // Pour l'instant, retourner une valeur mock
    return 0.0;
  }
}
