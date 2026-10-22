import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  final ValueNotifier<AppUser?> user = ValueNotifier<AppUser?>(null);
  String? token;

  bool get isLoggedIn => user.value != null;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (email == 'admin@smartcoco.ph' && password == 'Admin123') {
      user.value = const AppUser(id: 'u_admin', name: 'Admin User', email: 'admin@smartcoco.ph', role: 'admin');
      token = 'tok_admin';
      return;
    }
    if (email == 'researcher@smartcoco.ph' && password == 'Research123') {
      user.value = const AppUser(id: 'u_res', name: 'Researcher User', email: 'researcher@smartcoco.ph', role: 'researcher');
      token = 'tok_res';
      return;
    }
    if (email == 'user@smartcoco.ph' && password == 'User1234') {
      user.value = const AppUser(id: 'u_user', name: 'Registered User', email: 'user@smartcoco.ph', role: 'user');
      token = 'tok_user';
      return;
    }
    throw Exception('invalid_credentials');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    DateTime? birthday,
    String? gender,
    String? role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (email == 'taken@smartcoco.ph') {
      throw Exception('duplicate_email');
    }
    user.value = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: (role == null || role.isEmpty) ? 'user' : role,
      firstName: firstName,
      lastName: lastName,
      birthday: birthday,
      gender: gender,
    );
    token = 'tok_new';
  }

  Future<void> updateProfile({required String name, required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final u = user.value;
    if (u == null) throw Exception('not_logged_in');
    if (name.isEmpty || email.isEmpty) throw Exception('invalid_profile');
    user.value = AppUser(
      id: u.id,
      name: name,
      email: email,
      role: u.role,
      firstName: u.firstName,
      lastName: u.lastName,
      birthday: u.birthday,
      gender: u.gender,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final u = user.value;
    if (u == null) throw Exception('not_logged_in');
    if (currentPassword.isEmpty) throw Exception('wrong_password');
    if (newPassword.length < 8) throw Exception('weak_password');
    if (confirmPassword != null && confirmPassword != newPassword) {
      throw Exception('mismatch_password');
    }
    // Mock: verify the current password against the demo accounts when the
    // e-mail matches one of them, otherwise accept any non-empty password.
    const demo = {
      'admin@smartcoco.ph': 'Admin123',
      'researcher@smartcoco.ph': 'Research123',
      'user@smartcoco.ph': 'User1234',
    };
    if (demo.containsKey(u.email) && demo[u.email] != currentPassword) {
      throw Exception('wrong_password');
    }
  }

  void logout() {
    user.value = null;
    token = null;
  }
}
