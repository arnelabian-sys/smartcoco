import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../widgets/app_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Soft dark halo behind all settings text so it stays readable
  /// over the background image.
  static const List<Shadow> _shadows = [
    Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2)),
    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
  ];

  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _currentPassCtl = TextEditingController();
  final TextEditingController _newPassCtl = TextEditingController();
  final TextEditingController _confirmPassCtl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _profileMsg;
  String? _profileErr;
  String? _passwordMsg;
  String? _passwordErr;

  @override
  void initState() {
    super.initState();
    final user = AuthController.instance.user.value;
    _nameCtl.text = user?.name ?? '';
    _emailCtl.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _currentPassCtl.dispose();
    _newPassCtl.dispose();
    _confirmPassCtl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileMsg = null;
      _profileErr = null;
    });
    try {
      await AuthController.instance.updateProfile(
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
      );
      if (mounted) {
        setState(() => _profileMsg = 'Profile updated successfully.');
      }
    } catch (_) {
      if (mounted) setState(() => _profileErr = 'Could not update profile.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _savingPassword = true;
      _passwordMsg = null;
      _passwordErr = null;
    });
    try {
      await AuthController.instance.changePassword(
        currentPassword: _currentPassCtl.text,
        newPassword: _newPassCtl.text,
      );
      _currentPassCtl.clear();
      _newPassCtl.clear();
      _confirmPassCtl.clear();
      if (mounted) setState(() => _passwordMsg = 'Password updated successfully.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _passwordErr = e.toString().contains('wrong_password')
              ? 'Current password is incorrect.'
              : e.toString().contains('weak_password')
                  ? 'New password must be at least 8 characters.'
                  : e.toString().contains('mismatch_password')
                      ? 'New passwords do not match.'
                      : 'Could not update password.';
        });
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: '/settings',
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black54,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        shadows: _shadows,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your account and security preferences.',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, shadows: _shadows),
                    ),
                    const SizedBox(height: 20),
                    _glassCard(
                      child: _seeProfileSection(),
                    ),
                    const SizedBox(height: 16),
                    _glassCard(
                      child: _editProfileSection(),
                    ),
                    const SizedBox(height: 16),
                    _glassCard(
                      child: _loginSecuritySection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- See profile ----------------
  Widget _seeProfileSection() {
    final user = AuthController.instance.user.value;
    final initials = user == null
        ? '?'
        : (user.name.trim().isEmpty
            ? '?'
            : user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase());

    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('See profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, shadows: _shadows)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withOpacity(0.22),
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Not signed in',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, shadows: _shadows),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, shadows: _shadows),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(user?.roleLabel ?? 'Guest'),
                        _chip(user == null ? '' : 'ID: ${user.id}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Edit profile ----------------
  Widget _editProfileSection() {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, shadows: _shadows)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_profileMsg != null) ...[
                _inlineBanner(_profileMsg!, success: true),
                const SizedBox(height: 12),
              ],
              if (_profileErr != null) ...[
                _inlineBanner(_profileErr!, success: false),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _nameCtl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Full name', Icons.badge_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('E-mail address', Icons.mail_outline),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                onPressed: _savingProfile ? null : _saveProfile,
                icon: _savingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_savingProfile ? 'Saving…' : 'Save changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Login and Security ----------------
  Widget _loginSecuritySection() {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Login and Security', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, shadows: _shadows)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_passwordMsg != null) ...[
                _inlineBanner(_passwordMsg!, success: true),
                const SizedBox(height: 12),
              ],
              if (_passwordErr != null) ...[
                _inlineBanner(_passwordErr!, success: false),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _currentPassCtl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Current password', Icons.key_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassCtl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('New password (min. 8 characters)', Icons.lock_reset),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassCtl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Confirm new password', Icons.lock_reset_outlined),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                onPressed: _savingPassword ? null : _savePassword,
                icon: _savingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                      )
                    : const Icon(Icons.shield_outlined, size: 18),
                label: Text(_savingPassword ? 'Updating…' : 'Update password'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- helpers ----------------
  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: child,
    );
  }

  Widget _chip(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: _shadows)),
    );
  }

  Widget _inlineBanner(String message, {required bool success}) {
    final color = success ? Colors.greenAccent : Colors.redAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle_outline : Icons.error_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: Colors.white, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.6),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
    );
  }
}
