import '../core/api_client.dart';
import '../models/category.dart';
import '../models/misc.dart';
import '../models/product.dart';

enum ProductSort {
  newest('Mới nhất'),
  bestSelling('Bán chạy'),
  priceAsc('Giá tăng dần'),
  priceDesc('Giá giảm dần');

  const ProductSort(this.label);

  final String label;

  String get apiValue => switch (this) {
        ProductSort.newest => 'newest',
        ProductSort.bestSelling => 'best_selling',
        ProductSort.priceAsc => 'price_asc',
        ProductSort.priceDesc => 'price_desc',
      };
}

typedef ProductPage = ({List<Product> items, int total});

class ProductService {
  final _dio = ApiClient.dio;

  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/categories');
    return (res.data as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Brand>> getBrands() async {
    final res = await _dio.get('/brands');
    return (res.data as List).map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductPage> getProducts({
    int? categoryId,
    int? brandId,
    String? search,
    ProductSort sort = ProductSort.newest,
    int page = 1,
    int size = 20,
  }) async {
    final res = await _dio.get('/products', queryParameters: {
      'category': ?categoryId,
      'brand': ?brandId,
      if (search != null && search.isNotEmpty) 'search': search,
      'sort': sort.apiValue,
      'page': page,
      'size': size,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      items: (data['items'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  Future<Product> getProduct(int id) async {
    final res = await _dio.get('/products/$id');
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Review>> getReviews(int productId) async {
    final res = await _dio.get('/products/$productId/reviews');
    return (res.data as List).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> canReview(int productId) async {
    final res = await _dio.get('/products/$productId/reviews/eligibility');
    return (res.data as Map<String, dynamic>)['can_review'] as bool;
  }

  Future<void> createReview(int productId, int rating, String? comment) =>
      _dio.post('/products/$productId/reviews', data: {'rating': rating, 'comment': comment});
}
