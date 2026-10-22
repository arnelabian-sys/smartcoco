import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/auth_controller.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool Function(AppUser? user) allowed;
  const NavItem(this.label, this.icon, this.route, this.allowed);
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({super.key, required this.child, required this.currentRoute});

  static List<NavItem> itemsFor(AppUser? user) {
    return [
      NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard', (u) => u != null),
      NavItem('Classify', Icons.cloud_upload_outlined, '/classify', (u) => u != null),
      NavItem('History', Icons.history, '/history', (u) => u != null && (u.role == 'user' || u.role == 'researcher' || u.role == 'admin')),
      NavItem('Varieties', Icons.eco_outlined, '/varieties', (u) => u != null),
      NavItem('Statistics', Icons.bar_chart_outlined, '/stats', (u) => u?.role == 'researcher'),
      NavItem('Admin Varieties', Icons.admin_panel_settings_outlined, '/admin/varieties', (u) => u?.role == 'admin'),
      NavItem('Admin Status', Icons.monitor_heart_outlined, '/admin/status', (u) => u?.role == 'admin'),
      NavItem('Settings', Icons.settings_outlined, '/settings', (u) => u != null),
    ].where((e) => e.allowed(user)).toList();
  }

  int _selectedIndex(List<NavItem> items) {
    final idx = items.indexWhere((e) => currentRoute == e.route || currentRoute.startsWith('${e.route}/'));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.user.value;
    final items = itemsFor(user);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    void onNavigate(int i) {
      final route = items[i].route;
      if (route != currentRoute) Navigator.pushReplacementNamed(context, route);
    }

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SmartCoco'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          )),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') {
                  AuthController.instance.logout();
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'profile', enabled: false, child: Text(user?.name ?? '')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AppColors.primary,
          child: Container(
            color: AppColors.primary,
            child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: const [
                          Icon(Icons.eco, color: Colors.white, size: 26),
                          SizedBox(width: 6),
                          Text('SmartCoco',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    ...items.asMap().entries.map((e) => ListTile(
                          leading: Icon(e.value.icon,
                              color: _selectedIndex(items) == e.key ? AppColors.primary : Colors.white),
                          title: Text(e.value.label,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          selected: _selectedIndex(items) == e.key,
                          selectedColor: AppColors.primary,
                          iconColor: AppColors.primary,
                          tileColor: _selectedIndex(items) == e.key ? Colors.white : null,
                          onTap: () {
                            Navigator.pop(context);
                            onNavigate(e.key);
                          },
                        )),
                  ],
                ),
              ),
            ),
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            backgroundColor: AppColors.primary,
            extended: !isTablet,
            minExtendedWidth: 200,
            selectedIndex: _selectedIndex(items),
            onDestinationSelected: onNavigate,
            indicatorColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            labelType: isTablet ? NavigationRailLabelType.none : NavigationRailLabelType.none,
            destinations: items
                .map((e) => NavigationRailDestination(
                      icon: Tooltip(message: e.label, child: Icon(e.icon)),
                      label: Text(e.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Logout',
                    color: Colors.white,
                    hoverColor: Colors.white24,
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      AuthController.instance.logout();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

