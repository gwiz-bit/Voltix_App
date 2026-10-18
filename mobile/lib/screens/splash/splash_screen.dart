import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Hiển thị trong lúc AuthProvider kiểm tra token; router tự chuyển màn khi xong.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Image.asset('assets/branding/logo_full.png', width: 360),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
