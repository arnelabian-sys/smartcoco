import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/app_shell.dart';
import '../widgets/status_chip.dart';

class AdminStatusScreen extends StatefulWidget {
  const AdminStatusScreen({super.key});

  @override
  State<AdminStatusScreen> createState() => _AdminStatusScreenState();
}

class _AdminStatusScreenState extends State<AdminStatusScreen> {
  bool _loading = false;
  String _api = 'Unknown';
  String _model = 'Unknown';
  String _lastChecked = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final h = await DataStore.instance.health();
      if (mounted) {
        setState(() {
          _api = h['api'] as String;
          _model = h['model'] as String;
          _lastChecked = (h['lastChecked'] as DateTime).toLocal().toString();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _api = 'Down';
          _model = 'Down';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiOk = _api == 'OK';
    final modelOk = _model == 'OK';
    return AppShell(
      currentRoute: '/admin/status',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Admin Status', style: Theme.of(context).textTheme.headlineLarge)),
                AppButton(label: 'Refresh', icon: Icons.refresh, loading: _loading, onPressed: _refresh),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud, size: 40, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text('API'),
                        const SizedBox(height: 8),
                        StatusChip(label: apiOk ? 'OK' : 'Down', color: apiOk ? AppColors.primary : AppColors.error, icon: apiOk ? Icons.check_circle : Icons.cancel),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.memory, size: 40, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text('CNN model'),
                        const SizedBox(height: 8),
                        StatusChip(label: modelOk ? 'OK' : 'Down', color: modelOk ? AppColors.primary : AppColors.error, icon: modelOk ? Icons.check_circle : Icons.cancel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lastChecked.isNotEmpty) Text('Last checked: $_lastChecked', style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
            if (!apiOk) ...[
              const SizedBox(height: 16),
              const FeedbackBanner(type: FeedbackType.error, message: 'API unreachable'),
            ],
          ],
        ),
      ),
    );
  }
}


