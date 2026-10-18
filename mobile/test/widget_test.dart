import 'package:flutter_test/flutter_test.dart';
import 'package:pcparts_mobile/core/validators.dart';
import 'package:pcparts_mobile/models/order.dart';
import 'package:pcparts_mobile/models/product.dart';

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

  group('Models', () {
    test('Product.fromJson dùng giá khuyến mãi và đọc specs', () {
      final p = Product.fromJson({
        'id': 1,
        'category_id': 1,
        'category_name': 'CPU',
        'brand_id': 2,
        'brand_name': 'AMD',
        'name': 'Ryzen 5 7600',
        'description': null,
        'price': 5000000,
        'sale_price': 4500000,
        'stock': 3,
        'image_url': null,
        'specs': {'socket': 'AM5', 'tdp': 65},
        'avg_rating': 4.5,
        'review_count': 2,
      });
      expect(p.finalPrice, 4500000);
      expect(p.onSale, isTrue);
      expect(p.tdp, 65);
      expect(p.specs['socket'], 'AM5');
    });

    test('Order.fromJson parse trạng thái và đơn VNPay chờ thanh toán', () {
      final o = Order.fromJson({
        'id': 7,
        'customer_name': 'A',
        'receiver': 'A',
        'phone': '0901234567',
        'shipping_address': '1 Lê Lợi',
        'note': null,
        'total': 100,
        'status': 'pending',
        'payment_method': 'VNPAY',
        'created_at': '2026-10-18T10:00:00',
        'items': [
          {'product_id': 1, 'product_name': 'X', 'image_url': null, 'quantity': 2, 'unit_price': 50},
        ],
      });
      expect(o.status, OrderStatus.pending);
      expect(o.awaitingVnpay, isTrue);
      expect(o.items.single.quantity, 2);
    });
  });
}
