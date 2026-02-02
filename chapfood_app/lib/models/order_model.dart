import 'enums.dart';
import 'order_item_model.dart';

class OrderModel {
  final int id;
  final String? userId;
  final String customerPhone;
  final String? customerName;
  final DeliveryType deliveryType;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final PaymentMethod paymentMethod;
  final String? paymentNumber;
  final double subtotal;
  final double? deliveryFee;
  final double totalAmount;
  final OrderStatus status;
  final String? instructions;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? preparationTime;
  final String? kitchenNotes;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? readyAt;
  final int? driverId;
  final bool?
  hasAssignedDriver; // Indique si un livreur est assigné (basé sur order_driver_assignments)
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.id,
    this.userId,
    required this.customerPhone,
    this.customerName,
    required this.deliveryType,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.paymentMethod,
    this.paymentNumber,
    required this.subtotal,
    this.deliveryFee,
    required this.totalAmount,
    required this.status,
    this.instructions,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.createdAt,
    this.updatedAt,
    this.preparationTime,
    this.kitchenNotes,
    this.acceptedAt,
    this.rejectedAt,
    this.readyAt,
    this.driverId,
    this.hasAssignedDriver,
    this.orderItems = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      customerPhone: json['customer_phone'] as String,
      customerName: json['customer_name'] as String?,
      deliveryType: DeliveryType.fromString(json['delivery_type'] as String),
      deliveryAddress: json['delivery_address'] as String?,
      deliveryLat: json['delivery_lat'] != null
          ? (json['delivery_lat'] as num).toDouble()
          : null,
      deliveryLng: json['delivery_lng'] != null
          ? (json['delivery_lng'] as num).toDouble()
          : null,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      paymentNumber: json['payment_number'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      instructions: json['instructions'] as String?,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      preparationTime: json['preparation_time'] as int?,
      kitchenNotes: json['kitchen_notes'] as String?,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'] as String)
          : null,
      driverId: json['driver_id'] as int?,
      // Vérifier si un livreur est assigné via order_driver_assignments
      hasAssignedDriver:
          json['order_driver_assignments'] != null &&
          (json['order_driver_assignments'] as List).isNotEmpty &&
          (json['order_driver_assignments'] as List).any(
            (assignment) => assignment['delivered_at'] == null,
          ), // Livreur assigné et pas encore livré
      orderItems: json['order_items'] != null
          ? (json['order_items'] as List)
                .map(
                  (item) =>
                      OrderItemModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_phone': customerPhone,
      'customer_name': customerName,
      'delivery_type': deliveryType.value,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'payment_method': paymentMethod.value,
      'payment_number': paymentNumber,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'status': status.value,
      'instructions': instructions,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'preparation_time': preparationTime,
      'kitchen_notes': kitchenNotes,
      'accepted_at': acceptedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'driver_id': driverId,
      'order_items': orderItems.map((item) => item.toJson()).toList(),
    };
  }
}
