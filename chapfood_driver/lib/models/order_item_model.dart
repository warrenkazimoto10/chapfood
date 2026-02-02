class OrderItemModel {
  final int id;
  final int orderId;
  final int menuItemId;
  final String itemName;
  final double itemPrice;
  final int quantity;
  final double totalPrice;
  final String? instructions;
  final Map<String, dynamic>? selectedExtras;
  final Map<String, dynamic>? selectedGarnitures;
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
    required this.totalPrice,
    this.instructions,
    this.selectedExtras,
    this.selectedGarnitures,
    required this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      menuItemId: json['menu_item_id'] as int,
      itemName: json['item_name'] as String,
      itemPrice: (json['item_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      instructions: json['instructions'] as String?,
      selectedExtras: json['selected_extras'] as Map<String, dynamic>?,
      selectedGarnitures: json['selected_garnitures'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'instructions': instructions,
      'selected_extras': selectedExtras,
      'selected_garnitures': selectedGarnitures,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'OrderItemModel(id: $id, itemName: $itemName, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
