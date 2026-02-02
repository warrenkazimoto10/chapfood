enum OrderStatus {
  pending,
  accepted,
  readyForDelivery,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.readyForDelivery:
        return 'ready_for_delivery';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'ready_for_delivery':
        return OrderStatus.readyForDelivery;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.readyForDelivery:
        return 'Prête pour livraison';
      case OrderStatus.pickedUp:
        return 'Récupérée';
      case OrderStatus.inTransit:
        return 'En cours de livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

enum PaymentMethod {
  cash,
  wave,
  orangeMoney;

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.wave:
        return 'wave';
      case PaymentMethod.orangeMoney:
        return 'orange_money';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'wave':
        return PaymentMethod.wave;
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      default:
        return PaymentMethod.cash;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
    }
  }
}

class OrderModel {
  final int id;
  final String? userId;
  final String? customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final double subtotal;
  final double totalAmount;
  final double? deliveryFee;
  final PaymentMethod paymentMethod;
  final String? paymentNumber;
  final OrderStatus status;
  final String? instructions;
  final DateTime? readyAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    this.userId,
    this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.subtotal,
    required this.totalAmount,
    this.deliveryFee,
    required this.paymentMethod,
    this.paymentNumber,
    required this.status,
    this.instructions,
    this.readyAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String?,
      deliveryLat: json['delivery_lat'] != null
          ? (json['delivery_lat'] as num).toDouble()
          : null,
      deliveryLng: json['delivery_lng'] != null
          ? (json['delivery_lng'] as num).toDouble()
          : null,
      subtotal: (json['subtotal'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      paymentMethod: PaymentMethod.fromString(
        json['payment_method'] as String? ?? 'cash',
      ),
      paymentNumber: json['payment_number'] as String?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      instructions: json['instructions'] as String?,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod.value,
      'payment_number': paymentNumber,
      'status': status.value,
      'instructions': instructions,
      'ready_at': readyAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, customerPhone: $customerPhone, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
