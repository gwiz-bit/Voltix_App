import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

typedef _HomeData = ({List<Category> categories, List<Product> bestSelling, List<Product> newest});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final service = context.read<ProductService>();
    // Gọi song song 3 API.
    final (categories, best, newest) = await (
      service.getCategories(),
      service.getProducts(sort: ProductSort.bestSelling, size: 6),
      service.getProducts(sort: ProductSort.newest, size: 10),
    ).wait;
    return (categories: categories, bestSelling: best.items, newest: newest.items);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/branding/logo_mark.png', height: 26),
            const SizedBox(width: 8),
            const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat tư vấn',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/chat'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Tìm CPU, VGA, RAM...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) context.push('/products?q=${Uri.encodeQueryComponent(q.trim())}');
              },
            ),
          ),
        ),
      ),
      body: FutureView(
        future: _future,
        onRetry: _refresh,
        builder: (context, data) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            children: [
              _BuilderBanner(onTap: () => context.go('/builder')),
              const _SectionTitle('Danh mục'),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: data.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _CategoryChip(category: data.categories[i]),
                ),
              ),
              _SectionTitle('Bán chạy nhất', onMore: () => context.push('/products?sort=best_selling&title=Bán chạy')),
              ProductGrid(products: data.bestSelling, shrinkWrap: true),
              _SectionTitle('Hàng mới về', onMore: () => context.push('/products?title=Tất cả sản phẩm')),
              ProductGrid(products: data.newest, shrinkWrap: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuilderBanner extends StatelessWidget {
  const _BuilderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.black, AppTheme.primary]),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tự build PC của bạn',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Tự động lọc linh kiện tương thích & gợi ý nguồn',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Icon(Icons.build_circle, color: Colors.white, size: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.onMore});

  final String text;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (onMore != null) TextButton(onPressed: onMore, child: const Text('Xem tất cả')),
          ],
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 80,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            '/products?category=${category.id}&title=${Uri.encodeQueryComponent(category.name)}',
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(categoryIcon(category.slug), color: color),
              const SizedBox(height: 6),
              Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
