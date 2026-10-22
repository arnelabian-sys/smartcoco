import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.grey400),
            const SizedBox(height: 12),
            const Text('404 — Page not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            AppButton(label: 'Go to home', onPressed: () => Navigator.pushReplacementNamed(context, '/')),
          ],
        ),
      ),
    );
  }
}

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('403 — You can\'t access this page', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            AppButton(label: 'Go to home', onPressed: () => Navigator.pushReplacementNamed(context, '/home')),
          ],
        ),
      ),
    );
  }
}
