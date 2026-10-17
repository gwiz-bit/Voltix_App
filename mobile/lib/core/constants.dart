class AppConstants {
  AppConstants._();

  static const String appName = 'Voltix';
  static const String tagline = 'Power Your Next Level.';

  /// Android emulator truy cập localhost của máy tính qua 10.0.2.2.
  /// Khi deploy backend, đổi sang URL server thật (https://...).
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /// Mốc 1 dùng dữ liệu mock để dựng UI; từ Mốc 3 đổi thành false để gọi API thật.
  static const bool useMock = true;
}
