import 'package:dio/dio.dart';

import 'constants.dart';
import 'storage.dart';

/// Dio dùng chung: tự gắn JWT vào header của mọi request.
class ApiClient {
  ApiClient._();

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
      ),
    );

  /// Chuyển lỗi (DioException hoặc lỗi khác) thành câu thông báo cho người dùng.
  static String messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) return data['detail'] as String;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối máy chủ quá thời gian, vui lòng thử lại.';
        case DioExceptionType.connectionError:
          return 'Không thể kết nối máy chủ. Kiểm tra mạng của bạn.';
        default:
          return 'Đã có lỗi xảy ra (${error.response?.statusCode ?? 'không rõ'}).';
      }
    }
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
