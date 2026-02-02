import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/menu_item_model.dart';
import '../models/supplement_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;
  final List<SupplementModel> selectedGarnitures;
  final List<SupplementModel> selectedExtras;
  final String instructions;
  final double totalPrice;

  CartItem({
    required this.menuItem,
    required this.quantity,
    required this.selectedGarnitures,
    required this.selectedExtras,
    required this.instructions,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'selectedGarnitures': selectedGarnitures.map((s) => s.toJson()).toList(),
      'selectedExtras': selectedExtras.map((s) => s.toJson()).toList(),
      'instructions': instructions,
      'totalPrice': totalPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItemModel.fromJson(json['menuItem']),
      quantity: json['quantity'],
      selectedGarnitures: (json['selectedGarnitures'] as List)
          .map((s) => SupplementModel.fromJson(s))
          .toList(),
      selectedExtras: (json['selectedExtras'] as List)
          .map((s) => SupplementModel.fromJson(s))
          .toList(),
      instructions: json['instructions'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }
}

class CartService {
  static const String _cartKey = 'cart_items';
  static List<CartItem> _cartItems = [];

  // Récupérer tous les articles du panier
  static List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  
  // Méthode alternative pour récupérer les articles du panier
  static Future<List<CartItem>> getCartItems() async {
    await loadCart();
    return List.unmodifiable(_cartItems);
  }

  // Calculer le total du panier
  static double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculer le nombre total d'articles
  static int get totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Charger le panier depuis le stockage local
  static Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erreur lors du chargement du panier: $e');
      _cartItems = [];
    }
  }

  // Sauvegarder le panier dans le stockage local
  static Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde du panier: $e');
    }
  }

  // Ajouter un article au panier
  static Future<void> addToCart({
    required MenuItemModel menuItem,
    required int quantity,
    required List<SupplementModel> selectedGarnitures,
    required List<SupplementModel> selectedExtras,
    required String instructions,
  }) async {
    // Calculer le prix total de l'article
    double totalPrice = menuItem.price * quantity;
    
    for (var garniture in selectedGarnitures) {
      totalPrice += garniture.price * quantity;
    }
    
    for (var extra in selectedExtras) {
      totalPrice += extra.price * quantity;
    }

    final cartItem = CartItem(
      menuItem: menuItem,
      quantity: quantity,
      selectedGarnitures: selectedGarnitures,
      selectedExtras: selectedExtras,
      instructions: instructions,
      totalPrice: totalPrice,
    );

    // Vérifier si l'article existe déjà dans le panier
    final existingIndex = _cartItems.indexWhere((item) =>
        item.menuItem.id == menuItem.id &&
        _areSupplementsEqual(item.selectedGarnitures, selectedGarnitures) &&
        _areSupplementsEqual(item.selectedExtras, selectedExtras) &&
        item.instructions == instructions);

    if (existingIndex != -1) {
      // Mettre à jour la quantité de l'article existant
      final existingItem = _cartItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      // Recalculer le prix total pour la nouvelle quantité
      double newTotalPrice = menuItem.price * newQuantity;
      for (var garniture in selectedGarnitures) {
        newTotalPrice += garniture.price * newQuantity;
      }
      for (var extra in selectedExtras) {
        newTotalPrice += extra.price * newQuantity;
      }
      
      _cartItems[existingIndex] = CartItem(
        menuItem: menuItem,
        quantity: newQuantity,
        selectedGarnitures: selectedGarnitures,
        selectedExtras: selectedExtras,
        instructions: instructions,
        totalPrice: newTotalPrice,
      );
    } else {
      // Ajouter un nouvel article
      _cartItems.add(cartItem);
    }

    await _saveCart();
  }

  // Vérifier si deux listes de suppléments sont égales
  static bool _areSupplementsEqual(List<SupplementModel> list1, List<SupplementModel> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    
    return true;
  }

  // Mettre à jour la quantité d'un article
  static Future<void> updateQuantity(int index, int newQuantity) async {
    if (index >= 0 && index < _cartItems.length) {
      if (newQuantity <= 0) {
        await removeFromCart(index);
      } else {
        final item = _cartItems[index];
        // Recalculer le prix total pour la nouvelle quantité
        double newTotalPrice = item.menuItem.price * newQuantity;
        for (var garniture in item.selectedGarnitures) {
          newTotalPrice += garniture.price * newQuantity;
        }
        for (var extra in item.selectedExtras) {
          newTotalPrice += extra.price * newQuantity;
        }
        
        _cartItems[index] = CartItem(
          menuItem: item.menuItem,
          quantity: newQuantity,
          selectedGarnitures: item.selectedGarnitures,
          selectedExtras: item.selectedExtras,
          instructions: item.instructions,
          totalPrice: newTotalPrice,
        );
        await _saveCart();
      }
    }
  }

  // Supprimer un article du panier
  static Future<void> removeFromCart(int index) async {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      await _saveCart();
    }
  }

  // Vider le panier
  static Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
  }

  // Calculer le total d'un article
}
