import 'package:flutter/material.dart';

import '../core/format.dart';

enum OrderStatus {
  pending('Chờ xử lý', Colors.grey, Icons.hourglass_empty),
  paid('Đã thanh toán', Colors.teal, Icons.credit_score),
  confirmed('Đã xác nhận', Colors.blue, Icons.inventory_2_outlined),
  shipping('Đang giao', Colors.orange, Icons.local_shipping_outlined),
  completed('Hoàn thành', Colors.green, Icons.check_circle_outline),
  cancelled('Đã huỷ', Colors.red, Icons.cancel_outlined);

  const OrderStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static OrderStatus parse(String value) => OrderStatus.values.byName(value);
}

class OrderItem {
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final int unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        quantity: json['quantity'] as int,
        unitPrice: json['unit_price'] as int,
      );
}

class Order {
  final int id;
  final String customerName;
  final String receiver;
  final String phone;
  final String shippingAddress;
  final String? note;
  final int total;
  final OrderStatus status;
  final String paymentMethod; // COD | VNPAY
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.customerName,
    required this.receiver,
    required this.phone,
    required this.shippingAddress,
    this.note,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  bool get awaitingVnpay => paymentMethod == 'VNPAY' && status == OrderStatus.pending;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        customerName: json['customer_name'] as String? ?? '',
        receiver: json['receiver'] as String,
        phone: json['phone'] as String,
        shippingAddress: json['shipping_address'] as String,
        note: json['note'] as String?,
        total: json['total'] as int,
        status: OrderStatus.parse(json['status'] as String),
        paymentMethod: json['payment_method'] as String,
        createdAt: parseServerTime(json['created_at'] as String),
        items: (json['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
