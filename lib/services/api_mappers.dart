import '../models/models.dart';

/// Converts the JSON returned by the FastAPI backend into the app's models.
///
/// Ids are stored as strings in the UI; the numeric database ids are prefixed
/// (`u1`, `v2`, `p3`) so they can never collide with the mock ids (`u_admin`,
/// `v1`, `p1700000000000`).
class ApiMappers {
  ApiMappers._();

  static String _id(String prefix, Object? value) => '$prefix$value';

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static DateTime _dateOrNow(Object? value) => _date(value) ?? DateTime.now();

  static AppUser user(Map<String, dynamic> json) {
    final first = (json['first_name'] as String?)?.trim();
    final last = (json['last_name'] as String?)?.trim();
    final fallbackName = '${first ?? ''} ${last ?? ''}'.trim();
    return AppUser(
      id: _id('u', json['id']),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : (fallbackName.isEmpty ? 'SmartCoco user' : fallbackName),
      email: (json['email'] as String? ?? '').trim(),
      role: (json['role'] as String?) ?? 'user',
      firstName: first,
      lastName: last,
      birthday: _date(json['birthday']),
      gender: json['gender'] as String?,
    );
  }

  static UserAccount account(Map<String, dynamic> json) {
    return UserAccount(
      user: user(json),
      registeredAt: _dateOrNow(json['created_at']),
      lastLoginAt: _date(json['last_login_at']),
      loginCount: (json['login_count'] as num?)?.toInt() ?? 0,
      online: json['online'] == true,
    );
  }

  static Variety variety(Map<String, dynamic> json) {
    return Variety(
      id: _id('v', json['id']),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      active: json['active'] != false,
    );
  }

  static Prediction prediction(Map<String, dynamic> json) {
    final variety = json['variety'];
    return Prediction(
      id: _id('p', json['id']),
      userId: _id('u', json['user_id']),
      variety: variety is Map ? variety['name'] as String? : null,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: _dateOrNow(json['created_at']),
      failed: json['status'] != null && json['status'] != 'success',
    );
  }

  static SystemHealth health(Map<String, dynamic> json) {
    return SystemHealth(
      apiUp: json['api_up'] != false,
      modelUp: json['model_up'] != false,
      checkedAt: _dateOrNow(json['checked_at']),
      apiVersion: (json['api_version'] as String?) ?? '—',
      modelVersion: (json['model_version'] as String?) ?? '—',
      architecture: (json['architecture'] as String?) ?? '—',
      apiLatencyMs: (json['api_latency_ms'] as num?)?.toInt() ?? 0,
      modelLatencyMs: (json['model_latency_ms'] as num?)?.toInt() ?? 0,
      uptime: Duration(seconds: (json['uptime_seconds'] as num?)?.toInt() ?? 0),
      accuracy: _percent(json['accuracy']),
      activeVarieties: (json['active_varieties'] as num?)?.toInt() ?? 0,
      checks: (json['checks'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
    );
  }

  /// Extracts the numeric part of one of the prefixed UI ids.
  static String numericId(String id) => id.replaceFirst(RegExp(r'^[a-z]+'), '');

  /// The API stores accuracy as a 0..1 fraction, the UI shows percentages.
  static double _percent(Object? value) {
    final numeric = (value as num?)?.toDouble() ?? 0;
    return numeric > 0 && numeric <= 1 ? numeric * 100 : numeric;
  }
}
