import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/models/models.dart';
import 'package:smartcoco/screens/admin_users_screen.dart';
import 'package:smartcoco/services/auth_controller.dart';
import 'package:smartcoco/widgets/app_shell.dart';

void main() {
  Future<void> loginAdmin(WidgetTester tester) async {
    await tester.runAsync(
      () => AuthController.instance.loginAsAdmin(
        'admin@smartcoco.ph',
        'Admin123',
      ),
    );
  }

  /// Registers an extra account (like a row in the `users` table) and signs
  /// out again, so only the administrator is online afterwards.
  Future<void> addAccount(
    WidgetTester tester, {
    required String name,
    required String email,
    required String role,
  }) async {
    await tester.runAsync(() async {
      final exists = AuthController.instance.registeredUsers.any(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (!exists) {
        await AuthController.instance.register(
          name: name,
          email: email,
          password: 'Password123',
          role: role,
        );
      }
      AuthController.instance.logout();
    });
  }

  setUp(() {
    AuthController.instance.logout();
  });

  testWidgets('admin sidebar lists Dashboard and User Management', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final items = AppShell.itemsFor(
      const AppUser(id: 'a', name: 'Admin', email: 'a@b.ph', role: 'admin'),
    );
    final labels = items.map((e) => e.label).toList();

    expect(labels.first, 'Dashboard');
    expect(labels.contains('User Management'), isTrue);
    expect(labels.contains('Settings'), isTrue);
    // Management-only: no classify/history for admins.
    expect(labels.contains('Classify'), isFalse);
    expect(labels.contains('History'), isFalse);

    final users = items.firstWhere((e) => e.label == 'User Management');
    expect(users.route, '/admin/users');
  });

  testWidgets('user management lists accounts with roles and login activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A registered farmer, on top of the provisioned administrator.
    await addAccount(
      tester,
      name: 'Maria Santos',
      email: 'maria@smartcoco.ph',
      role: 'farmer',
    );
    await loginAdmin(tester);

    await tester.pumpWidget(const MaterialApp(home: AdminUsersScreen()));
    await tester.pump();

    expect(find.text('User Management'), findsWidgets);
    // The provisioned administrator is always there ...
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('admin@smartcoco.ph'), findsOneWidget);
    // ... plus the registered farmer (no demo accounts anymore).
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('maria@smartcoco.ph'), findsOneWidget);
    expect(find.text('Researcher User'), findsNothing);

    // Stats: the signed-in admin is online, and the login was counted.
    expect(find.text('Online Now'), findsOneWidget);
    expect(find.text('Total Logins'), findsOneWidget);
    expect(AuthController.instance.onlineCount, 1);
    expect(AuthController.instance.totalLogins, greaterThanOrEqualTo(1));

    // The signed-in administrator has an "Online" chip.
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('search and role filters narrow the list', (tester) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await addAccount(
      tester,
      name: 'Maria Santos',
      email: 'maria@smartcoco.ph',
      role: 'farmer',
    );
    await loginAdmin(tester);

    await tester.pumpWidget(const MaterialApp(home: AdminUsersScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'maria');
    await tester.pump();

    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('admin@smartcoco.ph'), findsNothing);

    // Clear the search, then filter by role chip.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Admin'));
    await tester.pump();

    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);
  });

  test('accounts expose registration and login metrics', () async {
    final before = AuthController.instance.registeredUsersCount();
    await AuthController.instance.register(
      name: 'Nena Bautista',
      email: 'nena@smartcoco.ph',
      password: 'Password123',
      role: 'farmer',
    );

    final accounts = AuthController.instance.accounts;
    expect(AuthController.instance.registeredUsersCount(), greaterThan(before));

    final nena = accounts.firstWhere(
      (a) => a.user.email == 'nena@smartcoco.ph',
    );
    expect(nena.user.role, 'farmer');
    expect(nena.initials, 'NB');
    expect(nena.loginCount, 1);
    expect(nena.online, isTrue);
    expect(nena.lastLoginAt, isNotNull);
  });
}
