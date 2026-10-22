import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/screens/register_screen.dart';

Future<void> pickDropdown(
    WidgetTester tester, Finder dropdown, Finder item) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown, warnIfMissed: false);
  await tester.pumpAndSettle();
  expect(item, findsWidgets, reason: 'the dropdown menu did not open');
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Register form shows the requested fields in order',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    // Heading ("Register" appears twice: heading + submit button label)
    expect(find.text('Register'), findsNWidgets(2));
    final headingY = tester.getCenter(find.text('Register').first).dy;
    final buttonY =
        tester.getCenter(find.widgetWithText(FilledButton, 'Register')).dy;
    expect(headingY, lessThan(buttonY),
        reason: 'the Register heading must sit above the Register button');

    // Section labels
    const labels = [
      'Name',
      'Birthday',
      'Gender',
      'Role',
      'Email',
      'Password',
      'Confirm password',
    ];
    for (final l in labels) {
      expect(find.text(l), findsOneWidget, reason: 'missing label: $l');
    }

    // Placeholders / hints
    for (final h in [
      'First name',
      'Last name',
      'Month',
      'Day',
      'Year',
      'Select gender (Optional)',
      'Select role',
      'Password (at least 8 characters)',
    ]) {
      expect(find.text(h), findsOneWidget, reason: 'missing field: $h');
    }

    // Dropdowns (5 of them)
    expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(3));
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

    // Required-ness: everything is required EXCEPT gender.
    final stringDropdowns = tester
        .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>))
        .toList();
    expect(stringDropdowns.first.validator, isNull,
        reason: 'Gender must be optional');
    expect(stringDropdowns.last.validator, isNotNull,
        reason: 'Role must be required');

    for (final d in tester.widgetList<DropdownButtonFormField<int>>(
        find.byType(DropdownButtonFormField<int>))) {
      expect(d.validator, isNotNull,
          reason: 'Month / Day / Year must be required');
    }

    // Vertical order of the labels
    final ys = <String, double>{};
    for (final l in labels) {
      ys[l] = tester.getCenter(find.text(l)).dy;
    }
    final ordered = ys.keys.toList()
      ..sort((a, b) => ys[a]!.compareTo(ys[b]!));
    expect(ordered, labels);

    // First name / Last name on the same row, side by side
    expect(tester.getCenter(find.text('First name')).dy,
        tester.getCenter(find.text('Last name')).dy);
    expect(tester.getCenter(find.text('First name')).dx,
        lessThan(tester.getCenter(find.text('Last name')).dx));

    // Month / Day / Year on the same row, side by side
    expect(tester.getCenter(find.text('Month')).dy,
        tester.getCenter(find.text('Day')).dy);
    expect(tester.getCenter(find.text('Day')).dy,
        tester.getCenter(find.text('Year')).dy);
    expect(tester.getCenter(find.text('Month')).dx,
        lessThan(tester.getCenter(find.text('Day')).dx));
    expect(tester.getCenter(find.text('Day')).dx,
        lessThan(tester.getCenter(find.text('Year')).dx));

    // Gender + Role dropdowns are full width, stacked
    expect(tester.getCenter(find.text('Select gender (Optional)')).dy,
        lessThan(tester.getCenter(find.text('Select role')).dy));

    // Terms, submit button, login link
    expect(find.text('I agree to Terms and Privacy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);

    // No leftover "Full name" field from the old form
    expect(find.text('Full name'), findsNothing);
  });

  testWidgets('empty fields warn "This field is required."', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    const msg = 'This field is required.';
    expect(find.text(msg), findsWidgets);

    // The message is attached to the First name box.
    final firstField = find.ancestor(
        of: find.text('First name'), matching: find.byType(TextFormField));
    expect(find.descendant(of: firstField, matching: find.text(msg)),
        findsOneWidget);

    // ... and to the Password box as well.
    final passField = find.ancestor(
        of: find.text('Password (at least 8 characters)'),
        matching: find.byType(TextFormField));
    expect(find.descendant(of: passField, matching: find.text(msg)),
        findsOneWidget);

    // Gender is optional -> no warning on the Gender dropdown.
    final genderField = find.ancestor(
        of: find.text('Select gender (Optional)'),
        matching: find.byType(DropdownButtonFormField<String>));
    expect(find.descendant(of: genderField, matching: find.text(msg)),
        findsNothing);
  });

  testWidgets('submitting traces (scrolls to) the first missing box',
      (tester) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    // Fill the two name boxes, so the first missing box is the Month dropdown.
    await tester.enterText(
        find.ancestor(
            of: find.text('First name'), matching: find.byType(TextFormField)),
        'Juan');
    await tester.enterText(
        find.ancestor(
            of: find.text('Last name'), matching: find.byType(TextFormField)),
        'Dela Cruz');
    await tester.pumpAndSettle();

    final button = find.widgetWithText(FilledButton, 'Register');
    final scrollable = find
        .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
        .first;
    final monthDropdown = find.byType(DropdownButtonFormField<int>).first;

    // Scroll to the very bottom so the Month dropdown is off-screen.
    final scrollState = tester.state<ScrollableState>(scrollable);
    scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.getRect(monthDropdown).top, lessThan(0),
        reason: 'precondition: the Month dropdown must start off-screen');

    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    // The submit ran and the uniform warning is shown.
    expect(find.text('This field is required.'), findsWidgets);

    // Trace: the form scrolled back up to the first missing box (Month).
    expect(tester.getRect(monthDropdown).top, greaterThanOrEqualTo(0),
        reason: 'the form should scroll to the first missing field');
    expect(tester.getRect(monthDropdown).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height));

    // The Month dropdown now carries the warning.
    expect(
        find.descendant(
            of: monthDropdown,
            matching: find.text('This field is required.')),
        findsOneWidget);
  });

  testWidgets('a completed registration shows the success state',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    Future<void> type(String hint, String value) async {
      final field = find.ancestor(
          of: find.text(hint), matching: find.byType(TextFormField));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }

    await type('First name', 'Juan');
    await type('Last name', 'Dela Cruz');

    // Month / Day / Year
    await pickDropdown(
        tester,
        find.byType(DropdownButtonFormField<int>).at(0),
        find.widgetWithText(DropdownMenuItem<int>, 'January'));
    await pickDropdown(
        tester,
        find.byType(DropdownButtonFormField<int>).at(1),
        find.widgetWithText(DropdownMenuItem<int>, '15'));
    await pickDropdown(
        tester,
        find.byType(DropdownButtonFormField<int>).at(2),
        find.widgetWithText(DropdownMenuItem<int>,
            '${DateTime.now().year}'));

    // Role (the 2nd string dropdown = Role, Gender is the 1st)
    await pickDropdown(
        tester,
        find.byType(DropdownButtonFormField<String>).at(1),
        find.widgetWithText(DropdownMenuItem<String>, 'Student'));

    await type('name@example.com', 'juan.delacruz@example.com');
    await type('Password (at least 8 characters)', 'Passw0rd');
    await type('Re-enter your password', 'Passw0rd');

    // Terms
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Submit
    final button = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Success state
    expect(find.text('Registration successful! You can now log in.'),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);

    // The form is replaced by the success panel.
    expect(find.text('First name'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });
}
