import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/screens/upload_screen.dart';
import 'package:smartcoco/services/auth_controller.dart';
import 'package:smartcoco/utils/picked_file.dart';

/// A real 1x1 PNG so `Image.memory` has valid bytes to decode.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

PickedFile _photo(String name) =>
    PickedFile(name: name, type: 'image/png', size: _png.length, bytes: _png);

Widget _app(UploadScreen screen) => MaterialApp(
      home: screen,
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/classify/result/')) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('RESULT SCREEN')),
          );
        }
        return null;
      },
    );

/// Signs in (the mock auth delays 700 ms, so it needs real async).
Future<void> _signIn(WidgetTester tester) async {
  await tester.runAsync(
      () => AuthController.instance.login('user@smartcoco.ph', 'User1234'));
}

/// Taps Classify and lets the (2 s) mock request finish.
Future<void> _classify(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Classify'));
  await tester.pump(); // IDLE -> LOADING
  await tester.pump(const Duration(seconds: 3)); // request completes
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('IDLE: nothing classified yet', (tester) async {
    await _signIn(tester);
    await tester.pumpWidget(_app(const UploadScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Tap to choose a photo'), findsOneWidget);
    expect(find.text('No coconut detected'), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Classify'), findsOneWidget);
  });

  testWidgets('IDLE -> LOADING -> SUCCESS opens the result screen',
      (tester) async {
    await _signIn(tester);
    await tester.pumpWidget(_app(UploadScreen(initialFile: _photo('tall-01.png'))));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Classify'));
    await tester.pump();

    // LOADING
    expect(find.text('Analyzing photo…'), findsOneWidget);
    expect(find.text('Analyzing…'), findsOneWidget);

    // SUCCESS
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('RESULT SCREEN'), findsOneWidget);
  });

  testWidgets('LOADING -> EMPTY shows "No coconut detected" (no Retry)',
      (tester) async {
    await _signIn(tester);
    await tester.pumpWidget(_app(UploadScreen(initialFile: _photo('empty_photo.png'))));
    await tester.pumpAndSettle();

    await _classify(tester);

    expect(find.text('No coconut detected'), findsOneWidget);
    expect(find.text('No coconut found'), findsOneWidget); // status chip
    expect(find.text('Try another photo'), findsOneWidget);
    // EMPTY has no Retry arrow in the flow.
    expect(find.text('Retry'), findsNothing);
    expect(find.text('RESULT SCREEN'), findsNothing);
  });

  testWidgets('LOADING -> ERROR, then RETRY -> SUCCESS', (tester) async {
    await _signIn(tester);
    await tester.pumpWidget(_app(UploadScreen(initialFile: _photo('error_photo.png'))));
    await tester.pumpAndSettle();

    await _classify(tester);

    // ERROR
    expect(find.text('Classification service unavailable. Try again.'),
        findsOneWidget);
    expect(find.text('Failed'), findsOneWidget); // status chip
    expect(find.text('Retry'), findsOneWidget);

    // RETRY -> LOADING
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Analyzing photo…'), findsOneWidget);

    // ... and this time the request succeeds.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('RESULT SCREEN'), findsOneWidget);
  });
}
