import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.search, this.title});

  final int? categoryId;
  final String? search;
  final String? title;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() =>
      context.read<ProductService>().getProducts(categoryId: widget.categoryId, search: widget.search);

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? (widget.search != null ? 'Kết quả: "${widget.search}"' : 'Sản phẩm');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: ApiClient.messageOf(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('Không có sản phẩm phù hợp'));
          }
          return ProductGrid(products: products);
        },
      ),
    );
  }
}
