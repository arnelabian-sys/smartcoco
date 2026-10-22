import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'auth_controller.dart';

class DataStore {
  DataStore._();
  static final DataStore instance = DataStore._();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final List<Variety> _varieties = [
    const Variety(id: 'v1', name: 'Tall', description: 'Tall coconut variety, used for copra and water.'),
    const Variety(id: 'v2', name: 'Dwarf', description: 'Short stature, early bearing, popular for tender coconut.'),
    const Variety(id: 'v3', name: 'Hybrid', description: 'Cross of Tall and Dwarf, high yield.'),
  ];

  final List<Prediction> _predictions = [];

  /// File names whose simulated request already failed once (so Retry works).
  final Set<String> _simulatedFailures = <String>{};

  List<Variety> varieties({bool onlyActive = true}) =>
      _varieties.where((v) => !onlyActive || v.active).toList(growable: false);

  Future<List<Variety>> fetchVarieties() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return varieties(onlyActive: false);
  }

  Future<Variety> addVariety(String name, String description) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_varieties.any((v) => v.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('duplicate_variety');
    }
    final v = Variety(id: 'v${DateTime.now().millisecondsSinceEpoch}', name: name, description: description);
    _varieties.add(v);
    revision.value++;
    return v;
  }

  Future<Variety> updateVariety(String id, {String? name, String? description, bool? active}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _varieties.indexWhere((v) => v.id == id);
    if (idx < 0) throw Exception('not_found');
    final updated = _varieties[idx].copyWith(name: name, description: description, active: active);
    _varieties[idx] = updated;
    revision.value++;
    return updated;
  }

  /// Mock image classifier.
  ///
  /// Request flow:  IDLE ──▶ LOADING ──┬──▶ SUCCESS
  ///                                  ├──▶ EMPTY
  ///                                  └──▶ ERROR ──▶ RETRY
  ///
  /// * returns a [Prediction] → SUCCESS
  /// * returns `null`         → EMPTY (no coconut detected)
  /// * throws                 → ERROR  (the caller offers Retry)
  ///
  /// The mock needs a deterministic way to reach every branch, so a file name
  /// containing "empty", "blank" or "none" simulates a photo with no coconut,
  /// and a name containing "error" or "fail" simulates a failed request. That
  /// request fails only on its first attempt, so tapping Retry recovers.
  Future<Prediction?> classifyImage(String fileName) async {
    await Future.delayed(const Duration(seconds: 2));
    final name = fileName.toLowerCase();
    if (name.contains('error') || name.contains('fail')) {
      if (_simulatedFailures.add(fileName)) {
        throw Exception('503 service_unavailable');
      }
    }
    final active = _varieties.where((x) => x.active).toList();
    if (active.isEmpty) return null; // nothing to match against → EMPTY
    if (name.contains('empty') ||
        name.contains('blank') ||
        name.contains('none')) {
      return null; // no coconut in the photo → EMPTY
    }
    final variety = active[fileName.length % active.length].name;
    final conf = 0.72 + (fileName.length % 20) / 100.0;
    final p = Prediction(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      userId: AuthController.instance.user.value!.id,
      variety: variety,
      confidence: conf.clamp(0.5, 0.99),
      createdAt: DateTime.now(),
    );
    _predictions.insert(0, p);
    revision.value++;
    return p;
  }

  Future<List<Prediction>> fetchHistory({String? filter}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final uid = AuthController.instance.user.value!.id;
    var list = _predictions.where((p) => p.userId == uid).toList();
    if (filter != null && filter.isNotEmpty && filter != 'All') {
      list = list.where((p) => p.variety == filter).toList();
    }
    return list;
  }

  Prediction? findPrediction(String id) {
    try {
      return _predictions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, int> stats(DateTime from, DateTime to) {
    final filtered = _predictions.where((p) {
      return !p.createdAt.isBefore(from) && !p.createdAt.isAfter(to.add(const Duration(days: 1)));
    }).toList();
    final counts = <String, int>{};
    for (final p in filtered) {
      final v = p.variety ?? 'Unknown';
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String, dynamic>> health() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {'api': 'OK', 'model': 'OK', 'lastChecked': DateTime.now()};
  }
}
