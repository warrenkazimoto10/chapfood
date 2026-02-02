class OrderDriverAssignmentModel {
  final int id;
  final int orderId;
  final int driverId;
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  OrderDriverAssignmentModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory OrderDriverAssignmentModel.fromJson(Map<String, dynamic> json) {
    return OrderDriverAssignmentModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      driverId: json['driver_id'] as int,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      pickedUpAt: json['picked_up_at'] != null 
          ? DateTime.parse(json['picked_up_at'] as String) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'driver_id': driverId,
      'assigned_at': assignedAt.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  bool get isPickedUp => pickedUpAt != null;
  bool get isDelivered => deliveredAt != null;
  
  Duration? get deliveryDuration {
    if (assignedAt != null && deliveredAt != null) {
      return deliveredAt!.difference(assignedAt);
    }
    return null;
  }
}


