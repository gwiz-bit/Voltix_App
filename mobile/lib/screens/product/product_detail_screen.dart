import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Product> _load() => context.read<ProductService>().getProduct(widget.productId);

  void _addToCart(Product product) {
    final ok = context.read<CartProvider>().add(product);
    showMessage(
      context,
      ok ? 'Đã thêm "${product.name}" vào giỏ' : 'Số lượng vượt quá tồn kho',
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: ApiClient.messageOf(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            ),
          );
        }
        final p = snapshot.data!;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(p.brandName)),
          body: ListView(
            children: [
              AspectRatio(aspectRatio: 1.3, child: ProductImage(p.imageUrl, fit: BoxFit.contain)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatVnd(p.finalPrice),
                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (p.onSale)
                          Text(
                            formatVnd(p.price),
                            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.inStock ? 'Còn ${p.stock} sản phẩm' : 'Hết hàng',
                      style: TextStyle(color: p.inStock ? Colors.green : Colors.grey),
                    ),
                    const Divider(height: 32),
                    Text('Mô tả', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(p.description),
                    if (p.specs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Thông số kỹ thuật', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final e in p.specs.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(e.key, style: const TextStyle(color: Colors.grey))),
                              Text('${e.value}'),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: p.inStock ? () => _addToCart(p) : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(p.inStock ? 'Thêm vào giỏ hàng' : 'Hết hàng'),
              ),
            ),
          ),
        );
      },
    );
  }
}
