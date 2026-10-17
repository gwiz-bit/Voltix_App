import 'package:flutter_test/flutter_test.dart';
import 'package:pcparts_mobile/core/validators.dart';
import 'package:pcparts_mobile/models/product.dart';
import 'package:pcparts_mobile/providers/cart_provider.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('phone', () {
      expect(Validators.phone('0901234567'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });

    test('password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('123'), isNotNull);
    });
  });

  group('CartProvider', () {
    const product = Product(
      id: 1,
      categoryId: 1,
      brandName: 'Intel',
      name: 'CPU',
      description: '',
      price: 1000,
      salePrice: 800,
      stock: 2,
      imageUrl: '',
    );

    test('cộng dồn số lượng và tính tổng theo giá khuyến mãi', () {
      final cart = CartProvider();
      expect(cart.add(product), isTrue);
      expect(cart.add(product), isTrue);
      expect(cart.count, 2);
      expect(cart.total, 1600);
    });

    test('không cho vượt tồn kho', () {
      final cart = CartProvider();
      expect(cart.add(product, quantity: 3), isFalse);
      expect(cart.isEmpty, isTrue);
    });
  });
}
