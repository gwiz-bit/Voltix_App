import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService = AppConstants.useMock ? MockAuthService() : ApiAuthService();
  final ProductService productService = AppConstants.useMock ? MockProductService() : ApiProductService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ProductService>.value(value: productService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
