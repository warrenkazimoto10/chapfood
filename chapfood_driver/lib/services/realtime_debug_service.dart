import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeDebugService {
  static final _client = Supabase.instance.client;

  /// Teste la connexion Realtime et vérifie les publications
  static Future<void> testRealtimeConnection() async {
    try {
      print('🔍 Test de connexion Realtime...');
      
      // Test 1: Vérifier la connexion Supabase
      final response = await _client.from('orders').select('id').limit(1);
      print('✅ Connexion Supabase OK: ${response.length} commandes trouvées');
      
      // Test 2: Vérifier les publications Realtime
      final publications = await _client.rpc('get_publications');
      print('📋 Publications disponibles: $publications');
      
      // Test 3: Vérifier les tables dans supabase_realtime
      final tables = await _client.rpc('get_publication_tables', params: {
        'pubname': 'supabase_realtime'
      });
      print('📊 Tables dans supabase_realtime: $tables');
      
    } catch (e) {
      print('❌ Erreur test Realtime: $e');
    }
  }

  /// Teste l'écoute Realtime sur la table orders
  static Stream<List<Map<String, dynamic>>> testOrdersRealtime() {
    print('🎧 Démarrage écoute Realtime orders...');
    
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'ready_for_delivery');
  }

  /// Teste l'insertion d'une commande de test
  static Future<void> insertTestOrder() async {
    try {
      print('🧪 Insertion commande de test...');
      
      final testOrder = {
        'customer_name': 'Test Customer',
        'customer_phone': '0707559999',
        'delivery_address': 'Test Address',
        'delivery_lat': 5.3599,
        'delivery_lng': -4.0083,
        'subtotal': 5000,
        'total_amount': 5000,
        'status': 'ready_for_delivery',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _client.from('orders').insert(testOrder).select();
      print('✅ Commande de test insérée: ${response.first['id']}');
      
    } catch (e) {
      print('❌ Erreur insertion test: $e');
    }
  }

  /// Nettoie les commandes de test
  static Future<void> cleanupTestOrders() async {
    try {
      print('🧹 Nettoyage commandes de test...');
      
      await _client
          .from('orders')
          .delete()
          .eq('customer_name', 'Test Customer');
      
      print('✅ Nettoyage terminé');
      
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }

  /// Vérifie la configuration Realtime complète
  static Future<void> fullRealtimeDiagnostic() async {
    print('🔍 === DIAGNOSTIC REALTIME COMPLET ===');
    
    await testRealtimeConnection();
    
    print('\n📊 === TEST ÉCOUTE REALTIME ===');
    final stream = testOrdersRealtime();
    
    // Écouter pendant 10 secondes
    final subscription = stream.take(1).listen((data) {
      print('✅ Realtime fonctionne: ${data.length} commandes');
    }, onError: (error) {
      print('❌ Erreur Realtime: $error');
    });
    
    // Attendre un peu puis insérer une commande de test
    await Future.delayed(const Duration(seconds: 2));
    await insertTestOrder();
    
    // Attendre la réception
    await Future.delayed(const Duration(seconds: 5));
    
    // Nettoyer
    await cleanupTestOrders();
    await subscription.cancel();
    
    print('\n✅ === DIAGNOSTIC TERMINÉ ===');
  }
}
