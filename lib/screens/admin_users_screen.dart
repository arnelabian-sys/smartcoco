import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

/// Administrator → User Management.
///
/// Lists every account known to the backend together with the activity the API
/// tracks: role, registration date, last login, number of logins and whether a
/// session is open right now.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';
  String _role = 'all';

  List<UserAccount> _accounts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await AuthController.instance.fetchAccounts();
      if (!mounted) return;
      setState(() => _accounts = accounts);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't load the accounts.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserAccount> get _filtered {
    final q = _query.trim().toLowerCase();
    return _accounts.where((a) {
      final matchesRole = _role == 'all' || a.user.role == _role;
      final matchesQuery =
          q.isEmpty ||
          a.user.name.toLowerCase().contains(q) ||
          a.user.email.toLowerCase().contains(q);
      return matchesRole && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filtered;

    return AppShell(
      currentRoute: '/admin/users',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _stats(),
            const SizedBox(height: 16),
            _filters(),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(
                  '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey600,
                  ),
                ),
                if (_role != 'all' || _query.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _role = 'all';
                      _query = '';
                      _searchCtl.clear();
                    }),
                    child: const Text('Clear filters'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : accounts.isEmpty
                  ? const EmptyState(
                      title: 'No matching accounts.',
                      subtitle: 'Try a different name, e-mail or role filter.',
                      icon: Icons.people_outline,
                    )
                  : ListView.separated(
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _accountCard(accounts[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _header() {
    return LayoutBuilder(
      builder: (context, c) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Every registered account, its role and its sign-in activity.',
              style: TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
          ],
        );
        final actions = AppButton(
          label: 'Refresh',
          icon: Icons.refresh,
          variant: AppButtonVariant.outlined,
          onPressed: _loading ? null : _load,
        );

        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Stat tiles
  // ---------------------------------------------------------------------------
  Widget _stats() {
    final admins = _accounts.where((a) => a.user.role == 'admin').length;
    final researchers = _accounts
        .where((a) => a.user.role == 'researcher')
        .length;
    final online = _accounts.where((a) => a.online).length;
    final logins = _accounts.fold<int>(0, (sum, a) => sum + a.loginCount);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statTile(
          'Total Accounts',
          '${_accounts.length}',
          Icons.people_outline,
        ),
        _statTile(
          'Online Now',
          '$online',
          Icons.wifi_tethering,
          highlight: true,
        ),
        _statTile('Total Logins', '$logins', Icons.login),
        _statTile(
          'Admins · Researchers',
          '$admins · $researchers',
          Icons.admin_panel_settings_outlined,
        ),
      ],
    );
  }

  Widget _statTile(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.grey400.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search + role filter
  // ---------------------------------------------------------------------------
  Widget _filters() {
    const roles = <String, String>{
      'all': 'All',
      'admin': 'Admin',
      'researcher': 'Researcher',
      'farmer': 'Farmer',
      'agriculturist': 'Agriculturist',
      'student': 'Student',
      'user': 'Registered',
    };

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search name or e-mail',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        ...roles.entries.map(
          (e) => ChoiceChip(
            label: Text(e.value),
            selected: _role == e.key,
            onSelected: (_) => setState(() => _role = e.key),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _role == e.key ? AppColors.primary : AppColors.grey800,
            ),
            side: BorderSide(
              color: _role == e.key
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.grey400.withValues(alpha: 0.6),
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Account row
  // ---------------------------------------------------------------------------
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF1B5E20);
      case 'researcher':
        return const Color(0xFF00695C);
      case 'farmer':
        return const Color(0xFFEF6C00);
      case 'agriculturist':
        return const Color(0xFF2E7D32);
      case 'student':
        return const Color(0xFF1565C0);
      default:
        return AppColors.grey600;
    }
  }

  Widget _accountCard(UserAccount a) {
    final roleColor = _roleColor(a.user.role);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxWidth < 620;

            final identity = Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: roleColor.withValues(alpha: 0.14),
                      child: Text(
                        a.initials,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (a.online)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.user.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.user.email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.grey600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(label: a.user.roleLabel, color: roleColor),
                          if (a.online) StatusChip.ok('Online'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final meta = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  a.lastLoginAt == null
                      ? 'Never signed in'
                      : 'Last login ${_fmt(a.lastLoginAt!)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered ${_fmtDate(a.registeredAt)} · '
                  '${a.loginCount} ${a.loginCount == 1 ? 'login' : 'logins'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 10), meta],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 16),
                meta,
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _fmt(DateTime d) {
    final h24 = d.hour;
    final hour12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '${_fmtDate(d)} · $hour12:$minute $period';
  }
}
