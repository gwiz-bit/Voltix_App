import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      context.read<CartProvider>().clear();
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              child: Text(user?.fullName.characters.first.toUpperCase() ?? '?', style: const TextStyle(fontSize: 22)),
            ),
            title: Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user?.email ?? ''}\n${user?.phone ?? ''}'),
            isThreeLine: true,
          ),
          const Divider(),
          // Các mục dưới đây sẽ được nối vào màn hình thật ở Mốc 3.
          const ListTile(leading: Icon(Icons.receipt_long), title: Text('Đơn hàng của tôi'), trailing: Icon(Icons.chevron_right)),
          const ListTile(leading: Icon(Icons.build_circle_outlined), title: Text('PC Builder'), trailing: Icon(Icons.chevron_right)),
          const ListTile(leading: Icon(Icons.chat_bubble_outline), title: Text('Chat tư vấn'), trailing: Icon(Icons.chevron_right)),
          const ListTile(leading: Icon(Icons.location_on_outlined), title: Text('Sổ địa chỉ'), trailing: Icon(Icons.chevron_right)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
