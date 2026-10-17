class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // customer | staff | admin

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'customer',
  });

  bool get isStaff => role == 'staff' || role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'customer',
      );
}
