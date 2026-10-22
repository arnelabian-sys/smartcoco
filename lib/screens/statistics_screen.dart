import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback_banner.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  Map<String, int>? _data;
  bool _loading = true;
  String? _error;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_from.isAfter(_to)) {
      setState(() => _rangeError = 'Start date must be before end date.');
      return;
    }
    if (_to.isAfter(DateTime.now())) {
      setState(() => _rangeError = 'Date range cannot be in the future.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rangeError = null;
    });
    try {
      final m = DataStore.instance.stats(_from, _to);
      if (mounted) setState(() => _data = m);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('403') ? 'This page is for verified Extension Workers/Researchers.' : "Couldn't load statistics.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (_data?.values.fold<int>(0, (a, b) => a + b) ?? 0);
    final maxVal = (_data?.values.fold<int>(0, (a, b) => a > b ? a : b) ?? 0).clamp(1, 1 << 30);
    return AppShell(
      currentRoute: '/stats',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                AppButton(label: 'Select date range', variant: AppButtonVariant.outlined, icon: Icons.date_range, onPressed: _pickRange),
                const SizedBox(width: 12),
                Text('${_from.month}/${_from.day}/${_from.year} – ${_to.month}/${_to.day}/${_to.year}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (_rangeError != null) ...[
              const SizedBox(height: 8),
              Text(_rangeError!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? FeedbackBanner(type: FeedbackType.error, message: _error!, onRetry: _load)
                      : (_data == null || total == 0)
                          ? EmptyState(title: 'No classifications in this date range.', icon: Icons.bar_chart, action: AppButton(label: 'Change dates', onPressed: _pickRange))
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Counts per variety', style: TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: _data!.entries.map((e) {
                                                final h = (e.value / maxVal) * 160;
                                                return Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Text('${e.value}', style: const TextStyle(fontSize: 12)),
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          height: h.clamp(4, 160),
                                                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(e.key, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          ..._data!.entries.map((e) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [Text(e.key), Text('${e.value}')],
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

