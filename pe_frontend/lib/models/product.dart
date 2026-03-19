class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int stock;
  final String userId;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.stock,
    required this.userId,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      stock: json['stock'] as int? ?? 0,
      userId: (json['userId'] is Map ? json['userId']['_id'] : json['userId']) as String? ?? '',
      createdAt: json['createAt'] != null
          ? DateTime.tryParse(json['createAt'] as String) ?? DateTime(0)
          : DateTime(0),
    );
  }
}
