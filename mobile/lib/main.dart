import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/product_service.dart';
import 'services/shop_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khoá màn hình dọc: giao diện chỉ thiết kế cho chiều dọc.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final shopService = ShopService();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ProductService()),
        Provider.value(value: shopService),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())..init()),
        ChangeNotifierProvider(create: (_) => CartProvider(shopService)),
      ],
      child: const VoltixApp(),
    ),
  );
}

class VoltixApp extends StatefulWidget {
  const VoltixApp({super.key});

  @override
  State<VoltixApp> createState() => _VoltixAppState();
}

class _VoltixAppState extends State<VoltixApp> {
  // Tạo router một lần để không mất lịch sử điều hướng khi rebuild.
  late final GoRouter _router = createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
