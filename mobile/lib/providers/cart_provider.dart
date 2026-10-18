import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/cart_item.dart';
import '../services/shop_service.dart';

/// Giỏ hàng lưu trên server (bảng cart_items) để đồng bộ giữa các thiết bị.
class CartProvider extends ChangeNotifier {
  CartProvider(this._service);

  final ShopService _service;

  List<CartItem> items = [];
  int total = 0;
  int count = 0;
  bool loading = false;
  String? error;

  bool get isEmpty => items.isEmpty;

  Future<void> load() => _run(_service.getCart);

  /// Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> add(int productId, {int quantity = 1}) =>
      _run(() => _service.addToCart(productId, quantity: quantity));

  Future<String?> setQuantity(CartItem item, int quantity) => quantity <= 0
      ? _run(() => _service.removeCartItem(item.id))
      : _run(() => _service.updateCartItem(item.id, quantity));

  Future<String?> remove(CartItem item) => _run(() => _service.removeCartItem(item.id));

  /// Gọi khi đăng xuất hoặc sau khi đặt hàng (server đã xoá giỏ).
  void reset() {
    items = [];
    total = 0;
    count = 0;
    error = null;
    notifyListeners();
  }

  Future<String?> _run(Future<CartData> Function() action) async {
    loading = true;
    notifyListeners();
    try {
      final cart = await action();
      items = cart.items;
      total = cart.total;
      count = cart.count;
      error = null;
    } catch (e) {
      error = ApiClient.messageOf(e);
    } finally {
      loading = false;
      notifyListeners();
    }
    return error;
  }
}
