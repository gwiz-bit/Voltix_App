import '../core/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';

abstract class ProductService {
  Future<List<Category>> getCategories();

  Future<List<Product>> getProducts({int? categoryId, String? search});

  Future<Product> getProduct(int id);
}

/// Gọi backend FastAPI (dùng từ Mốc 3).
class ApiProductService implements ProductService {
  final _dio = ApiClient.dio;

  @override
  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/categories');
    return (res.data as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Product>> getProducts({int? categoryId, String? search}) async {
    final res = await _dio.get('/products', queryParameters: {
      'category': ?categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final items = (res.data as Map<String, dynamic>)['items'] as List;
    return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Product> getProduct(int id) async {
    final res = await _dio.get('/products/$id');
    return Product.fromJson(res.data as Map<String, dynamic>);
  }
}

/// Dữ liệu giả để dựng UI ở Mốc 1 (sẽ chuyển thành seed.sql cho MySQL ở Mốc 2).
class MockProductService implements ProductService {
  static const _categories = [
    Category(id: 1, name: 'CPU', slug: 'cpu'),
    Category(id: 2, name: 'Mainboard', slug: 'mainboard'),
    Category(id: 3, name: 'RAM', slug: 'ram'),
    Category(id: 4, name: 'Card đồ hoạ', slug: 'vga'),
    Category(id: 5, name: 'SSD', slug: 'ssd'),
    Category(id: 6, name: 'Nguồn', slug: 'psu'),
    Category(id: 7, name: 'Vỏ case', slug: 'case'),
    Category(id: 8, name: 'Tản nhiệt', slug: 'cooler'),
  ];

  static String _img(String text) => 'https://placehold.co/400x400/png?text=${Uri.encodeComponent(text)}';

  static final _products = [
    Product(id: 1, categoryId: 1, brandName: 'Intel', name: 'Intel Core i5-14400F', description: '10 nhân 16 luồng, xung tối đa 4.7GHz.', price: 4290000, salePrice: 3990000, stock: 25, imageUrl: _img('i5-14400F'), specs: {'socket': 'LGA1700', 'tdp': 65}),
    Product(id: 2, categoryId: 1, brandName: 'AMD', name: 'AMD Ryzen 5 7600', description: '6 nhân 12 luồng, Zen 4, hỗ trợ DDR5.', price: 5190000, stock: 18, imageUrl: _img('Ryzen 5 7600'), specs: {'socket': 'AM5', 'tdp': 65}),
    Product(id: 3, categoryId: 1, brandName: 'AMD', name: 'AMD Ryzen 7 7800X3D', description: '8 nhân 16 luồng, 3D V-Cache, CPU chơi game hàng đầu.', price: 10990000, salePrice: 10490000, stock: 7, imageUrl: _img('Ryzen 7 7800X3D'), specs: {'socket': 'AM5', 'tdp': 120}),
    Product(id: 4, categoryId: 2, brandName: 'ASUS', name: 'ASUS PRIME B760M-A WIFI D4', description: 'Mainboard mATX, socket LGA1700, DDR4, WiFi 6.', price: 3490000, stock: 12, imageUrl: _img('B760M-A'), specs: {'socket': 'LGA1700', 'ram_type': 'DDR4'}),
    Product(id: 5, categoryId: 2, brandName: 'MSI', name: 'MSI B650M GAMING PLUS WIFI', description: 'Mainboard mATX, socket AM5, DDR5.', price: 4190000, stock: 9, imageUrl: _img('B650M Gaming'), specs: {'socket': 'AM5', 'ram_type': 'DDR5'}),
    Product(id: 6, categoryId: 3, brandName: 'Kingston', name: 'Kingston Fury Beast 16GB (2x8GB) DDR4 3200', description: 'Kit RAM 16GB bus 3200MHz.', price: 1090000, stock: 40, imageUrl: _img('Fury DDR4 16GB'), specs: {'ram_type': 'DDR4'}),
    Product(id: 7, categoryId: 3, brandName: 'Corsair', name: 'Corsair Vengeance 32GB (2x16GB) DDR5 6000', description: 'Kit RAM DDR5 32GB, hỗ trợ EXPO/XMP.', price: 2890000, salePrice: 2690000, stock: 22, imageUrl: _img('Vengeance DDR5 32GB'), specs: {'ram_type': 'DDR5'}),
    Product(id: 8, categoryId: 4, brandName: 'GIGABYTE', name: 'GIGABYTE RTX 4060 WINDFORCE OC 8GB', description: 'Card đồ hoạ RTX 4060, DLSS 3.', price: 7990000, salePrice: 7590000, stock: 15, imageUrl: _img('RTX 4060'), specs: {'tdp': 115}),
    Product(id: 9, categoryId: 4, brandName: 'ASUS', name: 'ASUS Dual RTX 4070 SUPER 12GB', description: 'Card đồ hoạ RTX 4070 SUPER, chơi tốt 2K.', price: 16490000, stock: 6, imageUrl: _img('RTX 4070 SUPER'), specs: {'tdp': 220}),
    Product(id: 10, categoryId: 5, brandName: 'Samsung', name: 'Samsung 990 EVO 1TB NVMe', description: 'SSD NVMe PCIe 4.0, đọc 5000MB/s.', price: 2190000, stock: 30, imageUrl: _img('990 EVO 1TB')),
    Product(id: 11, categoryId: 6, brandName: 'Corsair', name: 'Corsair RM750e 750W 80 Plus Gold', description: 'Nguồn full modular, ATX 3.0.', price: 2590000, stock: 14, imageUrl: _img('RM750e'), specs: {'wattage': 750}),
    Product(id: 12, categoryId: 7, brandName: 'NZXT', name: 'NZXT H5 Flow', description: 'Vỏ case mid-tower, thông gió tốt.', price: 2290000, stock: 0, imageUrl: _img('NZXT H5 Flow')),
    Product(id: 13, categoryId: 8, brandName: 'Deepcool', name: 'Deepcool AK400', description: 'Tản khí 4 ống đồng, hỗ trợ LGA1700/AM5.', price: 690000, stock: 35, imageUrl: _img('AK400')),
  ];

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<Category>> getCategories() async {
    await _latency();
    return _categories;
  }

  @override
  Future<List<Product>> getProducts({int? categoryId, String? search}) async {
    await _latency();
    final q = search?.trim().toLowerCase() ?? '';
    return _products
        .where((p) => categoryId == null || p.categoryId == categoryId)
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.brandName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Product> getProduct(int id) async {
    await _latency();
    return _products.firstWhere((p) => p.id == id, orElse: () => throw Exception('Không tìm thấy sản phẩm'));
  }
}
