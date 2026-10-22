import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/screens/login_screen.dart';

Widget _app() => MaterialApp(
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('DASHBOARD')),
          );
        }
        return null;
      },
    );

Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(700, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wrong password: warning on the password box, cleared for retry',
      (tester) async {
    await _pumpLogin(tester);

    final email = find.byType(TextFormField).at(0);
    final pass = find.byType(TextFormField).at(1);

    await tester.enterText(email, 'user@smartcoco.ph');
    await tester.enterText(pass, 'WrongPass1');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800)); // auth delay
    await tester.pumpAndSettle();

    const msg = 'Incorrect password. Please try again.';
    expect(find.text(msg), findsOneWidget);

    // The warning lives on the password box.
    expect(find.descendant(of: pass, matching: find.text(msg)), findsOneWidget);

    // No separate banner duplicating the message.
    expect(find.text('E-mail or password is incorrect.'), findsNothing);

    final passField = tester.widget<TextFormField>(pass);
    // The password was cleared ...
    expect(passField.controller!.text, isEmpty);
    // ... and focused so the user can type again.
    final editable = tester.widget<EditableText>(
        find.descendant(of: pass, matching: find.byType(EditableText)));
    expect(editable.focusNode.hasFocus, isTrue);

    // Typing clears the warning.
    await tester.enterText(pass, 'User1234');
    await tester.pump();
    expect(find.text(msg), findsNothing);
  });

  testWidgets('correct password logs in', (tester) async {
    await _pumpLogin(tester);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'user@smartcoco.ph');
    await tester.enterText(find.byType(TextFormField).at(1), 'User1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('Incorrect password. Please try again.'), findsNothing);
  });
}
