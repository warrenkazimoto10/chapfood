import 'order_model.dart';

/// Modèle représentant l'état d'une livraison active sauvegardée localement
class ActiveDeliveryState {
  final int orderId;
  final String status;
  final double? clientLat;
  final double? clientLng;
  final String? clientAddress;
  final DateTime savedAt;
  final bool hasPickedUp;
  final bool hasArrived;
  final Map<String, dynamic>? routeData;

  ActiveDeliveryState({
    required this.orderId,
    required this.status,
    this.clientLat,
    this.clientLng,
    this.clientAddress,
    required this.savedAt,
    this.hasPickedUp = false,
    this.hasArrived = false,
    this.routeData,
  });

  /// Créer depuis un OrderModel
  factory ActiveDeliveryState.fromOrder(
    OrderModel order, {
    bool hasPickedUp = false,
    bool hasArrived = false,
    Map<String, dynamic>? routeData,
  }) {
    return ActiveDeliveryState(
      orderId: order.id,
      status: order.status.value,
      clientLat: order.deliveryLat,
      clientLng: order.deliveryLng,
      clientAddress: order.deliveryAddress,
      savedAt: DateTime.now(),
      hasPickedUp: hasPickedUp,
      hasArrived: hasArrived,
      routeData: routeData,
    );
  }

  /// Convertir en JSON pour sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': status,
      'clientLat': clientLat,
      'clientLng': clientLng,
      'clientAddress': clientAddress,
      'savedAt': savedAt.toIso8601String(),
      'hasPickedUp': hasPickedUp,
      'hasArrived': hasArrived,
      'routeData': routeData,
    };
  }

  /// Créer depuis JSON
  factory ActiveDeliveryState.fromJson(Map<String, dynamic> json) {
    return ActiveDeliveryState(
      orderId: json['orderId'] as int,
      status: json['status'] as String,
      clientLat: json['clientLat'] as double?,
      clientLng: json['clientLng'] as double?,
      clientAddress: json['clientAddress'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      hasPickedUp: json['hasPickedUp'] as bool? ?? false,
      hasArrived: json['hasArrived'] as bool? ?? false,
      routeData: json['routeData'] as Map<String, dynamic>?,
    );
  }

  /// Vérifier si l'état est encore valide (pas trop ancien)
  bool get isValid {
    final age = DateTime.now().difference(savedAt);
    return age.inHours < 24; // Valide pendant 24h
  }
}

