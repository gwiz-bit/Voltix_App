import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFFEFF1F4)),
      errorWidget: (_, _, _) => const ColoredBox(
        color: Color(0xFFEFF1F4),
        child: Center(child: Icon(Icons.memory, size: 40, color: Colors.grey)),
      ),
    );
  }
}

/// Hiển thị lỗi kèm nút thử lại cho các màn hình tải dữ liệu.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

IconData categoryIcon(String slug) => switch (slug) {
      'cpu' => Icons.memory,
      'mainboard' => Icons.developer_board,
      'ram' => Icons.view_week,
      'vga' => Icons.videogame_asset,
      'ssd' => Icons.storage,
      'psu' => Icons.power,
      'case' => Icons.computer,
      'cooler' => Icons.ac_unit,
      _ => Icons.category,
    };

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.redAccent : null,
    ));
}
