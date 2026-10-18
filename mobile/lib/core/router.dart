import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_screens.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/builder/builder_screen.dart';
import '../screens/builder/builds_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/chat/chat_screens.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/order/order_detail_screen.dart';
import '../screens/order/orders_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/product_list_screen.dart';
import '../screens/profile/account_screens.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../services/product_service.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    // Mỗi khi trạng thái đăng nhập đổi, router chạy lại redirect.
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';
      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : '/login';
        case AuthStatus.authenticated:
          if (onAuthPage || loc == '/splash') return '/home';
          // Màn quản trị chỉ dành cho nhân viên.
          if (loc.startsWith('/admin') && !(auth.user?.isStaff ?? false)) return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/builder', builder: (_, _) => const BuilderScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, _) => const CartScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: '/products',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return ProductListScreen(
            categoryId: int.tryParse(q['category'] ?? ''),
            search: q['q'],
            title: q['title'],
            sort: q['sort'] == 'best_selling' ? ProductSort.bestSelling : null,
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ProductDetailScreen(productId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: '/orders',
        builder: (_, _) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(path: '/builds', builder: (_, _) => const BuildsScreen()),
      GoRoute(
        path: '/chat',
        builder: (_, _) => const ChatEntryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ChatRoomScreen(
              conversationId: int.parse(state.pathParameters['id']!),
              title: state.uri.queryParameters['name'] ?? 'Chat',
            ),
          ),
        ],
      ),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile/password', builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: '/profile/addresses', builder: (_, _) => const AddressesScreen()),
      GoRoute(path: '/admin/dashboard', builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/orders', builder: (_, _) => const AdminOrdersScreen()),
    ],
  );
}
