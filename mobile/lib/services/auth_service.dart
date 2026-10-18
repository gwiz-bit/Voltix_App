import '../core/api_client.dart';
import '../models/user.dart';

typedef AuthResult = ({String token, User user});

class AuthService {
  final _dio = ApiClient.dio;

  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return _parse(res.data as Map<String, dynamic>);
  }

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

  Future<User> me() async {
    final res = await _dio.get('/auth/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<User> updateProfile({required String fullName, required String phone}) async {
    final res = await _dio.put('/auth/me', data: {'full_name': fullName, 'phone': phone});
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String oldPassword, String newPassword) =>
      _dio.post('/auth/change-password', data: {'old_password': oldPassword, 'new_password': newPassword});

  AuthResult _parse(Map<String, dynamic> data) => (
        token: data['access_token'] as String,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
      );
}
