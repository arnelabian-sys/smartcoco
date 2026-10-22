import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../services/data_store.dart';
import '../screens/landing_screen.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/upload_screen.dart';
import '../screens/result_screen.dart';
import '../screens/history_screen.dart';
import '../screens/history_detail_screen.dart';
import '../screens/varieties_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/admin_varieties_screen.dart';
import '../screens/admin_status_screen.dart';
import '../screens/not_found_screen.dart';

Route<dynamic> _page(Widget w, {String? name}) =>
    MaterialPageRoute(builder: (_) => w, settings: RouteSettings(name: name));

Route<dynamic> generateRoute(RouteSettings settings) {
  final raw = settings.name ?? '/';
  final uri = Uri.parse(raw.isEmpty ? '/' : raw);
  String path = uri.path;
  if (path.isEmpty) path = '/';

  if (path == '/landing') return _page(const LandingScreen(), name: path);
  if (path == '/' || path == '/home') return _page(const HomeScreen(), name: path);
  if (path == '/register') return _page(const RegisterScreen(), name: path);
  if (path == '/login') {
    final returnTo = uri.queryParameters['returnTo'];
    return _page(LoginScreen(returnTo: returnTo), name: path);
  }

  final user = AuthController.instance.user.value;
  if (user == null) {
    return _page(LoginScreen(returnTo: path), name: '/login');
  }

  if (path == '/dashboard') return _page(const DashboardScreen(), name: path);
  if (path == '/settings') return _page(const SettingsScreen(), name: path);
  if (path == '/home') return _page(const HomeScreen(), name: path);
  if (path == '/classify') return _page(const UploadScreen(), name: path);

  final resultMatch = RegExp(r'^/classify/result/([^/]+)$').firstMatch(path);
  if (resultMatch != null) {
    final id = resultMatch.group(1)!;
    final pred = DataStore.instance.findPrediction(id);
    if (pred == null) return _page(const NotFoundScreen(), name: path);
    if (pred.userId != user.id && !user.isAdmin) return _page(const ForbiddenScreen(), name: path);
    return _page(ResultScreen(id: id), name: path);
  }

  if (path == '/history') return _page(const HistoryScreen(), name: path);

  final histMatch = RegExp(r'^/history/([^/]+)$').firstMatch(path);
  if (histMatch != null) {
    final id = histMatch.group(1)!;
    final pred = DataStore.instance.findPrediction(id);
    if (pred == null) return _page(const NotFoundScreen(), name: path);
    if (pred.userId != user.id && !user.isAdmin) return _page(const ForbiddenScreen(), name: path);
    return _page(HistoryDetailScreen(id: id), name: path);
  }

  if (path == '/varieties') return _page(const VarietiesScreen(), name: path);

  if (path == '/stats') {
    if (user.role != 'researcher') return _page(const ForbiddenScreen(), name: path);
    return _page(const StatisticsScreen(), name: path);
  }

  if (path == '/admin/varieties') {
    if (user.role != 'admin') return _page(const ForbiddenScreen(), name: path);
    return _page(const AdminVarietiesScreen(), name: path);
  }

  if (path == '/admin/status') {
    if (user.role != 'admin') return _page(const ForbiddenScreen(), name: path);
    return _page(const AdminStatusScreen(), name: path);
  }

  return _page(const NotFoundScreen(), name: path);
}

// re-export so app.dart can use _page if needed (not necessary)
