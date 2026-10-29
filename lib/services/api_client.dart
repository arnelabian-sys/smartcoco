import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// One failed API call.
///
/// [statusCode] is `0` when the server could not be reached at all. [code] is
/// the machine-readable `detail` returned by FastAPI (`invalid_credentials`,
/// `duplicate_email`, ...) so the screens can keep switching on strings.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException(this.statusCode, this.code, [this.message = '']);

  bool get isNetworkError => statusCode == 0;

  @override
  String toString() {
    final details = message.isEmpty ? '' : ' $message';
    return 'ApiException($statusCode $code)$details';
  }
}

/// Thin JSON/REST client for the FastAPI backend.
///
/// The JWT lives in [token] and is sent as `Authorization: Bearer ...` on every
/// authenticated call. [AuthController] owns the token and persists it in the
/// browser's `localStorage`, so a page refresh keeps the session.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Replaceable for tests (e.g. `MockClient` from `package:http/testing.dart`).
  http.Client? client;

  String? token;

  http.Client get _client => client ??= http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$clean').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    return _run(() => _client.get(_uri(path, query), headers: _headers));
  }

  Future<dynamic> postJson(String path, {Object? body}) async {
    return _run(
      () => _client.post(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> patchJson(String path, {Object? body}) async {
    return _run(
      () => _client.patch(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> deleteJson(String path) async {
    return _run(() => _client.delete(_uri(path), headers: _headers));
  }

  /// Uploads one image to `POST /predictions`.
  Future<dynamic> postImage(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _mediaType(contentType),
        ),
      );
    try {
      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(0, 'timeout');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, 'network_error');
    }
  }

  Future<dynamic> _run(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(ApiConfig.timeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(0, 'timeout');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(0, 'network_error');
    }
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        body = null;
      }
    }
    if (status >= 200 && status < 300) return body;

    var code = 'http_$status';
    var message = response.reasonPhrase ?? '';
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        code = detail;
      } else if (detail is List && detail.isNotEmpty) {
        code = 'validation_error';
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          message = first['msg'] as String;
        }
      } else if (body['message'] is String) {
        message = body['message'] as String;
      }
    }
    throw ApiException(status, code, message);
  }

  static http.MediaType _mediaType(String mime) {
    final parts = mime.split('/');
    if (parts.length == 2) {
      return http.MediaType(parts[0], parts[1]);
    }
    return http.MediaType('application', 'octet-stream');
  }
}
