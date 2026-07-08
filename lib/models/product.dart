class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String image;
  final List<String> images;
  final String categoryId;
  final int sales;
  final double rating;
  final List<String> specs;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    this.image = '',
    this.images = const [],
    required this.categoryId,
    this.sales = 0,
    this.rating = 5.0,
    this.specs = const [],
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: '${json['id'] ?? ''}',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0,
      image: json['image'] ?? '',
      images: json['images'] is List ? (json['images'] as List).cast<String>() : [],
      categoryId: '${json['category_id'] ?? ''}',
      sales: json['sales'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      specs: json['specs'] is List ? (json['specs'] as List).cast<String>() : [],
      stock: json['stock'] ?? 0,
    );
  }

  double get discount =>
      originalPrice > 0 ? (1 - price / originalPrice) : 0;

  String get discountText => '${(discount * 100).toInt()}% OFF';
}
