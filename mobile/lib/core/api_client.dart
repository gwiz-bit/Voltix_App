import 'package:dio/dio.dart';

import 'constants.dart';
import 'storage.dart';

/// Dio dùng chung: tự gắn JWT vào header và báo khi token hết hạn (401).
class ApiClient {
  ApiClient._();

  /// AuthProvider gán callback này để tự đăng xuất khi server trả 401.
  static void Function()? onUnauthorized;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final isLogin = error.requestOptions.path.startsWith('/auth/login');
          if (error.response?.statusCode == 401 && !isLogin) onUnauthorized?.call();
          handler.next(error);
        },
      ),
    );

  /// Chuyển lỗi (DioException hoặc lỗi khác) thành câu thông báo cho người dùng.
  static String messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) return detail;
        // Lỗi validate của FastAPI: [{"loc": [...], "msg": "..."}]
        if (detail is List && detail.isNotEmpty && detail.first is Map) {
          return 'Dữ liệu không hợp lệ: ${(detail.first as Map)['msg']}';
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối máy chủ quá thời gian, vui lòng thử lại.';
        case DioExceptionType.connectionError:
          return 'Không thể kết nối máy chủ. Kiểm tra mạng của bạn.';
        default:
          final status = error.response?.statusCode;
          // Lỗi không có phản hồi từ server (vd. lỗi trong interceptor) -> hiện nguyên nhân gốc.
          if (status != null) return 'Đã có lỗi xảy ra ($status).';
          final detail = '${error.error ?? error.message}'.split('\n').first;
          return 'Đã có lỗi xảy ra: ${detail.length > 160 ? '${detail.substring(0, 160)}…' : detail}';
      }
    }
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
