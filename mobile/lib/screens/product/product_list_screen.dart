import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/misc.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

/// Danh sách sản phẩm: lọc theo danh mục/từ khoá/thương hiệu, sắp xếp, cuộn để tải thêm.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.search, this.title, this.sort});

  final int? categoryId;
  final String? search;
  final String? title;
  final ProductSort? sort;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _pageSize = 20;

  final _scroll = ScrollController();
  final List<Product> _items = [];
  List<Brand> _brands = [];
  late ProductSort _sort = widget.sort ?? ProductSort.newest;
  int? _brandId;
  int _page = 0;
  int _total = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    context.read<ProductService>().getBrands().then((b) {
      if (mounted) setState(() => _brands = b);
    }).catchError((_) {});
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reload() {
    _items.clear();
    _page = 0;
    _total = 0;
    _error = null;
    _loadMore(force: true);
  }

  Future<void> _loadMore({bool force = false}) async {
    if (_loading || (!force && _items.length >= _total)) return;
    setState(() => _loading = true);
    try {
      final page = await context.read<ProductService>().getProducts(
            categoryId: widget.categoryId,
            brandId: _brandId,
            search: widget.search,
            sort: _sort,
            page: _page + 1,
            size: _pageSize,
          );
      _page++;
      _items.addAll(page.items);
      _total = page.total;
    } catch (e) {
      _error = ApiClient.messageOf(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? (widget.search != null ? 'Kết quả: "${widget.search}"' : 'Sản phẩm');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          _filters(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          PopupMenuButton<ProductSort>(
            initialValue: _sort,
            onSelected: (s) {
              setState(() => _sort = s);
              _reload();
            },
            itemBuilder: (_) => [for (final s in ProductSort.values) PopupMenuItem(value: s, child: Text(s.label))],
            child: Chip(avatar: const Icon(Icons.sort, size: 18), label: Text(_sort.label)),
          ),
          const SizedBox(width: 8),
          for (final b in _brands) ...[
            FilterChip(
              label: Text(b.name),
              selected: _brandId == b.id,
              onSelected: (selected) {
                setState(() => _brandId = selected ? b.id : null);
                _reload();
              },
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty && _error != null) {
      return ErrorView(message: _error!, onRetry: () => setState(_reload));
    }
    if (_items.isEmpty) {
      return const EmptyView(icon: Icons.search_off, message: 'Không có sản phẩm phù hợp');
    }
    return RefreshIndicator(
      onRefresh: () async => setState(_reload),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.builder(
              gridDelegate: productGridDelegate,
              itemCount: _items.length,
              itemBuilder: (_, i) => ProductCard(product: _items[i]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text('Đã hiển thị ${_items.length}/$_total sản phẩm', style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
