import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/constants.dart';

class ProductImage extends StatelessWidget {
  const ProductImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImagePlaceholder();
    return CachedNetworkImage(
      // Ảnh lưu trên server dạng '/static/...': ghép với địa chỉ server hiện tại.
      imageUrl: url.startsWith('/') ? '${AppConstants.serverUrl}$url' : url,
      fit: fit,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFFEFF1F4)),
      errorWidget: (_, _, _) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFEFF1F4),
        child: Center(child: Icon(Icons.memory, size: 40, color: Colors.grey)),
      );
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

/// Hiển thị loading / lỗi + thử lại / dữ liệu cho một Future.
class FutureView<T> extends StatelessWidget {
  const FutureView({super.key, required this.future, required this.onRetry, required this.builder});

  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(message: ApiClient.messageOf(snapshot.error!), onRetry: onRetry);
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Hiển thị khi danh sách rỗng.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i ? Icons.star : (rating >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: Colors.amber,
          ),
      ],
    );
  }
}

/// Nút có trạng thái đang xử lý.
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.loading, required this.onPressed, required this.child});

  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          : child,
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
