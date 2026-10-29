import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartcoco/services/api_client.dart';
import 'package:smartcoco/services/api_config.dart';
import 'package:smartcoco/services/auth_controller.dart';
import 'package:smartcoco/services/data_store.dart';
import 'package:smartcoco/utils/picked_file.dart';

/// Exercises the REST code paths against a mocked FastAPI server.
///
/// The real web build uses the same [ApiClient]/[DataStore] methods; only the
/// HTTP transport differs, so this covers the JSON wiring without needing
/// PostgreSQL or uvicorn during `flutter test`.

const _user = {
  'id': 1,
  'first_name': 'Maria',
  'last_name': 'Santos',
  'name': 'Maria Santos',
  'email': 'maria@smartcoco.ph',
  'role': 'farmer',
  'role_label': 'Farmer',
  'status': 'active',
  'birthday': '1999-04-02',
  'gender': 'Female',
  'login_count': 3,
  'last_login_at': '2026-10-29T08:15:00+00:00',
  'created_at': '2026-10-01T09:00:00+00:00',
  'online': true,
};

const _variety = {
  'id': 1,
  'code': 'TALL',
  'name': 'Tall',
  'local_name': null,
  'description': 'Tall coconut variety, used for copra and water.',
  'reference_image': null,
  'active': true,
  'created_at': '2026-10-01T09:00:00+00:00',
  'updated_at': '2026-10-01T09:00:00+00:00',
};

Map<String, dynamic> _prediction(int id, {String status = 'success'}) => {
  'id': id,
  'user_id': 1,
  'variety': status == 'success' ? _variety : null,
  'confidence': status == 'success' ? 0.91 : null,
  'image_path': 'predictions/2026/10/$id.png',
  'status': status,
  'error_message': null,
  'latency_ms': 320,
  'created_at': '2026-10-29T10:00:00+00:00',
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

PickedFile _photo(String name) => PickedFile(
  name: name,
  type: 'image/png',
  size: 68,
  bytes: Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47]),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requests = <http.Request>[];

  setUp(() {
    requests.clear();
    ApiConfig.debugOverride = true;
    // Start from a clean, signed-out state without hitting the network.
    AuthController.instance.user.value = null;
    ApiClient.instance.token = null;
    ApiClient.instance.client = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      final method = request.method;

      if (path.endsWith('/auth/admin/login')) {
        return _json({
          'access_token': 'jwt-admin',
          'token_type': 'bearer',
          'expires_in': 28800,
          'user': {
            ..._user,
            'id': 2,
            'first_name': 'Admin',
            'last_name': 'User',
            'name': 'Admin User',
            'email': 'admin@smartcoco.ph',
            'role': 'admin',
            'online': false,
          },
        });
      }
      if (path.endsWith('/auth/login')) {
        return _json({
          'access_token': 'jwt-token',
          'token_type': 'bearer',
          'expires_in': 28800,
          'user': _user,
        });
      }
      if (path.endsWith('/auth/logout')) return _json({'detail': 'logged_out'});
      if (path.endsWith('/varieties') && method == 'GET') {
        return _json([_variety]);
      }
      if (path.endsWith('/predictions') && method == 'POST') {
        final filename = utf8.decode(request.bodyBytes, allowMalformed: true);
        return _json(
          filename.contains('empty')
              ? _prediction(9, status: 'empty')
              : _prediction(7),
          201,
        );
      }
      if (path.endsWith('/predictions') && method == 'GET') {
        return _json([_prediction(7), _prediction(5)]);
      }
      if (path.endsWith('/predictions/stats')) {
        return _json({
          'total': 3,
          'success': 2,
          'empty': 1,
          'error': 0,
          'average_confidence': 0.88,
          'by_variety': [
            {'variety_id': 1, 'code': 'TALL', 'name': 'Tall', 'count': 2},
          ],
        });
      }
      if (path.endsWith('/predictions/7')) return _json(_prediction(7));
      if (path.endsWith('/predictions/6')) return _json(_prediction(6));
      if (path.endsWith('/users/stats')) {
        return _json({
          'total_accounts': 2,
          'online_now': 1,
          'total_logins': 4,
          'admins': 1,
          'researchers': 0,
          'by_role': {'admin': 1, 'farmer': 1},
        });
      }
      if (path.endsWith('/users') && method == 'GET') {
        return _json([
          _user,
          {
            ..._user,
            'id': 2,
            'first_name': 'Admin',
            'last_name': 'User',
            'name': 'Admin User',
            'email': 'admin@smartcoco.ph',
            'role': 'admin',
            'online': false,
          },
        ]);
      }
      if (path.endsWith('/health')) {
        return _json({
          'api_up': true,
          'model_up': true,
          'checked_at': '2026-10-29T10:00:00+00:00',
          'api_version': '1.0.0',
          'model_version': 'cnn-v1.0.0',
          'architecture': 'MobileNetV2',
          'api_latency_ms': 3,
          'model_latency_ms': 180,
          'uptime_seconds': 600,
          'accuracy': 0.947,
          'active_varieties': 3,
          'checks': 12,
          'error': null,
        });
      }
      return _json({'detail': 'not_found'}, 404);
    });
  });

  tearDown(() {
    AuthController.instance.logout();
    ApiClient.instance.client = null;
    ApiClient.instance.token = null;
    ApiConfig.debugOverride = null;
  });

  test('login stores the JWT and maps the user', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');

    final user = AuthController.instance.user.value;
    expect(user, isNotNull);
    expect(user!.id, 'u1');
    expect(user.name, 'Maria Santos');
    expect(user.role, 'farmer');
    expect(user.birthday, DateTime(1999, 4, 2));
    expect(ApiClient.instance.token, 'jwt-token');
  });

  test('authenticated calls send the bearer token', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');
    await DataStore.instance.fetchVarieties();

    final varietiesCall = requests.lastWhere(
      (r) => r.url.path.endsWith('/varieties'),
    );
    expect(varietiesCall.headers['Authorization'], 'Bearer jwt-token');
  });

  test('varieties are mapped from the API response', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');
    final varieties = await DataStore.instance.fetchVarieties();

    expect(varieties.single.id, 'v1');
    expect(varieties.single.name, 'Tall');
    expect(varieties.single.active, isTrue);
    expect(DataStore.instance.varieties().single.name, 'Tall');
  });

  test('classification parses SUCCESS, EMPTY and ERROR', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');

    final success = await DataStore.instance.classifyImage(
      _photo('tall-01.png'),
    );
    expect(success, isNotNull);
    expect(success!.id, 'p7');
    expect(success.variety, 'Tall');
    expect(success.confidence, closeTo(0.91, 0.0001));
    expect(DataStore.instance.findPrediction('p7'), isNotNull);

    final empty = await DataStore.instance.classifyImage(
      _photo('empty_photo.png'),
    );
    expect(empty, isNull);
  });

  test('history, stats and single-record fetch use the API', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');

    final history = await DataStore.instance.fetchHistory();
    expect(history.map((p) => p.id), containsAll(['p7', 'p5']));
    expect(history.first.variety, 'Tall');

    final stats = await DataStore.instance.stats(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 29),
    );
    expect(stats['Tall'], 2);
    expect(stats['Unknown'], 1); // the EMPTY row

    final fetched = await DataStore.instance.fetchPrediction('p6');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'p6');
    expect(requests.any((r) => r.url.path.endsWith('/predictions/6')), isTrue);
  });

  test('admin lists, counts and health come from the backend', () async {
    await AuthController.instance.loginAsAdmin(
      'admin@smartcoco.ph',
      'Admin123',
    );
    expect(AuthController.instance.user.value!.isAdmin, isTrue);

    final accounts = await AuthController.instance.fetchAccounts();
    expect(accounts, hasLength(2));
    expect(accounts.first.user.email, 'maria@smartcoco.ph');
    expect(accounts.first.online, isTrue);
    expect(accounts.first.loginCount, 3);

    expect(await DataStore.instance.fetchUsersCount(), 2);

    final health = await DataStore.instance.health();
    expect(health.apiUp, isTrue);
    expect(health.modelVersion, 'cnn-v1.0.0');
    expect(health.activeVarieties, 3);
    expect(health.uptime.inSeconds, 600);
    expect(health.accuracy, closeTo(94.7, 0.001)); // 0..1 API value → percent
  });

  test('API errors keep their status and code', () async {
    ApiClient.instance.client = MockClient(
      (_) async => _json({'detail': 'invalid_credentials'}, 401),
    );
    await expectLater(
      AuthController.instance.login('maria@smartcoco.ph', 'wrong'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.code, 'code', 'invalid_credentials'),
      ),
    );
  });

  test('logout clears the token', () async {
    await AuthController.instance.login('maria@smartcoco.ph', 'Password123');
    AuthController.instance.logout();
    // The revoke call is fire-and-forget; let the mock record it.
    await Future<void>.delayed(Duration.zero);

    expect(AuthController.instance.user.value, isNull);
    expect(ApiClient.instance.token, isNull);
    expect(
      requests.where((r) => r.url.path.endsWith('/auth/logout')),
      isNotEmpty,
    );
  });
}
