import '../core/api_client.dart';
import '../models/user.dart';

typedef AuthResult = ({String token, User user});

abstract class AuthService {
  Future<AuthResult> login(String email, String password);

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// Lấy thông tin user hiện tại từ token đã lưu.
  Future<User> me(String token);
}

/// Gọi backend FastAPI (dùng từ Mốc 3).
class ApiAuthService implements AuthService {
  final _dio = ApiClient.dio;

  @override
  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return _parse(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return _parse(res.data as Map<String, dynamic>);
  }

  @override
  Future<User> me(String token) async {
    final res = await _dio.get('/auth/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  AuthResult _parse(Map<String, dynamic> data) => (
        token: data['access_token'] as String,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
      );
}

/// Dữ liệu giả để dựng UI ở Mốc 1. Tài khoản demo: customer@voltix.vn / 123456
class MockAuthService implements AuthService {
  final Map<String, ({User user, String password})> _accounts = {
    'customer@voltix.vn': (
      user: const User(id: 1, fullName: 'Nguyễn Văn A', email: 'customer@voltix.vn', phone: '0901234567'),
      password: '123456',
    ),
  };

  @override
  Future<AuthResult> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
    return (token: 'mock-token:${account.user.email}', user: account.user);
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw Exception('Email đã được sử dụng');
    final user = User(id: _accounts.length + 1, fullName: fullName, email: key, phone: phone);
    _accounts[key] = (user: user, password: password);
    return (token: 'mock-token:$key', user: user);
  }

  @override
  Future<User> me(String token) async {
    final account = _accounts[token.replaceFirst('mock-token:', '')];
    if (account == null) throw Exception('Phiên đăng nhập hết hạn');
    return account.user;
  }
}
