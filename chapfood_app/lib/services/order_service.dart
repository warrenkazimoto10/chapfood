import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../services/cart_service.dart';
import '../models/order_model.dart';
import '../models/enums.dart';

class OrderService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<OrderModel> createOrder({
    required String? userId,
    required String customerName,
    required String customerPhone,
    required DeliveryType deliveryType,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    required PaymentMethod paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    required List<dynamic> items,
  }) async {
    print('🛒 OrderService.createOrder appelé avec:');
    print('  - userId: $userId (type: ${userId.runtimeType})');
    print('  - customerName: $customerName');
    print('  - customerPhone: $customerPhone');
    print('  - deliveryType: $deliveryType');
    print('  - subtotal: $subtotal');
    print('  - totalAmount: $totalAmount');
    print('  - items count: ${items.length}');
    
    print('📝 Préparation des données d\'insertion...');
    final orderData = {
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_type': deliveryType.value,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'payment_method': paymentMethod.value,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'status': OrderStatus.pending.value,
    };
    
    print('📊 Données de commande:');
    orderData.forEach((key, value) {
      print('  - $key: $value (type: ${value.runtimeType})');
    });
    
    print('💾 Insertion dans la base de données...');
    
    // Tentative avec retry en cas d'erreur réseau
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final orderInsert = await _supabase.from('orders').insert(orderData).select('id').single();
        print('✅ Commande créée avec succès! ID: ${orderInsert['id']}');
        final orderId = orderInsert['id'] as int;
        
        // Ajouter les articles de la commande
        if (items.isNotEmpty) {
          print('📦 Ajout des articles...');
          final payload = items.map((i) => {
            'order_id': orderId,
            'menu_item_id': i.menuItem.id,
            'item_name': i.menuItem.name,
            'item_price': i.menuItem.price,
            'quantity': i.quantity,
            'total_price': i.totalPrice,
            'selected_garnitures': i.selectedGarnitures.map((g) => g.name).toList(),
            'selected_extras': i.selectedExtras.map((e) => e.name).toList(),
            'instructions': i.instructions,
          });
          await _supabase.from('order_items').insert(payload.toList());
          print('✅ Articles ajoutés avec succès!');
        }
        
        print('🧹 Vidage du panier...');
        await CartService.clearCart();
        
        // Récupérer la commande complète pour la retourner
        print('📋 Récupération de la commande complète...');
        final completeOrder = await getOrderWithItems(orderId);
        print('✅ Commande complète récupérée avec succès!');
        
        return completeOrder;
      } catch (e) {
        retryCount++;
        print('⚠️ Tentative $retryCount/$maxRetries échouée: $e');
        
        if (retryCount < maxRetries) {
          print('🔄 Nouvelle tentative dans 2 secondes...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          print('❌ Toutes les tentatives ont échoué');
          rethrow;
        }
      }
    }
    
    // Cette ligne ne devrait jamais être atteinte à cause du return dans la boucle
    throw Exception('Erreur inattendue dans la création de commande');
  }

  static Future<List<OrderModel>> getMyOrders() async {
    try {
      print('OrderService.getMyOrders() - Début');
      final user = await SessionService.getCurrentUser();
      print('User: ${user?.id}');
      if (user == null) {
        print('User is null, returning empty list');
        return [];
      }
      
      print('Fetching orders from Supabase...');
      final data = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(
              *,
              menu_items(*)
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      print('Raw data from Supabase: $data');
      print('Data length: ${data.length}');
      
      final orders = (data as List)
          .map((order) {
            print('Processing order: ${order['id']}');
            return OrderModel.fromJson(order as Map<String, dynamic>);
          })
          .toList();
      
      print('Processed orders count: ${orders.length}');
      return orders;
    } catch (e) {
      print('Error in getMyOrders: $e');
      rethrow;
    }
  }

  static Future<OrderModel> getOrderWithItems(int orderId) async {
    final data = await _supabase
        .from('orders')
        .select('''
          *,
          order_items(
            *,
            menu_items(*)
          )
        ''')
        .eq('id', orderId)
        .single();
    
    return OrderModel.fromJson(data);
  }
}


