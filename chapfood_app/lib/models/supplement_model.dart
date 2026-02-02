import 'enums.dart';

class SupplementModel {
  final int id;
  final String name;
  final SupplementType type;
  final double price;
  final bool? isObligatory;
  final bool? isAvailable;
  final DateTime? createdAt;

  SupplementModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.isObligatory,
    this.isAvailable,
    this.createdAt,
  });

  factory SupplementModel.fromJson(Map<String, dynamic> json) {
    return SupplementModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: SupplementType.fromString(json['type'] as String),
      price: (json['price'] as num).toDouble(),
      isObligatory: json['is_obligatory'] as bool?,
      isAvailable: json['is_available'] as bool?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'price': price,
      'is_obligatory': isObligatory,
      'is_available': isAvailable,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
