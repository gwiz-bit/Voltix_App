class AppConstants {
  AppConstants._();

  static const String appName = 'Voltix';
  static const String tagline = 'Power Your Next Level.';

  /// Địa chỉ backend. Android emulator truy cập localhost của máy tính qua 10.0.2.2.
  /// Có thể đổi khi build mà không sửa code:
  ///   flutter run --dart-define=SERVER_URL=http://192.168.1.10:8000
  static const String serverUrl = String.fromEnvironment('SERVER_URL', defaultValue: 'http://10.0.2.2:8000');

  static const String baseUrl = '$serverUrl/api';

  static String get wsUrl => serverUrl.replaceFirst('http', 'ws');
}
