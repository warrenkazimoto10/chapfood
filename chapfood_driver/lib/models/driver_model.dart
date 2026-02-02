class DriverModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? vehicleType;
  final double? rating;
  final bool isActive;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final String? address;
  final int totalDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.vehicleType,
    this.rating,
    required this.isActive,
    required this.isAvailable,
    this.currentLat,
    this.currentLng,
    this.address,
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
      vehicleType: json['vehicle_type'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isActive: json['is_active'] as bool? ?? true,
      isAvailable: json['is_available'] as bool? ?? true,
      currentLat: json['current_lat'] != null ? (json['current_lat'] as num).toDouble() : null,
      currentLng: json['current_lng'] != null ? (json['current_lng'] as num).toDouble() : null,
      address: json['address'] as String?,
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
      'vehicle_type': vehicleType,
      'rating': rating,
      'is_active': isActive,
      'is_available': isAvailable,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'address': address,
      'total_deliveries': totalDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DriverModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    double? rating,
    bool? isActive,
    bool? isAvailable,
    double? currentLat,
    double? currentLng,
    String? address,
    int? totalDeliveries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      address: address ?? this.address,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DriverModel(id: $id, name: $name, phone: $phone, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getters pour l'affichage
  String get vehicleDisplayName {
    switch (vehicleType?.toLowerCase()) {
      case 'moto':
        return 'Moto';
      case 'car':
        return 'Voiture';
      case 'bike':
        return 'Vélo';
      case 'walking':
        return 'À pied';
      default:
        return vehicleType ?? 'Non spécifié';
    }
  }

  String get ratingDisplay {
    if (rating == null) return 'N/A';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }
}
