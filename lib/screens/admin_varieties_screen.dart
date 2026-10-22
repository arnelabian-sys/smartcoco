import 'package:flutter/material.dart';
import '../services/data_store.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/status_chip.dart';

class AdminVarietiesScreen extends StatefulWidget {
  const AdminVarietiesScreen({super.key});

  @override
  State<AdminVarietiesScreen> createState() => _AdminVarietiesScreenState();
}

class _AdminVarietiesScreenState extends State<AdminVarietiesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

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
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load varieties.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({dynamic existing}) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final descCtl = TextEditingController(text: existing?.description ?? '');
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          title: Text(existing == null ? 'Add variety' : 'Edit variety'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Name', controller: nameCtl, validator: (_) => null),
                const SizedBox(height: 12),
                AppTextField(label: 'Description', controller: descCtl, maxLines: 3),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            AppButton(
              label: _saving ? 'Saving…' : 'Save',
              loading: _saving,
              onPressed: () async {
                final name = nameCtl.text.trim();
                final desc = descCtl.text.trim();
                if (name.isEmpty) {
                  setD(() => err = 'Name is required.');
                  return;
                }
                if (desc.length > 500) {
                  setD(() => err = 'Description too long.');
                  return;
                }
                setState(() => _saving = true);
                try {
                  if (existing == null) {
                    await DataStore.instance.addVariety(name, desc);
                  } else {
                    await DataStore.instance.updateVariety(existing.id, name: name, description: desc);
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variety saved')));
                  }
                  _load();
                } catch (e) {
                  setD(() => err = e.toString().contains('duplicate_variety') ? 'This variety already exists.' : 'Could not save.');
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
            ),
          ],
        );
      }),
    );
  }

  Future<void> _deactivate(dynamic v) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deactivate variety?',
      message: 'Deactivate "${v.name}"? It will no longer appear to users.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (!ok) return;
    try {
      await DataStore.instance.updateVariety(v.id, active: false);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variety deactivated')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not deactivate.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/admin/varieties',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Admin Varieties', style: Theme.of(context).textTheme.headlineLarge)),
                AppButton(label: 'Add variety', icon: Icons.add, onPressed: () => _openForm()),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? FeedbackBanner(type: FeedbackType.error, message: _error!, onRetry: _load)
                      : _items.isEmpty
                          ? Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('No varieties yet.'),
                                const SizedBox(height: 8),
                                AppButton(label: 'Add variety', onPressed: () => _openForm()),
                              ],
                            ))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _items.map((v) => DataRow(cells: [
                                      DataCell(Text(v.name)),
                                      DataCell(SizedBox(width: 260, child: Text(v.description, overflow: TextOverflow.ellipsis))),
                                      DataCell(StatusChip(label: v.active ? 'Active' : 'Inactive', color: v.active ? AppColors.primary : AppColors.grey600, icon: v.active ? Icons.check_circle : Icons.block)),
                                      DataCell(Row(
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(existing: v)),
                                          IconButton(icon: const Icon(Icons.block), onPressed: v.active ? () => _deactivate(v) : null),
                                        ],
                                      )),
                                    ])).toList(),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

