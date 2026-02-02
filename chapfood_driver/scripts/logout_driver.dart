import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Configuration Supabase (copiée pour éviter les dépendances)
const String supabaseUrl = 'https://bxticpobvukefjtawjhi.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4dGljcG9idnVrZWZqdGF3amhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0Nzc0NTMsImV4cCI6MjA3MDA1MzQ1M30.JJ_TvTyetZWB42Ef4971Iaa2PxzyqjBhFMOUDXX7bDA';

/// Script pour déconnecter le livreur actuellement connecté
///
/// Usage: dart run scripts/logout_driver.dart
///
/// Ce script va:
/// 1. Charger la session actuelle du livreur
/// 2. Déconnecter le livreur de Supabase Auth
/// 3. Nettoyer les données de session locale
/// 4. Mettre à jour le statut du livreur dans la base de données
Future<void> main() async {
  print('🚪 Script de déconnexion du livreur');
  print('=' * 50);

  try {
    // Initialiser Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final supabase = Supabase.instance.client;

    // Charger les préférences pour trouver le livreur connecté
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final driverData = prefs.getString('driver_data');

    if (!isLoggedIn || driverData == null) {
      print('ℹ️  Aucun livreur connecté trouvé');
      exit(0);
    }

    // Parser les données du livreur
    final driverJson = driverData;
    print('📋 Données du livreur trouvées dans la session locale');

    // Extraire l'ID du livreur depuis les données JSON
    // Format attendu: {"id":123,"name":"...","email":"...",...}
    int? driverId;
    String? driverEmail;

    try {
      final data = driverJson;
      // Chercher l'ID dans la chaîne JSON
      final idMatch = RegExp(r'"id"\s*:\s*(\d+)').firstMatch(data);
      if (idMatch != null) {
        driverId = int.parse(idMatch.group(1)!);
      }

      // Chercher l'email dans la chaîne JSON
      final emailMatch = RegExp(r'"email"\s*:\s*"([^"]+)"').firstMatch(data);
      if (emailMatch != null) {
        driverEmail = emailMatch.group(1);
      }
    } catch (e) {
      print('⚠️  Erreur lors du parsing des données: $e');
    }

    if (driverId == null) {
      print('❌ Impossible de trouver l\'ID du livreur');
      exit(1);
    }

    print('👤 Livreur trouvé - ID: $driverId, Email: ${driverEmail ?? "N/A"}');

    // 1. Mettre à jour le statut du livreur dans la base de données
    print('\n📝 Mise à jour du statut du livreur dans la base de données...');
    try {
      await supabase
          .from('drivers')
          .update({
            'is_active': false,
            'is_available': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
      print(
        '✅ Statut du livreur mis à jour (is_active: false, is_available: false)',
      );
    } catch (e) {
      print('⚠️  Erreur lors de la mise à jour du statut: $e');
    }

    // 2. Déconnecter de Supabase Auth si une session existe
    print('\n🔐 Déconnexion de Supabase Auth...');
    try {
      await supabase.auth.signOut();
      print('✅ Déconnexion de Supabase Auth réussie');
    } catch (e) {
      print(
        '⚠️  Erreur lors de la déconnexion Auth (peut-être déjà déconnecté): $e',
      );
    }

    // 3. Nettoyer les données de session locale
    print('\n🧹 Nettoyage des données de session locale...');
    await prefs.remove('driver_data');
    await prefs.remove('is_logged_in');
    await prefs.remove('selected_service');
    await prefs.remove('saved_email');
    await prefs.remove('saved_phone');
    print('✅ Données de session locale supprimées');

    // 4. Arrêter le suivi GPS si actif
    print('\n📍 Arrêt du suivi GPS...');
    try {
      // Note: DriverLocationService est statique, on peut l'appeler directement
      // Mais pour éviter les dépendances, on met juste à jour la base de données
      await supabase
          .from('drivers')
          .update({'current_lat': null, 'current_lng': null})
          .eq('id', driverId);
      print('✅ Position GPS réinitialisée');
    } catch (e) {
      print('⚠️  Erreur lors de la réinitialisation GPS: $e');
    }

    print('\n' + '=' * 50);
    print('✅ Déconnexion complète réussie !');
    print('📱 Le livreur peut maintenant se reconnecter avec un autre compte');
    print('=' * 50);
  } catch (e, stackTrace) {
    print('\n❌ Erreur lors de la déconnexion: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
