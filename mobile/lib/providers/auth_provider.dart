import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool loading = false;

  /// Tự đăng nhập lại nếu còn token trong SharedPreferences.
  Future<void> init() async {
    final token = await AppStorage.getToken();
    if (token != null) {
      try {
        user = await _service.me(token);
        status = AuthStatus.authenticated;
        notifyListeners();
        return;
      } catch (_) {
        await AppStorage.clearToken();
      }
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
