import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Hiển thị trong lúc AuthProvider kiểm tra token; router tự chuyển màn khi xong.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, size: 80, color: color),
            const SizedBox(height: 12),
            Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(AppConstants.tagline, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
