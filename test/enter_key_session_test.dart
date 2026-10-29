import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/screens/login_screen.dart';
import 'package:smartcoco/screens/register_screen.dart';
import 'package:smartcoco/services/auth_controller.dart';

import 'test_accounts.dart';

Widget _loginApp() => MaterialApp(
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

void main() {
  setUp(() async {
    // Only the administrator is provisioned, so register the normal account
    // these tests sign in with.
    await ensureUserAccount();
  });

  testWidgets('Enter in the login password box signs the user in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_loginApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@smartcoco.ph',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'User1234');
    await tester.pump();

    // Simulate the physical Enter / "done" key on the keyboard.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(AuthController.instance.isLoggedIn, isTrue);
  });

  testWidgets('Enter in the e-mail box moves focus to the password box', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_loginApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@smartcoco.ph',
    );
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final pass = find.byType(TextFormField).at(1);
    final editable = tester.widget<EditableText>(
      find.descendant(of: pass, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('Enter in the register confirm box submits the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    final confirm = find.ancestor(
      of: find.text('Re-enter your password'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.enterText(confirm, 'Passw0rd');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // The form ran its validators (empty boxes are flagged).
    expect(find.text('This field is required.'), findsWidgets);
  });

  test('a signed-in session survives a refresh and clears on logout', () async {
    await AuthController.instance.login('user@smartcoco.ph', 'User1234');
    expect(AuthController.instance.isLoggedIn, isTrue);
    final email = AuthController.instance.user.value!.email;

    // Simulate a page reload: the in-memory account is gone ...
    AuthController.instance.user.value = null;
    expect(AuthController.instance.isLoggedIn, isFalse);

    // ... but start-up restores it from the session store.
    AuthController.instance.restoreSession();
    expect(AuthController.instance.isLoggedIn, isTrue);
    expect(AuthController.instance.user.value!.email, email);
    expect(AuthController.instance.user.value!.role, 'user');

    // An explicit logout forgets the session for good.
    AuthController.instance.logout();
    AuthController.instance.restoreSession();
    expect(AuthController.instance.isLoggedIn, isFalse);
  });
}
