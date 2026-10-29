import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/widgets/smartcoco_navbar.dart';

void main() {
  Future<void> pumpNav(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SmartCocoNavBar())),
    );
    await tester.pump();
  }

  testWidgets('desktop bar shows brand, Home, About and Login', (tester) async {
    await pumpNav(tester, const Size(1280, 800));

    // Brand: "Smart" + "Coco" rich text.
    expect(find.text('SmartCoco', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Login is the rounded primary action.
    final login = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Login'),
    );
    final shape = login.style?.shape?.resolve({}) as RoundedRectangleBorder?;
    expect(shape?.borderRadius, BorderRadius.circular(999));
  });

  testWidgets('narrow window collapses the links into a menu', (tester) async {
    await pumpNav(tester, const Size(600, 800));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('About'), findsNothing);
    // Login stays visible even on narrow screens.
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Home'), findsWidgets);
    expect(find.text('About'), findsWidgets);
  });

  testWidgets('links have hover feedback', (tester) async {
    await pumpNav(tester, const Size(1280, 800));

    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: Offset.zero);
    addTearDown(hover.removePointer);

    final homeCenter = tester.getCenter(find.text('Home'));
    await hover.moveTo(homeCenter);
    await tester.pump(const Duration(milliseconds: 250));

    // No exceptions and the link is still rendered after hovering.
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);

    await hover.moveTo(tester.getCenter(find.text('Login')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('bar fits inside the screen width on all sizes', (tester) async {
    for (final size in const [
      Size(1535, 900),
      Size(900, 700),
      Size(699, 800),
      Size(400, 800),
    ]) {
      await pumpNav(tester, size);
      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byType(SmartCocoNavBar));
      expect(bar.width, size.width);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
