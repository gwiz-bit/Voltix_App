class Product {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categorySlug;
  final int brandId;
  final String brandName;
  final String name;
  final String description;
  final int price;
  final int? salePrice;
  final int stock;
  final String imageUrl;
  final double avgRating;
  final int reviewCount;

  /// Thông số kỹ thuật dùng cho PC Builder: socket, ram_type, tdp, wattage, ...
  final Map<String, dynamic> specs;

  const Product({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    this.categorySlug = '',
    this.brandId = 0,
    required this.brandName,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.stock,
    required this.imageUrl,
    this.avgRating = 0,
    this.reviewCount = 0,
    this.specs = const {},
  });

  int get finalPrice => salePrice ?? price;
  bool get onSale => salePrice != null && salePrice! < price;
  bool get inStock => stock > 0;
  int get tdp => (specs['tdp'] as num?)?.toInt() ?? 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        categoryName: json['category_name'] as String? ?? '',
        categorySlug: json['category_slug'] as String? ?? '',
        brandId: json['brand_id'] as int? ?? 0,
        brandName: json['brand_name'] as String? ?? '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: json['price'] as int,
        salePrice: json['sale_price'] as int?,
        stock: json['stock'] as int,
        imageUrl: json['image_url'] as String? ?? '',
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        specs: (json['specs'] as Map<String, dynamic>?) ?? const {},
      );
}
