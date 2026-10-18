import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/order.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _future = context.read<ShopService>().getOrders();

  void _reload() => setState(() => _future = context.read<ShopService>().getOrders());

  static const _tabs = <(String, Set<OrderStatus>?)>[
    ('Tất cả', null),
    ('Chờ xử lý', {OrderStatus.pending, OrderStatus.paid, OrderStatus.confirmed}),
    ('Đang giao', {OrderStatus.shipping}),
    ('Hoàn thành', {OrderStatus.completed}),
    ('Đã huỷ', {OrderStatus.cancelled}),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          bottom: TabBar(isScrollable: true, tabs: [for (final t in _tabs) Tab(text: t.$1)]),
        ),
        body: FutureView(
          future: _future,
          onRetry: _reload,
          builder: (context, orders) => TabBarView(
            children: [
              for (final (_, statuses) in _tabs)
                OrderList(
                  orders: orders.where((o) => statuses == null || statuses.contains(o.status)).toList(),
                  onRefresh: () async => _reload(),
                  onTap: (o) async {
                    await context.push('/orders/${o.id}');
                    _reload();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách đơn dùng chung cho khách hàng và trang quản trị.
class OrderList extends StatelessWidget {
  const OrderList({super.key, required this.orders, required this.onRefresh, required this.onTap, this.showCustomer = false});

  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final ValueChanged<Order> onTap;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: orders.isEmpty
          ? ListView(children: const [
              SizedBox(height: 300, child: EmptyView(icon: Icons.receipt_long_outlined, message: 'Không có đơn hàng')),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    onTap: () => onTap(o),
                    leading: CircleAvatar(
                      backgroundColor: o.status.color.withValues(alpha: 0.15),
                      child: Icon(o.status.icon, color: o.status.color),
                    ),
                    title: Text('Đơn #${o.id}${showCustomer ? ' · ${o.customerName}' : ''}'),
                    subtitle: Text(
                      '${formatDateTime(o.createdAt)} · ${o.items.length} sản phẩm · ${o.paymentMethod}\n'
                      '${o.status.label}${o.awaitingVnpay ? ' – chờ thanh toán' : ''}',
                    ),
                    isThreeLine: true,
                    trailing: Text(formatVnd(o.total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                );
              },
            ),
    );
  }
}
