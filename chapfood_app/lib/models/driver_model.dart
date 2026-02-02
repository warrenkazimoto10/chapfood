class DriverModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final bool isAvailable;
  final bool isActive;
  final double? currentLat;
  final double? currentLng;
  final String? address;
  final String vehicleType;
  final Map<String, dynamic>? vehicleInfo;
  final List<String> deliveryZones;
  final Map<String, dynamic>? workingHours;
  final int maxDeliveryDistance;
  final double rating;
  final int totalDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.isAvailable,
    required this.isActive,
    this.currentLat,
    this.currentLng,
    this.address,
    this.vehicleType = 'moto',
    this.vehicleInfo,
    this.deliveryZones = const [],
    this.workingHours,
    this.maxDeliveryDistance = 10,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      currentLat: json['current_lat'] != null 
          ? (json['current_lat'] as num).toDouble() 
          : null,
      currentLng: json['current_lng'] != null 
          ? (json['current_lng'] as num).toDouble() 
          : null,
      address: json['address'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? 'moto',
      vehicleInfo: json['vehicle_info'] as Map<String, dynamic>?,
      deliveryZones: (json['delivery_zones'] as List<dynamic>?)?.cast<String>() ?? [],
      workingHours: json['working_hours'] as Map<String, dynamic>?,
      maxDeliveryDistance: json['max_delivery_distance'] as int? ?? 10,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'is_available': isAvailable,
      'is_active': isActive,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'address': address,
      'vehicle_type': vehicleType,
      'vehicle_info': vehicleInfo,
      'delivery_zones': deliveryZones,
      'working_hours': workingHours,
      'max_delivery_distance': maxDeliveryDistance,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  String get vehicleDisplayName {
    switch (vehicleType.toLowerCase()) {
      case 'moto':
        return 'Moto';
      case 'car':
        return 'Voiture';
      case 'bike':
        return 'Vélo';
      case 'walking':
        return 'À pied';
      default:
        return vehicleType;
    }
  }

  String get ratingDisplay {
    return rating > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'Nouveau';
  }

  bool get hasLocation {
    return currentLat != null && currentLng != null;
  }

  String get statusText {
    if (!isActive) return 'Inactif';
    if (!isAvailable) return 'Occupé';
    return 'Disponible';
  }
}
