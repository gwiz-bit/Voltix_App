import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _change(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) showMessage(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.count})'),
        bottom: cart.loading
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: cart.load,
        child: cart.isEmpty
            ? ListView(children: [
                SizedBox(
                  height: 400,
                  child: cart.error != null
                      ? ErrorView(message: cart.error!, onRetry: cart.load)
                      : EmptyView(
                          icon: Icons.remove_shopping_cart_outlined,
                          message: 'Giỏ hàng trống',
                          action: OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Mua sắm ngay')),
                        ),
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: cart.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _CartTile(
                  item: cart.items[i],
                  onChange: (q) => _change(context, cart.setQuantity(cart.items[i], q)),
                  onRemove: () => _change(context, cart.remove(cart.items[i])),
                ),
              ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng cộng'),
                          Text(
                            formatVnd(cart.total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: FilledButton(
                        onPressed: cart.loading ? null : () => context.push('/checkout'),
                        child: const Text('Đặt hàng'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, required this.onChange, required this.onRemove});

  final CartItem item;
  final ValueChanged<int> onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/products/${p.id}'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 72, height: 72, child: ProductImage(p.imageUrl)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(formatVnd(p.finalPrice),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      if (item.quantity > p.stock)
                        Text('Chỉ còn ${p.stock} sản phẩm', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: item.quantity < p.stock ? () => onChange(item.quantity + 1) : null,
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(item.quantity == 1 ? Icons.delete_outline : Icons.remove_circle_outline),
                      onPressed: () => onChange(item.quantity - 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
