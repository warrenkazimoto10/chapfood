import 'dart:convert';
import 'menu_item_model.dart';

class OrderItemModel {
  final int id;
  final int orderId;
  final int? menuItemId;
  final String itemName;
  final double itemPrice;
  final int quantity;
  final double totalPrice;
  final List<String> selectedGarnitures;
  final List<String> selectedExtras;
  final String? instructions;
  final DateTime? createdAt;
  final MenuItemModel? menuItem;

  OrderItemModel({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
    required this.totalPrice,
    required this.selectedGarnitures,
    required this.selectedExtras,
    this.instructions,
    this.createdAt,
    this.menuItem,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse JSON arrays
    List<String> parseStringList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // If JSON parsing fails, treat as empty list
        }
      }
      return [];
    }

    return OrderItemModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      menuItemId: json['menu_item_id'] as int?,
      itemName: json['item_name'] as String,
      itemPrice: (json['item_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      selectedGarnitures: parseStringList(json['selected_garnitures']),
      selectedExtras: parseStringList(json['selected_extras']),
      instructions: json['instructions'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      menuItem: json['menu_items'] != null 
          ? MenuItemModel.fromJson(json['menu_items'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'item_name': itemName,
      'item_price': itemPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'selected_garnitures': selectedGarnitures,
      'selected_extras': selectedExtras,
      'instructions': instructions,
      'created_at': createdAt?.toIso8601String(),
      'menu_items': menuItem?.toJson(),
    };
  }
}