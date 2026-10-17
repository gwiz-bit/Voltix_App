class Product {
  final int id;
  final int categoryId;
  final String brandName;
  final String name;
  final String description;
  final int price;
  final int? salePrice;
  final int stock;
  final String imageUrl;

  /// Thông số kỹ thuật dùng cho PC Builder: socket, ram_type, tdp, ...
  final Map<String, dynamic> specs;

  const Product({
    required this.id,
    required this.categoryId,
    required this.brandName,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.stock,
    required this.imageUrl,
    this.specs = const {},
  });

  int get finalPrice => salePrice ?? price;
  bool get onSale => salePrice != null && salePrice! < price;
  bool get inStock => stock > 0;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        brandName: json['brand_name'] as String? ?? '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: json['price'] as int,
        salePrice: json['sale_price'] as int?,
        stock: json['stock'] as int,
        imageUrl: json['image_url'] as String? ?? '',
        specs: (json['specs'] as Map<String, dynamic>?) ?? const {},
      );
}
