import 'package:flutter/material.dart';

import '../services/auth_controller.dart';

/// ---------------------------------------------------------------------------
/// SmartCoco top navigation bar.
///
/// Left  : coconut logo badge + "SmartCoco" word mark.
/// Right : Home / About links and a rounded "Login" action (turns into
///         "Dashboard" once a user is signed in).
///
/// The bar is responsive: below 700 px the links collapse into a menu so the
/// header never overflows on phones or narrow browser windows.
/// ---------------------------------------------------------------------------
class SmartCocoNavBar extends StatelessWidget {
  const SmartCocoNavBar({super.key, this.currentRoute = '/'});

  /// Route of the page showing the bar — used to highlight the active link.
  final String currentRoute;

  static const Color green800 = Color(0xFF2E7D32); // Colors.green[800]
  static const Color green600 = Color(0xFF43A047); // Colors.green[600]
  static const Color textGreen = Color(0xFF1B5E20);

  void _goHome(BuildContext context) {
    if (currentRoute == '/') return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  void _goAbout(BuildContext context) {
    if (currentRoute == '/landing') return;
    Navigator.pushNamed(context, '/landing');
  }

  void _goLogin(BuildContext context, bool loggedIn) {
    Navigator.pushNamed(context, loggedIn ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the session changes (login, logout, restored session)
    // so the "Login" button flips to "Dashboard" on its own.
    return ValueListenableBuilder(
      valueListenable: AuthController.instance.user,
      builder: (context, user, _) {
        final loggedIn = user != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            // Very narrow windows: drop the word mark and the button label so the
            // bar never overflows.
            final veryNarrow = constraints.maxWidth < 430;

            return Container(
              height: compact ? 58 : 68,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                border: Border(
                  bottom: BorderSide(
                    color: green800.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ---------------------------------------------------------- //
                  // Left: logo + app title
                  // ---------------------------------------------------------- //
                  _Brand(onTap: () => _goHome(context), showTitle: !veryNarrow),
                  const Spacer(),

                  // ---------------------------------------------------------- //
                  // Right: links + Login (desktop / tablet)
                  // ---------------------------------------------------------- //
                  if (!compact) ...[
                    _NavLink(
                      label: 'Home',
                      selected: currentRoute == '/',
                      onTap: () => _goHome(context),
                    ),
                    _NavLink(
                      label: 'About',
                      selected: currentRoute == '/landing',
                      onTap: () => _goAbout(context),
                    ),
                    const SizedBox(width: 12),
                    _LoginAction(
                      label: loggedIn ? 'Dashboard' : 'Login',
                      icon: loggedIn ? Icons.dashboard_outlined : Icons.login,
                      onTap: () => _goLogin(context, loggedIn),
                    ),
                  ] else ...[
                    _CompactMenu(
                      currentRoute: currentRoute,
                      loggedIn: loggedIn,
                      onHome: () => _goHome(context),
                      onAbout: () => _goAbout(context),
                      onLogin: () => _goLogin(context, loggedIn),
                    ),
                    const SizedBox(width: 8),
                    _LoginAction(
                      label: loggedIn ? 'Dashboard' : 'Login',
                      icon: loggedIn ? Icons.dashboard_outlined : Icons.login,
                      onTap: () => _goLogin(context, loggedIn),
                      compact: true,
                      showLabel: !veryNarrow,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Logo badge + "SmartCoco" word mark.
class _Brand extends StatelessWidget {
  const _Brand({required this.onTap, this.showTitle = true});

  final VoidCallback onTap;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SmartCocoNavBar.green600, SmartCocoNavBar.green800],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SmartCocoNavBar.green800.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 22),
            ),
            if (showTitle) ...[
              const SizedBox(width: 10),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Smart',
                      style: TextStyle(color: SmartCocoNavBar.textGreen),
                    ),
                    TextSpan(
                      text: 'Coco',
                      style: TextStyle(color: SmartCocoNavBar.green600),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped text link with a smooth hover highlight.
class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _hover || widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: highlighted
                ? SmartCocoNavBar.green600.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w700,
              color: highlighted
                  ? SmartCocoNavBar.green800
                  : const Color(0xFF33691E),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded primary action: "Login" (or "Dashboard" when signed in).
class _LoginAction extends StatefulWidget {
  const _LoginAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
    this.showLabel = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  final bool showLabel;

  @override
  State<_LoginAction> createState() => _LoginActionState();
}

class _LoginActionState extends State<_LoginAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover ? SmartCocoNavBar.green600 : SmartCocoNavBar.green800;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: _hover ? 0.45 : 0.28),
              blurRadius: _hover ? 14 : 8,
              offset: Offset(0, _hover ? 5 : 3),
            ),
          ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size(
              widget.showLabel ? (widget.compact ? 0 : 112) : 42,
              42,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.showLabel ? (widget.compact ? 14 : 22) : 0,
              vertical: 10,
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: widget.onTap,
          child: widget.showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(widget.label),
                  ],
                )
              : Icon(widget.icon, size: 20),
        ),
      ),
    );
  }
}

/// Collapsed links for narrow screens.
class _CompactMenu extends StatelessWidget {
  const _CompactMenu({
    required this.currentRoute,
    required this.loggedIn,
    required this.onHome,
    required this.onAbout,
    required this.onLogin,
  });

  final String currentRoute;
  final bool loggedIn;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu, color: SmartCocoNavBar.green800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'home':
            onHome();
            break;
          case 'about':
            onAbout();
            break;
          default:
            onLogin();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'home',
          child: _MenuRow(
            icon: Icons.home_outlined,
            label: 'Home',
            active: currentRoute == '/',
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: _MenuRow(
            icon: Icons.info_outline,
            label: 'About',
            active: currentRoute == '/landing',
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? SmartCocoNavBar.green800 : const Color(0xFF33691E);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
