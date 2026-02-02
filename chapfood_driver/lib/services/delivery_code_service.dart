import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les codes de confirmation de livraison
class DeliveryCodeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Valide un code de livraison pour une commande
  static Future<bool> validateDeliveryCode(int orderId, String code) async {
    try {
      print('🔐 Validation du code de livraison: $code pour la commande $orderId');
      
      final response = await _supabase.rpc('validate_delivery_code', params: {
        'p_order_id': orderId,
        'p_delivery_code': code,
      });
      
      final isValid = response as bool;
      print('✅ Code de livraison valide: $isValid');
      
      return isValid;
    } catch (e) {
      print('❌ Erreur validation code: $e');
      return false;
    }
  }

  /// Confirme une livraison avec le code
  static Future<bool> confirmDelivery(int orderId, String code, String confirmedBy) async {
    try {
      print('✅ Confirmation de la livraison avec le code: $code');
      
      final response = await _supabase.rpc('confirm_delivery', params: {
        'p_order_id': orderId,
        'p_delivery_code': code,
        'p_confirmed_by': confirmedBy,
      });
      
      final isConfirmed = response as bool;
      print('✅ Livraison confirmée: $isConfirmed');
      
      return isConfirmed;
    } catch (e) {
      print('❌ Erreur confirmation livraison: $e');
      return false;
    }
  }

  /// Récupère les informations de la commande avec le code de livraison
  static Future<Map<String, dynamic>?> getOrderDeliveryInfo(int orderId) async {
    try {
      final response = await _supabase
          .from('orders_with_delivery_codes')
          .select('*')
          .eq('id', orderId)
          .maybeSingle();
      
      if (response != null) {
        print('📦 Informations de livraison récupérées: ${response['delivery_code_status']}');
        return response;
      }
      
      return null;
    } catch (e) {
      print('❌ Erreur récupération infos livraison: $e');
      return null;
    }
  }

  /// Vérifie si une commande a un code de livraison actif
  static Future<bool> hasActiveDeliveryCode(int orderId) async {
    try {
      final info = await getOrderDeliveryInfo(orderId);
      if (info == null) return false;
      
      final status = info['delivery_code_status'] as String;
      return status == 'active';
    } catch (e) {
      print('❌ Erreur vérification code actif: $e');
      return false;
    }
  }

  /// Génère un code de livraison pour une commande (utilisé par l'app client)
  static Future<bool> generateDeliveryCode(int orderId) async {
    try {
      print('🔐 Génération du code de livraison pour la commande $orderId');
      
      final response = await _supabase.rpc('generate_delivery_code');
      final code = response as String;
      
      await _supabase.from('orders').update({
        'delivery_code': code,
        'delivery_code_generated_at': DateTime.now().toIso8601String(),
        'delivery_code_expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      
      print('✅ Code de livraison généré: $code');
      return true;
    } catch (e) {
      print('❌ Erreur génération code: $e');
      return false;
    }
  }
}

