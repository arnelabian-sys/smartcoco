import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/status_chip.dart';

class ResultScreen extends StatelessWidget {
  final String id;
  const ResultScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final pred = DataStore.instance.findPrediction(id);
    if (pred == null) {
      return AppShell(
        currentRoute: '/classify/result/$id',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 8),
              const Text('Record not found'),
              const SizedBox(height: 12),
              AppButton(label: 'Back to history', onPressed: () => Navigator.pushReplacementNamed(context, '/history')),
            ],
          ),
        ),
      );
    }
    final conf = (pred.confidence ?? 0.0).clamp(0.0, 1.0);
    return AppShell(
      currentRoute: '/classify/result/$id',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, c) {
                final sideBySide = c.maxWidth >= 768;
                final photo = Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.image, size: 64, color: AppColors.grey400)),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 12),
                    Text(pred.variety ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    StatusChip(label: '${(conf * 100).toStringAsFixed(1)}% confidence', color: AppColors.primary, icon: Icons.verified),
                    const SizedBox(height: 12),
                    Text('Confidence', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: conf, minHeight: 8, color: AppColors.primary, backgroundColor: AppColors.grey200),
                    const SizedBox(height: 4),
                    Text('${(conf * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppButton(label: 'Classify another', icon: Icons.refresh, onPressed: () => Navigator.pushReplacementNamed(context, '/classify')),
                        AppButton(label: 'View in history', variant: AppButtonVariant.outlined, icon: Icons.history, onPressed: () => Navigator.pushNamed(context, '/history/${pred.id}')),
                      ],
                    ),
                  ],
                );
                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: photo),
                      const SizedBox(width: 24),
                      Expanded(child: details),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [photo, const SizedBox(height: 24), details],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

