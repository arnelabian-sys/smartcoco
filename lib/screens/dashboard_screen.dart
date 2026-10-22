import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_controller.dart';
import '../services/data_store.dart';
import '../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Soft dark halo behind all dashboard text so it stays readable
  /// over the background image.
  static const List<Shadow> _shadows = [
    Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2)),
    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
  ];

  List<Prediction>? _recent;
  int _varietyCount = 0;
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
      final results = await Future.wait([
        DataStore.instance.fetchHistory(),
        DataStore.instance.fetchVarieties(),
      ]);
      final history = results[0] as List<Prediction>;
      final varieties = results[1] as List<Variety>;
      if (!mounted) return;
      setState(() {
        _recent = history;
        _varietyCount = varieties.where((v) => v.active).length;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load dashboard data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/dashboard',
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.black54],
            ),
          ),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = AuthController.instance.user.value;
    final history = _recent ?? const <Prediction>[];
    final total = history.length;
    final avgConfidence = history.isEmpty
        ? 0.0
        : history.map((p) => p.confidence ?? 0).reduce((a, b) => a + b) / history.length;
    final lastScan = history.isEmpty ? null : history.first.createdAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null ? 'Dashboard' : 'Welcome back, ${user.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            shadows: _shadows,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user == null ? '' : '${user.roleLabel}  •  ${_fmtLong(DateTime.now())}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, shadows: _shadows),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                _glassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white))),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statCard(
                    label: 'Classifications',
                    value: _loading ? '—' : '$total',
                    icon: Icons.photo_camera_outlined,
                  ),
                  _statCard(
                    label: 'Active Varieties',
                    value: _loading ? '—' : '$_varietyCount',
                    icon: Icons.eco_outlined,
                  ),
                  _statCard(
                    label: 'Avg. Confidence',
                    value: _loading || total == 0 ? '—' : '${(avgConfidence * 100).toStringAsFixed(1)}%',
                    icon: Icons.verified_outlined,
                  ),
                  _statCard(
                    label: 'Last Scan',
                    value: lastScan == null ? '—' : _fmtShort(lastScan),
                    icon: Icons.schedule,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick actions',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, shadows: _shadows),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _quickActions(user),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent classifications',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, shadows: _shadows),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/history'),
                    child: const Text('View all', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (history.isEmpty)
                _glassCard(
                  child: Row(
                    children: const [
                      Icon(Icons.inbox_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Wala pa kay classification. Sugdi pinaagi sa Classify.',
                          style: TextStyle(color: Colors.white, shadows: _shadows),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...history.take(5).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _glassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            child: const Icon(Icons.image, color: Colors.white),
                          ),
                          title: Text(
                            p.variety ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, shadows: _shadows),
                          ),
                          subtitle: Text(
                            'Confidence: ${(((p.confidence ?? 0)) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, shadows: _shadows),
                          ),
                          trailing: Text(_fmtShort(p.createdAt), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, shadows: _shadows)),
                          onTap: () => Navigator.pushNamed(context, '/history/${p.id}'),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _quickActions(AppUser? user) {
    final actions = <_QuickAction>[
      _QuickAction('Classify', Icons.cloud_upload, '/classify'),
      _QuickAction('History', Icons.history, '/history'),
      _QuickAction('Varieties', Icons.eco, '/varieties'),
    ];
    if (user?.isResearcher == true) {
      actions.add(_QuickAction('Statistics', Icons.bar_chart, '/stats'));
    }
    if (user?.isAdmin == true) {
      actions.add(_QuickAction('Admin Varieties', Icons.admin_panel_settings, '/admin/varieties'));
      actions.add(_QuickAction('System Status', Icons.monitor_heart, '/admin/status'));
    }
    actions.add(_QuickAction('Settings', Icons.settings, '/settings'));
    return actions
        .map((a) => _glassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushReplacementNamed(context, a.route),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(a.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, shadows: _shadows)),
                  ],
                ),
              ),
            ))
        .toList();
  }

  Widget _statCard({required String label, required String value, required IconData icon}) {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        width: 210,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, shadows: _shadows),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: _shadows), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  String _fmtShort(DateTime d) => '${d.month}/${d.day}/${d.year}';

  String _fmtLong(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  _QuickAction(this.label, this.icon, this.route);
}
