import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartProvider>().reset();
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();
    final theme = Theme.of(context);

    Widget item(IconData icon, String title, String route) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(route),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              child: Text(user.fullName.characters.first.toUpperCase(), style: const TextStyle(fontSize: 22)),
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user.email}\n${user.phone ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/profile/edit')),
          ),
          if (user.isStaff) ...[
            _Header('Quản lý cửa hàng', color: theme.colorScheme.primary),
            item(Icons.insights, 'Báo cáo thống kê', '/admin/dashboard'),
            item(Icons.assignment_outlined, 'Xử lý đơn hàng', '/admin/orders'),
            item(Icons.forum_outlined, 'Hộp thư khách hàng', '/chat'),
          ] else ...[
            const _Header('Mua sắm'),
            item(Icons.receipt_long, 'Đơn hàng của tôi', '/orders'),
            item(Icons.bookmarks_outlined, 'Cấu hình PC đã lưu', '/builds'),
            item(Icons.chat_bubble_outline, 'Chat tư vấn', '/chat'),
          ],
          const _Header('Cài đặt'),
          item(Icons.location_on_outlined, 'Sổ địa chỉ', '/profile/addresses'),
          item(Icons.lock_outline, 'Đổi mật khẩu', '/profile/password'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('${AppConstants.appName} · ${AppConstants.tagline}',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.grey.shade700)),
      );
}
