enum DriverNotificationType {
  orderAvailable,
  orderReady,
  orderAssigned;

  String get value {
    switch (this) {
      case DriverNotificationType.orderAvailable:
        return 'order_available';
      case DriverNotificationType.orderReady:
        return 'order_ready';
      case DriverNotificationType.orderAssigned:
        return 'order_assigned';
    }
  }

  static DriverNotificationType fromString(String value) {
    switch (value) {
      case 'order_available':
        return DriverNotificationType.orderAvailable;
      case 'order_ready':
        return DriverNotificationType.orderReady;
      case 'order_assigned':
        return DriverNotificationType.orderAssigned;
      default:
        return DriverNotificationType.orderAvailable;
    }
  }

  String get displayName {
    switch (this) {
      case DriverNotificationType.orderAvailable:
        return 'Commande disponible';
      case DriverNotificationType.orderReady:
        return 'Commande prête';
      case DriverNotificationType.orderAssigned:
        return 'Commande assignée';
    }
  }
}

class DriverNotificationModel {
  final String id;
  final int driverId;
  final int? orderId;
  final String message;
  final DriverNotificationType type;
  final DateTime? readAt;
  final DateTime createdAt;

  DriverNotificationModel({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.message,
    required this.type,
    this.readAt,
    required this.createdAt,
  });

  factory DriverNotificationModel.fromJson(Map<String, dynamic> json) {
    return DriverNotificationModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as int,
      orderId: json['order_id'] as int?,
      message: json['message'] as String,
      type: DriverNotificationType.fromString(json['type'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'order_id': orderId,
      'message': message,
      'type': type.value,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRead => readAt != null;

  DriverNotificationModel markAsRead() {
    return copyWith(readAt: DateTime.now());
  }

  DriverNotificationModel copyWith({
    String? id,
    int? driverId,
    int? orderId,
    String? message,
    DriverNotificationType? type,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return DriverNotificationModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      orderId: orderId ?? this.orderId,
      message: message ?? this.message,
      type: type ?? this.type,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DriverNotificationModel(id: $id, type: ${type.displayName}, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverNotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
