import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../models/misc.dart';
import '../models/order.dart';
import '../models/product.dart';

typedef CartData = ({List<CartItem> items, int total, int count});

/// Giỏ hàng, sổ địa chỉ, đơn hàng, thanh toán VNPay và PC Builder.
class ShopService {
  final _dio = ApiClient.dio;

  // ===== Giỏ hàng =====
  Future<CartData> getCart() async => _cart((await _dio.get('/cart')).data);

  Future<CartData> addToCart(int productId, {int quantity = 1}) async =>
      _cart((await _dio.post('/cart/items', data: {'product_id': productId, 'quantity': quantity})).data);

  Future<CartData> updateCartItem(int itemId, int quantity) async =>
      _cart((await _dio.put('/cart/items/$itemId', data: {'quantity': quantity})).data);

  Future<CartData> removeCartItem(int itemId) async => _cart((await _dio.delete('/cart/items/$itemId')).data);

  CartData _cart(dynamic data) {
    final map = data as Map<String, dynamic>;
    return (
      items: (map['items'] as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
      total: map['total'] as int,
      count: map['count'] as int,
    );
  }

  // ===== Sổ địa chỉ =====
  Future<List<Address>> getAddresses() async {
    final res = await _dio.get('/addresses');
    return (res.data as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> createAddress({
    required String receiver,
    required String phone,
    required String detail,
    bool isDefault = false,
  }) async {
    final res = await _dio.post('/addresses', data: {
      'receiver': receiver,
      'phone': phone,
      'detail': detail,
      'is_default': isDefault,
    });
    return Address.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) => _dio.delete('/addresses/$id');

  // ===== Đơn hàng =====
  Future<Order> createOrder({
    required String receiver,
    required String phone,
    required String address,
    String? note,
    required String paymentMethod,
  }) async {
    final res = await _dio.post('/orders', data: {
      'receiver': receiver,
      'phone': phone,
      'shipping_address': address,
      'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      'payment_method': paymentMethod,
    });
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders() async {
    final res = await _dio.get('/orders');
    return (res.data as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(int id) async => Order.fromJson((await _dio.get('/orders/$id')).data as Map<String, dynamic>);

  Future<Order> cancelOrder(int id) async =>
      Order.fromJson((await _dio.post('/orders/$id/cancel')).data as Map<String, dynamic>);

  Future<String> createVnpayUrl(int orderId) async {
    final res = await _dio.post('/payments/vnpay/create', data: {'order_id': orderId});
    return (res.data as Map<String, dynamic>)['payment_url'] as String;
  }

  // ===== PC Builder =====
  Future<List<Product>> compatibleProducts(String categorySlug, List<int> selectedIds) async {
    final res = await _dio.get('/builder/compatible', queryParameters: {
      'category': categorySlug,
      'selected': selectedIds.join(','),
    });
    return (res.data as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// AI gợi ý cấu hình hoàn chỉnh. [purpose]: gaming | office | design | streaming.
  Future<AiBuild> aiSuggest({required int budget, required String purpose, String? notes}) async {
    final res = await _dio.post(
      '/builder/ai-suggest',
      data: {'budget': budget, 'purpose': purpose, if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim()},
      // Khi bật Claude, lời tư vấn có thể mất vài giây.
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return AiBuild.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<PcBuild>> getBuilds() async {
    final res = await _dio.get('/builds');
    return (res.data as List).map((e) => PcBuild.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PcBuild> saveBuild(String name, List<int> productIds) async {
    final res = await _dio.post('/builds', data: {'name': name, 'product_ids': productIds});
    return PcBuild.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteBuild(int id) => _dio.delete('/builds/$id');
}
