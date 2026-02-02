class OrderDriverAssignmentModel {
  final int id;
  final int orderId;
  final int driverId;
  final DateTime assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;

  OrderDriverAssignmentModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.assignedAt,
    this.pickedUpAt,
    this.arrivedAt,
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
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'] as String)
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
      'arrived_at': arrivedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'OrderDriverAssignmentModel(id: $id, orderId: $orderId, driverId: $driverId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderDriverAssignmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Méthodes utilitaires
  bool get isPickedUp => pickedUpAt != null;
  bool get isArrived => arrivedAt != null;
  bool get isDelivered => deliveredAt != null;

  Duration? get deliveryDuration {
    if (assignedAt != null && deliveredAt != null) {
      return deliveredAt!.difference(assignedAt);
    }
    return null;
  }
}
