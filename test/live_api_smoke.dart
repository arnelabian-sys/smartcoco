// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcoco/services/api_config.dart';
import 'package:smartcoco/services/auth_controller.dart';
import 'package:smartcoco/services/data_store.dart';
import 'package:smartcoco/utils/picked_file.dart';

/// One-off end-to-end check against the real FastAPI server.
///
///   SMARTCOCO_LIVE=1 flutter test test/live_api_smoke.dart
///
/// Skipped during the normal `flutter test` run (no server required).
final bool _live = Platform.environment['SMARTCOCO_LIVE'] == '1';

final Uint8List _png = Uint8List.fromList(const [
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

void main() {
  test('live API round trip', () async {
    ApiConfig.debugOverride = true;
    addTearDown(() {
      AuthController.instance.logout();
      ApiConfig.debugOverride = null;
    });

    // --- administrator ------------------------------------------------
    await AuthController.instance.loginAsAdmin(
      'admin@smartcoco.ph',
      'Admin123',
    );
    final admin = AuthController.instance.user.value!;
    expect(admin.isAdmin, isTrue);
    print('admin login        : ${admin.name} <${admin.email}>');

    final health = await DataStore.instance.health();
    expect(health.apiUp, isTrue);
    print(
      'health             : model=${health.modelVersion} '
      'varieties=${health.activeVarieties} checks=${health.checks}',
    );

    final varieties = await DataStore.instance.fetchVarieties();
    expect(varieties, isNotEmpty);
    print('varieties          : ${varieties.map((v) => v.name).join(', ')}');

    final accounts = await AuthController.instance.fetchAccounts();
    print('accounts           : ${accounts.length}');
    expect(accounts.any((a) => a.user.email == 'admin@smartcoco.ph'), isTrue);
    expect(await DataStore.instance.fetchUsersCount(), accounts.length);

    final adminStats = await DataStore.instance.stats(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );
    print('stats              : $adminStats');

    AuthController.instance.logout();
    print('admin logout       : token=${AuthController.instance.token}');

    // --- farmer -------------------------------------------------------
    const email = 'smoke@smartcoco.ph';
    const password = 'Smoke1234';
    try {
      await AuthController.instance.register(
        name: 'Smoke Tester',
        firstName: 'Smoke',
        lastName: 'Tester',
        email: email,
        password: password,
        birthday: DateTime(1995, 5, 20),
        gender: 'Male',
        role: 'farmer',
      );
      print('register           : created $email');
    } catch (e) {
      print('register           : $e (falling back to login)');
      await AuthController.instance.login(email, password);
    }
    expect(AuthController.instance.user.value!.role, 'farmer');

    final photo = PickedFile(
      name: 'tall_smoke.png',
      type: 'image/png',
      size: _png.length,
      bytes: _png,
    );
    final prediction = await DataStore.instance.classifyImage(photo);
    expect(prediction, isNotNull);
    print(
      'classify SUCCESS   : ${prediction!.variety} '
      '${(prediction.confidence! * 100).toStringAsFixed(1)}% id=${prediction.id}',
    );

    final empty = await DataStore.instance.classifyImage(
      PickedFile(
        name: 'empty_photo.png',
        type: 'image/png',
        size: _png.length,
        bytes: _png,
      ),
    );
    expect(empty, isNull);
    print('classify EMPTY     : null (as expected)');

    final history = await DataStore.instance.fetchHistory();
    expect(history, isNotEmpty);
    print('history            : ${history.length} record(s)');

    final detail = await DataStore.instance.fetchPrediction(history.first.id);
    expect(detail, isNotNull);
    expect(detail!.id, history.first.id);
    print('record by id       : ${detail.id} â†’ ${detail.variety}');
  }, skip: !_live);
}
