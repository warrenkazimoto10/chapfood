import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../models/order_model.dart';

class OrderStatusService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Timer? _statusTimer;
  static RealtimeChannel? _statusChannel;
  static final StreamController<List<OrderModel>> _ordersController =
      StreamController<List<OrderModel>>.broadcast();

  // Stream pour écouter les changements de statut
  static Stream<List<OrderModel>> get ordersStream => _ordersController.stream;

  // Démarrer le monitoring des statuts
  static void startStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForStatusUpdates();
    });

    // Vérification immédiate
    _checkForStatusUpdates();
  }

  // Arrêter le monitoring
  static void stopStatusMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  // Vérifier les mises à jour de statut
  static Future<void> _checkForStatusUpdates() async {
    try {
      final user = await SessionService.getCurrentUser();
      if (user == null) return;

      // Récupérer les commandes avec leurs statuts actuels et les assignations de livreurs
      final data = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(
              *,
              menu_items(*)
            ),
            order_driver_assignments(
              driver_id,
              delivered_at
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final orders = (data as List)
          .map((order) => OrderModel.fromJson(order as Map<String, dynamic>))
          .toList();

      // Émettre les nouvelles données
      _ordersController.add(orders);
    } catch (e) {
      print('Erreur lors de la vérification des statuts: $e');
    }
  }

  // Écouter les changements de statut en temps réel via Supabase Realtime
  static Future<void> startRealtimeSubscription() async {
    final user = await SessionService.getCurrentUser();
    if (user == null) return;

    _statusChannel = _supabase
        .channel('order_status_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            print('Statut de commande mis à jour: ${payload.newRecord}');
            _checkForStatusUpdates();
          },
        )
        .subscribe();
  }

  // Arrêter la souscription temps réel
  static void stopRealtimeSubscription() {
    try {
      if (_statusChannel != null) {
        _supabase.removeChannel(_statusChannel!);
        _statusChannel = null;
      }
    } catch (e) {
      print('Erreur lors de l\'arrêt de la souscription: $e');
    }
  }

  // Nettoyer les ressources
  static void dispose() {
    stopStatusMonitoring();
    stopRealtimeSubscription();
    _ordersController.close();
  }
}
