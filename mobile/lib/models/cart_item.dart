import 'product.dart';

class CartItem {
  final int id;
  final Product product;
  final int quantity;

  const CartItem({required this.id, required this.product, required this.quantity});

  int get subtotal => product.finalPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as int,
        quantity: json['quantity'] as int,
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
      );
}
