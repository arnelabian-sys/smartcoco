import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String id;
  const HistoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.user.value!;
    final pred = DataStore.instance.findPrediction(id);
    if (pred == null) {
      return AppShell(
        currentRoute: '/history/$id',
        child: _centerMessage(context, 'Record not found', 'Back to history', '/history'),
      );
    }
    if (pred.userId != user.id && !user.isAdmin) {
      return AppShell(
        currentRoute: '/history/$id',
        child: _centerMessage(context, "You can't view this record", 'Back to history', '/history'),
      );
    }
    return AppShell(
      currentRoute: '/history/$id',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Classification detail', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 16),
                Container(
                  height: 260,
                  decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Icon(Icons.image, size: 64, color: AppColors.grey400)),
                ),
                const SizedBox(height: 16),
                Text(pred.variety ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Confidence: ${((pred.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 4),
                Text('Created: ${pred.createdAt}'),
                const SizedBox(height: 24),
                AppButton(label: 'Back', variant: AppButtonVariant.outlined, onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _centerMessage(BuildContext context, String msg, String btn, String route) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 8),
          Text(msg),
          const SizedBox(height: 12),
          AppButton(label: btn, onPressed: () => Navigator.pushReplacementNamed(context, route)),
        ],
      ),
    );
  }
}

