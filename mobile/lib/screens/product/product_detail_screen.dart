import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../models/misc.dart';
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
  late Future<(Product, List<Review>, bool)> _future;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Product, List<Review>, bool)> _load() async {
    final service = context.read<ProductService>();
    return (
      service.getProduct(widget.productId),
      service.getReviews(widget.productId),
      service.canReview(widget.productId).catchError((_) => false),
    ).wait;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addToCart(Product product, {bool buyNow = false}) async {
    setState(() => _adding = true);
    final error = await context.read<CartProvider>().add(product.id);
    if (!mounted) return;
    setState(() => _adding = false);
    if (error != null) {
      showMessage(context, error, error: true);
    } else if (buyNow) {
      context.go('/cart');
    } else {
      showMessage(context, 'Đã thêm "${product.name}" vào giỏ');
    }
  }

  Future<void> _writeReview(Product product) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(productId: product.id),
    );
    if (submitted == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: FutureView(future: _future, onRetry: _reload, builder: (_, _) => const SizedBox()),
          );
        }
        final (p, reviews, canReview) = snapshot.data!;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(p.categoryName)),
          body: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              children: [
                AspectRatio(aspectRatio: 1.2, child: ProductImage(p.imageUrl, fit: BoxFit.contain)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.brandName, style: TextStyle(color: theme.colorScheme.primary)),
                      Text(p.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (p.reviewCount > 0)
                        Row(children: [
                          RatingStars(rating: p.avgRating),
                          Text('  ${p.avgRating} · ${p.reviewCount} đánh giá'),
                        ]),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            formatVnd(p.finalPrice),
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          if (p.onSale)
                            Text(formatVnd(p.price),
                                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
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
                        Table(
                          columnWidths: const {0: IntrinsicColumnWidth()},
                          children: [
                            for (final e in p.specs.entries)
                              TableRow(children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 4, 24, 4),
                                  child: Text(_specLabel(e.key), style: const TextStyle(color: Colors.grey)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(e.value is List ? (e.value as List).join(', ') : '${e.value}'),
                                ),
                              ]),
                          ],
                        ),
                      ],
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(child: Text('Đánh giá (${reviews.length})', style: theme.textTheme.titleMedium)),
                          if (canReview)
                            TextButton.icon(
                              onPressed: () => _writeReview(p),
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text('Viết đánh giá'),
                            ),
                        ],
                      ),
                      if (reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Chưa có đánh giá. Mua và nhận hàng để đánh giá sản phẩm.',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      for (final r in reviews)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(r.userName.characters.first)),
                          title: Row(children: [
                            Flexible(child: Text(r.userName, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            RatingStars(rating: r.rating.toDouble(), size: 14),
                          ]),
                          subtitle: Text('${r.comment ?? ''}\n${formatDateTime(r.createdAt)}'),
                          isThreeLine: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: p.inStock && !_adding ? () => _addToCart(p) : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Thêm vào giỏ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LoadingButton(
                      loading: _adding,
                      onPressed: p.inStock ? () => _addToCart(p, buyNow: true) : null,
                      child: Text(p.inStock ? 'Mua ngay' : 'Hết hàng'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _specLabel(String key) => switch (key) {
        'socket' => 'Socket',
        'ram_type' => 'Chuẩn RAM',
        'tdp' => 'TDP (W)',
        'cores' => 'Số nhân',
        'threads' => 'Số luồng',
        'capacity_gb' => 'Dung lượng (GB)',
        'speed' => 'Bus (MHz)',
        'vram_gb' => 'VRAM (GB)',
        'wattage' => 'Công suất (W)',
        'interface' => 'Giao tiếp',
        'form' => 'Kích thước',
        'type' => 'Loại',
        'sockets' => 'Hỗ trợ socket',
        _ => key,
      };
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.productId});

  final int productId;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await context.read<ProductService>().createReview(widget.productId, _rating, _comment.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showMessage(context, 'Không gửi được đánh giá', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đánh giá sản phẩm', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                ),
            ],
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(hintText: 'Chia sẻ trải nghiệm của bạn...'),
          ),
          const SizedBox(height: 8),
          LoadingButton(loading: _sending, onPressed: _submit, child: const Text('Gửi đánh giá')),
        ],
      ),
    );
  }
}
