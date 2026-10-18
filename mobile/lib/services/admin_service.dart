import '../core/api_client.dart';
import '../models/order.dart';

/// API dành cho nhân viên/quản lý: thống kê và xử lý đơn hàng.
class AdminService {
  final _dio = ApiClient.dio;

  Future<Map<String, dynamic>> summary() async =>
      (await _dio.get('/admin/stats/summary')).data as Map<String, dynamic>;

  /// [{date: '2026-10-01', revenue: 123}]
  Future<List<Map<String, dynamic>>> revenueByDay({int days = 30}) async =>
      _list(await _dio.get('/admin/stats/revenue', queryParameters: {'group': 'day', 'days': days}));

  /// [{status: 'pending', count: 3}]
  Future<List<Map<String, dynamic>>> ordersByStatus() async => _list(await _dio.get('/admin/stats/orders-by-status'));

  /// [{name, sold, revenue}]
  Future<List<Map<String, dynamic>>> topProducts({int limit = 5}) async =>
      _list(await _dio.get('/admin/stats/top-products', queryParameters: {'limit': limit}));

  Future<List<Order>> orders({OrderStatus? status}) async {
    final res = await _dio.get('/admin/orders', queryParameters: {'status_filter': ?status?.name});
    return (res.data as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> updateStatus(int orderId, OrderStatus status) async {
    final res = await _dio.put('/admin/orders/$orderId/status', data: {'status': status.name});
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  List<Map<String, dynamic>> _list(dynamic res) => ((res.data as List).cast<Map<String, dynamic>>());
}

/// Trạng thái kế tiếp hợp lệ (khớp TRANSITIONS ở backend).
const orderTransitions = <OrderStatus, List<OrderStatus>>{
  OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.paid, OrderStatus.cancelled],
  OrderStatus.paid: [OrderStatus.confirmed, OrderStatus.cancelled],
  OrderStatus.confirmed: [OrderStatus.shipping, OrderStatus.cancelled],
  OrderStatus.shipping: [OrderStatus.completed],
  OrderStatus.completed: [],
  OrderStatus.cancelled: [],
};
