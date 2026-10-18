import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/api_client.dart';
import '../../services/shop_service.dart';
import '../../widgets/common.dart';

/// Tạo URL thanh toán cho đơn [orderId] rồi mở WebView VNPay.
/// Trả về true nếu VNPay báo thanh toán thành công.
Future<bool> payWithVnpay(BuildContext context, int orderId) async {
  try {
    final url = await context.read<ShopService>().createVnpayUrl(orderId);
    if (!context.mounted) return false;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VnpayScreen(paymentUrl: url)),
    );
    if (context.mounted) {
      showMessage(
        context,
        paid == true ? 'Thanh toán thành công!' : 'Chưa thanh toán. Bạn có thể thanh toán lại trong chi tiết đơn hàng.',
        error: paid != true,
      );
    }
    return paid == true;
  } catch (e) {
    if (context.mounted) showMessage(context, ApiClient.messageOf(e), error: true);
    return false;
  }
}

class VnpayScreen extends StatefulWidget {
  const VnpayScreen({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<VnpayScreen> createState() => _VnpayScreenState();
}

class _VnpayScreenState extends State<VnpayScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        // VNPay chuyển về /api/payments/vnpay/return: server đã cập nhật đơn, app đọc mã kết quả rồi đóng.
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.path.endsWith('/payments/vnpay/return')) {
            _finish(uri.queryParameters['vnp_ResponseCode'] == '00', loadUrl: request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _finish(bool success, {required String loadUrl}) async {
    if (_done) return;
    _done = true;
    // Gọi return URL để server xác minh chữ ký và cập nhật trạng thái đơn trước khi đóng.
    try {
      await ApiClient.dio.getUri(Uri.parse(loadUrl));
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, minHeight: 2),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
