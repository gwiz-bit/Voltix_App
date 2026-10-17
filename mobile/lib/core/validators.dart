class Validators {
  Validators._();

  static String? required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $field' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim());
    return ok ? null : 'Email không hợp lệ';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    return v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    return RegExp(r'^0\d{9}$').hasMatch(v.trim()) ? null : 'Số điện thoại gồm 10 số, bắt đầu bằng 0';
  }
}
