import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';

class SupabaseService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // ========== USER SERVICES ==========
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  static Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await _client
          .from('users')
          .insert(user.toJson())
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  static Future<UserModel?> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }

  // ========== CATEGORY SERVICES ==========
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // ========== MENU ITEM SERVICES ==========
  static Future<List<MenuItemModel>> getMenuItems({int? categoryId}) async {
    try {
      var query = _client
          .from('menu_items')
          .select()
          .eq('is_available', true);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query.order('name');

      return (response as List)
          .map((json) => MenuItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting menu items: $e');
      return [];
    }
  }

  static Future<MenuItemModel?> getMenuItem(int id) async {
    try {
      final response = await _client
          .from('menu_items')
          .select()
          .eq('id', id)
          .single();

      return MenuItemModel.fromJson(response);
    } catch (e) {
      print('Error getting menu item: $e');
      return null;
    }
  }

  // ========== ORDER SERVICES ==========
  static Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  static Future<OrderModel?> createOrder(OrderModel order) async {
    try {
      final response = await _client
          .from('orders')
          .insert(order.toJson())
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  static Future<OrderModel?> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId)
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      print('Error updating order status: $e');
      return null;
    }
  }

  // ========== CART SERVICES ==========
  static Future<CartModel?> getUserCart(String userId) async {
    try {
      final response = await _client
          .from('carts')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return CartModel.fromJson(response);
    } catch (e) {
      print('Error getting user cart: $e');
      return null;
    }
  }

  static Future<CartModel?> createCart(String userId) async {
    try {
      final response = await _client
          .from('carts')
          .insert({'user_id': userId})
          .select()
          .single();

      return CartModel.fromJson(response);
    } catch (e) {
      print('Error creating cart: $e');
      return null;
    }
  }

  // ========== AUTHENTICATION ==========
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ========== REALTIME SUBSCRIPTIONS ==========
  static RealtimeChannel subscribeToOrders(String userId) {
    return _client
        .channel('user_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('Order update: $payload');
          },
        )
        .subscribe();
  }
}
