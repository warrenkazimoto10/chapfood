import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Configuration Supabase
const String supabaseUrl = 'https://bxticpobvukefjtawjhi.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4dGljcG9idnVrZWZqdGF3amhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0Nzc0NTMsImV4cCI6MjA3MDA1MzQ1M30.JJ_TvTyetZWB42Ef4971Iaa2PxzyqjBhFMOUDXX7bDA';

/// Script pour nettoyer l'état d'une commande spécifique
///
/// Usage: dart run scripts/clear_order_state.dart [orderId]
/// Exemple: dart run scripts/clear_order_state.dart 50
Future<void> main(List<String> args) async {
  print('🧹 Script de nettoyage de l\'état d\'une commande');
  print('=' * 50);

  if (args.isEmpty) {
    print('❌ Usage: dart run scripts/clear_order_state.dart [orderId]');
    print('   Exemple: dart run scripts/clear_order_state.dart 50');
    exit(1);
  }

  final orderIdStr = args[0];
  final orderId = int.tryParse(orderIdStr);

  if (orderId == null) {
    print('❌ ID de commande invalide: $orderIdStr');
    exit(1);
  }

  try {
    // Initialiser Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final supabase = Supabase.instance.client;

    print('🔍 Vérification de la commande #$orderId...');

    // Vérifier le statut de la commande
    final orderResponse = await supabase
        .from('orders')
        .select('id, status')
        .eq('id', orderId)
        .maybeSingle();

    if (orderResponse == null) {
      print('❌ Commande #$orderId introuvable');
      exit(1);
    }

    final status = orderResponse['status'] as String;
    print('📋 Statut de la commande #$orderId: $status');

    // Charger les préférences
    final prefs = await SharedPreferences.getInstance();
    final savedStateJson = prefs.getString('active_delivery_state');

    if (savedStateJson == null) {
      print('ℹ️  Aucun état de livraison sauvegardé trouvé');
      exit(0);
    }

    // Parser l'état sauvegardé
    final savedState = savedStateJson;
    final savedOrderIdMatch = RegExp(
      r'"orderId"\s*:\s*(\d+)',
    ).firstMatch(savedState);

    if (savedOrderIdMatch == null) {
      print('⚠️  Impossible de parser l\'état sauvegardé');
      exit(1);
    }

    final savedOrderId = int.parse(savedOrderIdMatch.group(1)!);

    if (savedOrderId != orderId) {
      print(
        'ℹ️  L\'état sauvegardé concerne la commande #$savedOrderId, pas #$orderId',
      );
      print('   Pour nettoyer la commande #$savedOrderId, utilisez:');
      print('   dart run scripts/clear_order_state.dart $savedOrderId');
      exit(0);
    }

    print('📦 État trouvé pour la commande #$orderId');

    // Nettoyer l'état
    await prefs.remove('active_delivery_state');
    print('✅ État de la commande #$orderId nettoyé');

    // Si la commande est livrée, afficher un message
    if (status == 'delivered' || status == 'cancelled') {
      print(
        '✅ La commande #$orderId est $status, l\'état a été correctement nettoyé',
      );
    }

    print('\n' + '=' * 50);
    print('✅ Nettoyage terminé !');
    print('=' * 50);
  } catch (e, stackTrace) {
    print('\n❌ Erreur lors du nettoyage: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

