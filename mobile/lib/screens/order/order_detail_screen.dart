import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';
import '../checkout/vnpay_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order> _future = _load();
  bool _busy = false;

  Future<Order> _load() => context.read<ShopService>().getOrder(widget.orderId);

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reload();
      }
    }
  }

  Future<void> _cancel(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ đơn hàng'),
        content: Text('Bạn có chắc muốn huỷ đơn #${order.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Huỷ đơn')),
        ],
      ),
    );
    if (ok == true) await _run(() => context.read<ShopService>().cancelOrder(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().user?.isStaff ?? false;
    return Scaffold(
      appBar: AppBar(title: Text('Đơn hàng #${widget.orderId}')),
      body: FutureView(
        future: _future,
        onRetry: _reload,
        builder: (context, order) => RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _StatusCard(order: order),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giao đến', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${order.receiver} · ${order.phone}'),
                      Text(order.shippingAddress),
                      if (order.note != null) Text('Ghi chú: ${order.note}', style: const TextStyle(color: Colors.grey)),
                      const Divider(),
                      Text('Ngày đặt: ${formatDateTime(order.createdAt)}'),
                      Text('Thanh toán: ${order.paymentMethod == 'VNPAY' ? 'VNPay' : 'Khi nhận hàng (COD)'}'),
                    ],
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final item in order.items)
                      ListTile(
                        onTap: () => context.push('/products/${item.productId}'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(width: 48, height: 48, child: ProductImage(item.imageUrl)),
                        ),
                        title: Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${formatVnd(item.unitPrice)} × ${item.quantity}'),
                        trailing: order.status == OrderStatus.completed && !isStaff
                            ? const Icon(Icons.rate_review_outlined, color: Colors.amber)
                            : Text(formatVnd(item.unitPrice * item.quantity)),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(formatVnd(order.total),
                          style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (order.status == OrderStatus.completed && !isStaff)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Chạm vào sản phẩm để viết đánh giá.', style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 8),
              if (isStaff)
                _StaffActions(order: order, busy: _busy, onChange: (s) => _run(() => context.read<AdminService>().updateStatus(order.id, s)))
              else ...[
                if (order.awaitingVnpay)
                  LoadingButton(
                    loading: _busy,
                    onPressed: () => _run(() => payWithVnpay(context, order.id)),
                    child: const Text('Thanh toán VNPay'),
                  ),
                if (order.status == OrderStatus.pending) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: Colors.red),
                    onPressed: _busy ? null : () => _cancel(order),
                    child: const Text('Huỷ đơn hàng'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final Order order;

  static const _flow = [OrderStatus.pending, OrderStatus.confirmed, OrderStatus.shipping, OrderStatus.completed];

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return Card(
        color: Colors.red.shade50,
        child: const ListTile(
          leading: Icon(Icons.cancel, color: Colors.red),
          title: Text('Đơn hàng đã bị huỷ'),
        ),
      );
    }
    // "Đã thanh toán" nằm giữa chờ xử lý và xác nhận.
    final current = order.status == OrderStatus.paid ? 0 : _flow.indexOf(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            for (var i = 0; i < _flow.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Icon(_flow[i].icon, color: i <= current ? _flow[i].color : Colors.grey.shade300),
                    const SizedBox(height: 4),
                    Text(
                      i == 0 && order.status == OrderStatus.paid ? 'Đã thanh toán' : _flow[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: i <= current ? null : Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffActions extends StatelessWidget {
  const _StaffActions({required this.order, required this.busy, required this.onChange});

  final Order order;
  final bool busy;
  final ValueChanged<OrderStatus> onChange;

  @override
  Widget build(BuildContext context) {
    final next = orderTransitions[order.status]!;
    if (next.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in next)
          FilledButton.tonalIcon(
            onPressed: busy ? null : () => onChange(s),
            icon: Icon(s.icon, color: s.color),
            label: Text('Chuyển: ${s.label}'),
          ),
      ],
    );
  }
}
