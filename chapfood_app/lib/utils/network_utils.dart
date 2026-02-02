import 'dart:io';
import '../config/supabase_config.dart';

class NetworkUtils {
  /// Teste la connectivité avec le serveur Supabase
  static Future<bool> testSupabaseConnection() async {
    try {
      print('🔍 Test de connectivité Supabase...');
      
      // Test de résolution DNS
      final internetAddress = await InternetAddress.lookup('bxticpobvukefjtawjhi.supabase.co');
      if (internetAddress.isEmpty) {
        print('❌ Échec de résolution DNS');
        return false;
      }
      print('✅ Résolution DNS réussie: ${internetAddress.first.address}');
      
      // Test de connexion HTTP simple
      final client = SupabaseConfig.client;
      await client
          .from('users')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      
      print('✅ Connexion Supabase réussie');
      return true;
    } catch (e) {
      print('❌ Échec de connexion Supabase: $e');
      return false;
    }
  }
  
  /// Vérifie la connectivité internet générale
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Retry avec backoff exponentiel pour les opérations réseau
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        print('🔄 Tentative $attempt échouée, retry dans ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Backoff exponentiel
      }
    }
    
    throw Exception('Toutes les tentatives ont échoué');
  }
}
