import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    // Token hết hạn / bị thu hồi -> đưa người dùng về màn đăng nhập.
    ApiClient.onUnauthorized = () {
      if (status == AuthStatus.authenticated) logout();
    };
  }

  final AuthService _service;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool loading = false;

  /// Tự đăng nhập lại nếu còn token trong SharedPreferences.
  /// Mọi lỗi (mất mạng, token hỏng, lỗi bộ nhớ) đều đưa về màn đăng nhập thay vì kẹt ở Splash.
  Future<void> init() async {
    try {
      if (await AppStorage.getToken() != null) {
        user = await _service.me();
        status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    } catch (_) {
      try {
        await AppStorage.clearToken();
      } catch (_) {}
    }
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> login(String email, String password) =>
      _authenticate(() => _service.login(email.trim(), password));

  Future<String?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      _authenticate(() => _service.register(
            fullName: fullName.trim(),
            email: email.trim(),
            phone: phone.trim(),
            password: password,
          ));

  Future<String?> updateProfile(String fullName, String phone) async {
    try {
      user = await _service.updateProfile(fullName: fullName.trim(), phone: phone.trim());
      notifyListeners();
      return null;
    } catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      await _service.changePassword(oldPassword, newPassword);
      return null;
    } catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  Future<void> logout() async {
    await AppStorage.clearToken();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> _authenticate(Future<AuthResult> Function() action) async {
    loading = true;
    notifyListeners();
    try {
      final result = await action();
      await AppStorage.saveToken(result.token);
      user = result.user;
      status = AuthStatus.authenticated;
      return null;
    } catch (e) {
      return ApiClient.messageOf(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
