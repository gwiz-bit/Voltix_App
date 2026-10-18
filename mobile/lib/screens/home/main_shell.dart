import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';

/// Khung chứa bottom navigation (Trang chủ / Build PC / Giỏ hàng / Tài khoản).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Shell chỉ hiển thị khi đã đăng nhập -> tải giỏ hàng từ server.
    context.read<CartProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final cartCount = context.select<CartProvider, int>((c) => c.count);
    Widget cartIcon(IconData icon) =>
        Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: Icon(icon));
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          const NavigationDestination(
              icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: 'Build PC'),
          NavigationDestination(
            icon: cartIcon(Icons.shopping_cart_outlined),
            selectedIcon: cartIcon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
