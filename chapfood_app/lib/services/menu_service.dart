import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/supplement_model.dart';
import '../config/supabase_config.dart';

class MenuService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  // Récupérer toutes les catégories
  static Future<List<CategoryModel>> getCategories() async {
    print('🍽️ [MENU_SERVICE] Récupération des catégories...');
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('created_at');

      print('🍽️ [MENU_SERVICE] Réponse brute des catégories: $response');

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      print('🍽️ [MENU_SERVICE] Catégories parsées: ${categories.length}');
      for (int i = 0; i < categories.length; i++) {
        print(
          '🍽️ [MENU_SERVICE] Catégorie $i: ${categories[i].name} (ID: ${categories[i].id})',
        );
      }

      return categories;
    } catch (e) {
      print(
        '🍽️ [MENU_SERVICE] ❌ Erreur lors de la récupération des catégories: $e',
      );
      return [];
    }
  }

  // Récupérer les plats par catégorie
  static Future<List<MenuItemModel>> getMenuItemsByCategory(
    int categoryId,
  ) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('created_at');

      return (response as List)
          .map((json) => MenuItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des plats: $e');
      return [];
    }
  }

  // Récupérer tous les plats
  static Future<List<MenuItemModel>> getAllMenuItems() async {
    print('🍽️ [MENU_SERVICE] Récupération de tous les plats...');
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('is_available', true)
          .order('created_at');

      print('🍽️ [MENU_SERVICE] Réponse brute des plats: $response');

      final menuItems = (response as List)
          .map((json) => MenuItemModel.fromJson(json))
          .toList();

      print('🍽️ [MENU_SERVICE] Plats parsés: ${menuItems.length}');
      for (int i = 0; i < menuItems.length; i++) {
        print(
          '🍽️ [MENU_SERVICE] Plat $i: ${menuItems[i].name} (Catégorie: ${menuItems[i].categoryId})',
        );
      }

      return menuItems;
    } catch (e) {
      print(
        '🍽️ [MENU_SERVICE] ❌ Erreur lors de la récupération de tous les plats: $e',
      );
      return [];
    }
  }

  // Récupérer tous les suppléments (garnitures et extras)
  static Future<List<SupplementModel>> getSupplements() async {
    try {
      final response = await _supabase
          .from('supplements')
          .select()
          .eq('is_available', true)
          .order('name');

      return (response as List)
          .map((json) => SupplementModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des suppléments: $e');
      return [];
    }
  }

  // Récupérer les garnitures
  static Future<List<SupplementModel>> getGarnitures() async {
    try {
      final response = await _supabase
          .from('supplements')
          .select()
          .eq('is_available', true)
          .eq('type', 'garniture')
          .order('name');

      return (response as List)
          .map((json) => SupplementModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des garnitures: $e');
      return [];
    }
  }

  // Récupérer les extras
  static Future<List<SupplementModel>> getExtras() async {
    try {
      final response = await _supabase
          .from('supplements')
          .select()
          .eq('is_available', true)
          .eq('type', 'extra')
          .order('name');

      return (response as List)
          .map((json) => SupplementModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des extras: $e');
      return [];
    }
  }
}
