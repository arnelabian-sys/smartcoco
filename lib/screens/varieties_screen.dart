import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/feedback_banner.dart';

class VarietiesScreen extends StatefulWidget {
  const VarietiesScreen({super.key});

  @override
  State<VarietiesScreen> createState() => _VarietiesScreenState();
}

class _VarietiesScreenState extends State<VarietiesScreen> {
  final _searchCtl = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final list = await DataStore.instance.fetchVarieties();
      if (mounted) setState(() => _items = list.where((v) => v.active).toList());
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load varieties.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1024 ? 4 : (width >= 600 ? 2 : 1);
    final filtered = _items.where((v) {
      if (_query.isEmpty) return true;
      return v.name.toLowerCase().contains(_query.toLowerCase()) ||
          v.description.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return AppShell(
      currentRoute: '/varieties',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Varieties', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search varieties',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? FeedbackBanner(type: FeedbackType.error, message: _error!, onRetry: _load)
                      : filtered.isEmpty
                          ? const EmptyState(title: 'No varieties available.', icon: Icons.eco)
                          : GridView.count(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                              children: filtered.map((v) => Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            const Icon(Icons.eco, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                          ]),
                                          const SizedBox(height: 8),
                                          Text(
                                            v.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )).toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

