import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/screens/home_screen.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
  }

  testWidgets('homepage lays out without Positioned constraint assertions', (
    tester,
  ) async {
    // Wide desktop, standard laptop and narrow mobile-ish window.
    for (final size in const [
      Size(1535, 800),
      Size(1280, 1000),
      Size(1920, 900),
      Size(600, 900),
    ]) {
      await pumpHome(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('slideshow advances automatically every 4 seconds', (
    tester,
  ) async {
    await pumpHome(tester, const Size(1535, 800));

    expect(
      find.byKey(const ValueKey('assets/images/coconut1.jpg')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    // Let the 900 ms fade finish (pumpAndSettle can't be used here because the
    // caption under the Register button blinks forever).
    await tester.pump(const Duration(milliseconds: 950));

    expect(
      find.byKey(const ValueKey('assets/images/coconut2.jpg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assets/images/coconut1.jpg')),
      findsNothing,
    );
  });

  testWidgets('dot indicators jump to a specific slide', (tester) async {
    await pumpHome(tester, const Size(1535, 800));

    // 8 dots, one per image (scoped to the slideshow — the nav bar also
    // uses AnimatedContainer for its hover effects).
    final dots = find.descendant(
      of: find.byType(HomeSlideshow),
      matching: find.byType(AnimatedContainer),
    );
    expect(dots, findsNWidgets(8));

    // Tap the 5th dot -> 5th image shows.
    await tester.tap(dots.at(4));
    await tester.pump(const Duration(milliseconds: 950));
    expect(
      find.byKey(const ValueKey('assets/images/coconut5.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('register caption is centered under the button and blinks', (
    tester,
  ) async {
    await pumpHome(tester, const Size(1535, 800));

    final caption = find.text(
      'Click Register now to start\nclassifying coconut variety',
    );
    expect(caption, findsOneWidget);

    // Centered horizontally under the button, a bit lower than it.
    final buttonRect = tester.getRect(
      find.widgetWithText(FilledButton, 'Register now'),
    );
    final captionRect = tester.getRect(find.byType(BlinkingCaption));
    expect((captionRect.center.dx - buttonRect.center.dx).abs(), lessThan(1.0));
    expect(captionRect.top, greaterThan(buttonRect.bottom));

    // Text is opaque white-on-green backdrop -> readable.
    final text = tester.widget<Text>(caption);
    expect(text.style?.color, const Color(0xFF0B4D2C));
    expect(text.style?.fontWeight, FontWeight.w800);

    // Blinking: the fade opacity changes over time.
    FadeTransition fade() => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(BlinkingCaption),
        matching: find.byType(FadeTransition),
      ),
    );

    final before = fade().opacity.value;
    await tester.pump(const Duration(milliseconds: 300));
    final after = fade().opacity.value;
    expect((after - before).abs(), greaterThan(0.05));
  });
}
