import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback_banner.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DataStore.instance.fetchHistory(filter: _filter);
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load history.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;
    final isTablet = width >= 600 && width < 1024;
    return AppShell(
      currentRoute: '/history',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: ['All', 'Tall', 'Dwarf', 'Hybrid'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filter = v);
                    _load();
                  },
                ),
                const Spacer(),
                if (isWide)
                  Text('${_items.length} records', style: const TextStyle(color: AppColors.grey600)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? FeedbackBanner(type: FeedbackType.error, message: _error!, onRetry: _load)
                      : _items.isEmpty
                          ? EmptyState(
                              title: 'No classifications yet.',
                              subtitle: 'Classify your first coconut to see it here.',
                              icon: Icons.history,
                              action: AppButton(label: 'Classify a coconut', onPressed: () => Navigator.pushNamed(context, '/classify')),
                            )
                          : isWide
                              ? _table()
                              : isTablet
                                  ? _grid(2)
                                  : _list(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) => _cardTile(_items[i], ctx),
    );
  }

  Widget _grid(int cols) {
    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _items.map((p) => _card(p)).toList(),
    );
  }

  Widget _cardTile(dynamic p, BuildContext ctx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.image, color: AppColors.primary),
        title: Text(p.variety ?? 'Unknown'),
        subtitle: Text('Confidence ${((p.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
        trailing: Text('${p.createdAt.month}/${p.createdAt.day}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
        onTap: () => Navigator.pushNamed(ctx, '/history/${p.id}'),
      ),
    );
  }

  Widget _card(dynamic p) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/history/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.image, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(p.variety ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${((p.confidence ?? 0) * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _table() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Image')),
            DataColumn(label: Text('Variety')),
            DataColumn(label: Text('Confidence')),
            DataColumn(label: Text('Date')),
          ],
          rows: _items.map((p) => DataRow(
                cells: [
                  const DataCell(Icon(Icons.image, color: AppColors.primary)),
                  DataCell(Text(p.variety ?? 'Unknown')),
                  DataCell(Text('${((p.confidence ?? 0) * 100).toStringAsFixed(1)}%')),
                  DataCell(Text('${p.createdAt.month}/${p.createdAt.day}/${p.createdAt.year}')),
                ],
                onSelectChanged: (_) => Navigator.pushNamed(context, '/history/${p.id}'),
              )).toList(),
        ),
      ),
    );
  }
}

