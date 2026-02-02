import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les codes de confirmation de livraison
class DeliveryCodeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Génère un code de livraison pour une commande
  static Future<Map<String, dynamic>> generateDeliveryCode(int orderId) async {
    try {
      print('🔐 Génération du code de livraison pour la commande $orderId');
      
      // Appeler la fonction SQL pour générer le code
      final response = await _supabase.rpc('generate_delivery_code');
      final deliveryCode = response as String;
      
      // Calculer les dates d'expiration (15 minutes)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));
      
      // Mettre à jour la commande avec le code
      final updateResponse = await _supabase
          .from('orders')
          .update({
            'delivery_code': deliveryCode,
            'delivery_code_generated_at': now.toIso8601String(),
            'delivery_code_expires_at': expiresAt.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      print('✅ Code de livraison généré: $deliveryCode');
      print('⏰ Expire à: ${expiresAt.toIso8601String()}');

      return {
        'success': true,
        'deliveryCode': deliveryCode,
        'expiresAt': expiresAt,
        'order': updateResponse,
      };
    } catch (e) {
      print('❌ Erreur lors de la génération du code: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Valide un code de livraison
  static Future<bool> validateDeliveryCode(int orderId, String code) async {
    try {
      print('🔍 Validation du code $code pour la commande $orderId');
      
      // Appeler la fonction SQL de validation
      final response = await _supabase.rpc('validate_delivery_code', params: {
        'p_order_id': orderId,
        'p_delivery_code': code,
      });
      
      final isValid = response as bool;
      print(isValid ? '✅ Code valide' : '❌ Code invalide');
      
      return isValid;
    } catch (e) {
      print('❌ Erreur lors de la validation: $e');
      return false;
    }
  }

  /// Confirme la livraison avec le code
  static Future<Map<String, dynamic>> confirmDelivery(int orderId, String code, String confirmedBy) async {
    try {
      print('📦 Confirmation de la livraison avec le code $code');
      
      // Appeler la fonction SQL de confirmation
      final response = await _supabase.rpc('confirm_delivery', params: {
        'p_order_id': orderId,
        'p_delivery_code': code,
        'p_confirmed_by': confirmedBy,
      });
      
      final isConfirmed = response as bool;
      
      if (isConfirmed) {
        print('✅ Livraison confirmée avec succès');
        
        // Récupérer la commande mise à jour
        final orderResponse = await _supabase
            .from('orders')
            .select()
            .eq('id', orderId)
            .single();
        
        return {
          'success': true,
          'order': orderResponse,
        };
      } else {
        print('❌ Échec de la confirmation');
        return {
          'success': false,
          'error': 'Code invalide ou expiré',
        };
      }
    } catch (e) {
      print('❌ Erreur lors de la confirmation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Récupère le statut du code de livraison pour une commande
  static Future<Map<String, dynamic>?> getDeliveryCodeStatus(int orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('delivery_code, delivery_code_generated_at, delivery_code_expires_at, delivery_confirmed_at, delivery_confirmed_by')
          .eq('id', orderId)
          .single();

      if (response['delivery_code'] == null) {
        return {
          'status': 'no_code',
          'message': 'Aucun code généré',
        };
      }

      final expiresAt = DateTime.parse(response['delivery_code_expires_at']);
      final now = DateTime.now();

      if (response['delivery_confirmed_at'] != null) {
        return {
          'status': 'confirmed',
          'message': 'Livraison confirmée',
          'confirmedAt': response['delivery_confirmed_at'],
          'confirmedBy': response['delivery_confirmed_by'],
        };
      }

      if (expiresAt.isBefore(now)) {
        return {
          'status': 'expired',
          'message': 'Code expiré',
          'expiredAt': expiresAt,
        };
      }

      final secondsUntilExpiry = expiresAt.difference(now).inSeconds;
      return {
        'status': 'active',
        'message': 'Code actif',
        'deliveryCode': response['delivery_code'],
        'expiresAt': expiresAt,
        'secondsUntilExpiry': secondsUntilExpiry,
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération du statut: $e');
      return null;
    }
  }

  /// Nettoie les codes expirés (fonction utilitaire)
  static Future<int> cleanupExpiredCodes() async {
    try {
      final response = await _supabase.rpc('cleanup_expired_delivery_codes');
      final count = response as int;
      print('🧹 $count codes expirés nettoyés');
      return count;
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
      return 0;
    }
  }

  /// Formate le temps restant avant expiration
  static String formatTimeUntilExpiry(int seconds) {
    if (seconds <= 0) return 'Expiré';
    
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  /// Vérifie si un code est valide (format 6 chiffres)
  static bool isValidCodeFormat(String code) {
    return RegExp(r'^[0-9]{6}$').hasMatch(code);
  }
}
