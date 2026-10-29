import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/routes/app_router.dart';
import 'package:smartcoco/screens/admin_status_screen.dart';
import 'package:smartcoco/screens/admin_varieties_screen.dart';
import 'package:smartcoco/screens/varieties_screen.dart';
import 'package:smartcoco/services/auth_controller.dart';
import 'package:smartcoco/services/data_store.dart';

Future<void> _loginAdmin(WidgetTester tester) async {
  await tester.runAsync(
    () =>
        AuthController.instance.loginAsAdmin('admin@smartcoco.ph', 'Admin123'),
  );
}

void main() {
  setUp(() {
    // Each test starts signed-in as the administrator.
    AuthController.instance.user.value = null;
  });

  testWidgets('admin update is saved and shown on the Varieties page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _loginAdmin(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: const AdminVarietiesScreen(),
        onGenerateRoute: generateRoute,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Variety Management'), findsWidgets);
    expect(find.text('Tall'), findsOneWidget);
    expect(find.text('Dwarf'), findsOneWidget);

    // Open the edit form for the first variety (Tall) and change its
    // description.
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Edit variety'), findsOneWidget);
    const updated = 'Tall palms are mainly grown for copra and coconut water.';
    await tester.enterText(find.byType(TextFormField).at(1), updated);
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 1. Persisted in the reference dataset.
    final tall = DataStore.instance
        .varieties(onlyActive: false)
        .firstWhere((v) => v.name == 'Tall');
    expect(tall.description, updated);

    // 2. The management list already shows the new copy.
    expect(find.text(updated), findsOneWidget);

    // 3. The list users see renders the same description.
    await tester.tap(find.text('View Varieties'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(VarietiesScreen), findsOneWidget);
    expect(find.text(updated), findsOneWidget);
  });

  testWidgets('Varieties page picks up a dataset change without reloading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _loginAdmin(tester);

    await tester.pumpWidget(const MaterialApp(home: VarietiesScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    const marker = 'Live update from the admin console.';
    expect(find.text(marker), findsNothing);

    final update = DataStore.instance.updateVariety('v1', description: marker);
    await tester.pump(const Duration(milliseconds: 500)); // repository write
    await tester.pump(const Duration(milliseconds: 500)); // in-place reload
    await tester.pump();
    await update;

    expect(find.text(marker), findsOneWidget);
  });

  testWidgets(
    'status page shows API and CNN model status and updates on refresh',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _loginAdmin(tester);

      await tester.pumpWidget(const MaterialApp(home: AdminStatusScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('All systems operational'), findsOneWidget);
      expect(find.text('API'), findsOneWidget);
      expect(find.text('CNN Model'), findsOneWidget);
      expect(find.text('Operational'), findsNWidgets(3));
      expect(find.text('CoconutNet'), findsOneWidget);
      expect(find.text('94.7%'), findsOneWidget);

      final before = tester
          .widget<Text>(find.textContaining('Last checked'))
          .data!;

      await tester.tap(find.text('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final after = tester
          .widget<Text>(find.textContaining('Last checked'))
          .data!;
      expect(after, isNot(before));
      expect(find.text('All systems operational'), findsOneWidget);
    },
  );

  testWidgets('status page reports an unreachable API and CNN model', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _loginAdmin(tester);

    await tester.pumpWidget(
      const MaterialApp(home: AdminStatusScreen(simulateDown: true)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Service degraded'), findsOneWidget);
    expect(find.text('Down'), findsNWidgets(3));
    expect(find.text('API and CNN model are unreachable.'), findsOneWidget);
    expect(find.text('Demo: outage'), findsOneWidget);
  });
}
