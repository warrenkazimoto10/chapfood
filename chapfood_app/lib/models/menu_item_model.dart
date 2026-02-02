class MenuItemModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? categoryId;
  final bool? isAvailable;
  final bool? isPopular;
  final int? preparationTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.isAvailable,
    this.isPopular,
    this.preparationTime,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as int?,
      isAvailable: json['is_available'] as bool?,
      isPopular: json['is_popular'] as bool?,
      preparationTime: json['preparation_time'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_available': isAvailable,
      'is_popular': isPopular,
      'preparation_time': preparationTime,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
