import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// Giỏ hàng lưu trong bộ nhớ ở Mốc 1; Mốc 3 sẽ đồng bộ với API /cart.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  int get total => _items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  /// Trả về false nếu vượt quá tồn kho.
  bool add(Product product, {int quantity = 1}) {
    final existing = _items.where((i) => i.product.id == product.id).firstOrNull;
    final newQty = (existing?.quantity ?? 0) + quantity;
    if (newQty > product.stock) return false;
    if (existing != null) {
      existing.quantity = newQty;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
    return true;
  }

  void setQuantity(int productId, int quantity) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    if (quantity <= 0) {
      _items.remove(item);
    } else if (quantity <= item.product.stock) {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
