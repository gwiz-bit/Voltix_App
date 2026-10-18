import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/misc.dart';
import '../../providers/cart_provider.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';

/// Các cấu hình PC đã lưu.
class BuildsScreen extends StatefulWidget {
  const BuildsScreen({super.key});

  @override
  State<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends State<BuildsScreen> {
  late Future<List<PcBuild>> _future = context.read<ShopService>().getBuilds();

  void _reload() => setState(() => _future = context.read<ShopService>().getBuilds());

  Future<void> _delete(PcBuild b) async {
    try {
      await context.read<ShopService>().deleteBuild(b.id);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    }
  }

  Future<void> _addToCart(PcBuild b) async {
    final cart = context.read<CartProvider>();
    String? error;
    for (final p in b.products) {
      error = await cart.add(p.id) ?? error;
    }
    if (!mounted) return;
    if (error != null) {
      showMessage(context, error, error: true);
    } else {
      context.go('/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình đã lưu')),
      body: FutureView(
        future: _future,
        onRetry: _reload,
        builder: (context, builds) => builds.isEmpty
            ? const EmptyView(icon: Icons.bookmarks_outlined, message: 'Bạn chưa lưu cấu hình nào')
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: builds.length,
                itemBuilder: (_, i) {
                  final b = builds[i];
                  return Card(
                    child: ExpansionTile(
                      title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${b.products.length} linh kiện · ${formatVnd(b.total)} · ${formatDateTime(b.createdAt)}'),
                      children: [
                        for (final p in b.products)
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                            title: Text(p.name),
                            trailing: Text(formatVnd(p.finalPrice)),
                            onTap: () => context.push('/products/${p.id}'),
                          ),
                        OverflowBar(
                          children: [
                            TextButton.icon(
                              onPressed: () => _delete(b),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Xoá', style: TextStyle(color: Colors.red)),
                            ),
                            FilledButton.icon(
                              onPressed: () => _addToCart(b),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Thêm vào giỏ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
