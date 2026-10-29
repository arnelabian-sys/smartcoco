import 'package:flutter/foundation.dart';

/// Where the Flutter app finds the SmartCoco REST API.
///
/// The web build talks to the FastAPI backend by default. Use
/// `flutter run -d chrome --dart-define=SMARTCOCO_API_BASE=http://127.0.0.1:8000/api/v1`
/// (or `SMARTCOCO_API=false` to fall back to the built-in mock data) when
/// running locally or against a deployed server.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the API, including the `/api/v1` prefix.
  static const String baseUrl = String.fromEnvironment(
    'SMARTCOCO_API_BASE',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// `true` on the web build; tests and desktop builds keep the mock backend.
  ///
  /// Override with `--dart-define=SMARTCOCO_API=true|false`.
  static const bool _fromEnvironment = bool.fromEnvironment(
    'SMARTCOCO_API',
    defaultValue: kIsWeb,
  );

  /// Tests flip this to exercise the REST code paths without the browser.
  static bool? debugOverride;

  static bool get enabled => debugOverride ?? _fromEnvironment;

  /// How long a single request may take before it is reported as unreachable.
  static const Duration timeout = Duration(seconds: 20);
}
