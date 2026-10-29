import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/auth_controller.dart';
import '../theme.dart';

/// Separate sign-in page for the System Administrator.
///
/// Kept apart from the regular [LoginScreen] so the two roles never share a
/// form. Reachable at `/admin/login` (link at the bottom of the user login) and
/// used automatically when a signed-out visitor opens an `/admin/...` route.
class AdminLoginScreen extends StatefulWidget {
  final String? returnTo;

  const AdminLoginScreen({super.key, this.returnTo});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  String? _banner;
  String? _passError;

  static const Color _mint = Color(0xFFB9F6CA);

  /// Green used by the glass card (standard green, not deep forest).
  static const Color _cardGreen = Color(0xFF2E7D32);

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _banner = null;
      _passError = null;
    });
    try {
      await AuthController.instance.loginAsAdmin(
        _emailCtl.text.trim(),
        _passCtl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        widget.returnTo ?? '/admin/varieties',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('network_error') || msg.contains('timeout')) {
        setState(() {
          _banner =
              "Can't reach the server. Start the SmartCoco API and try again.";
          _passError = null;
        });
      } else if (msg.contains('not_administrator')) {
        setState(() {
          _banner = 'This account is not an administrator. Use the user login instead.';
          _passError = null;
        });
        _passCtl.clear();
        _formKey.currentState?.validate();
      } else {
        setState(() {
          _banner = null;
          _passError = 'Incorrect password. Please try again.';
        });
        _passCtl.clear();
        _formKey.currentState?.validate();
        _passFocus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _dec(String label, {Widget? suffix, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      // Resting label: dark enough to read on the white input.
      labelStyle: const TextStyle(
        color: Color(0xFF3E5648),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      // Floating label: bigger, bolder, dark green, with a white chip behind
      // it so it never blends into the border or the green card.
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF1B5E20),
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        backgroundColor: Colors.white,
        height: 1.1,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF1B5E20))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        gapPadding: 6,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        gapPadding: 6,
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rightSide = size.width >= 740;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/homepage_background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.52),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: rightSide
                    ? const Alignment(0.60, 0)
                    : Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 430,
                    maxHeight: size.height - 24,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: _cardGreen.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    // Shield badge: soft white gradient tile,
                                    // dark-green shield and a small verified
                                    // check bubble so it reads as "secure".
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            Color(0xFFDCEEDF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.28,
                                            ),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                          BoxShadow(
                                            color: _mint.withValues(
                                              alpha: 0.22,
                                            ),
                                            blurRadius: 18,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(
                                            Icons.shield_outlined,
                                            color: Color(0xFF1B5E20),
                                            size: 30,
                                          ),
                                          Positioned(
                                            right: 5,
                                            bottom: 5,
                                            child: Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2E7D32),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.6,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 9,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SMARTCOCO',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'System Administrator',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Admin Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Restricted access. Sign in with your administrator account.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                if (_banner != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF8A80)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFF8A80)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: Color(0xFFFFCDD2),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _banner!,
                                            style: const TextStyle(
                                              color: Color(0xFFFFCDD2),
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/login',
                                          ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _mint,
                                      ),
                                      child: const Text('Go to user login'),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                TextFormField(
                                  controller: _emailCtl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  // Enter jumps to the password box.
                                  onFieldSubmitted: (_) =>
                                      _passFocus.requestFocus(),
                                  // Black text so what you type is easy to read.
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: Colors.black,
                                  decoration: _dec(
                                    'Admin e-mail',
                                    icon: Icons.mail_outline,
                                  ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) return 'Enter your e-mail.';
                                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(t)) {
                                      return 'Enter a valid e-mail.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passCtl,
                                  focusNode: _passFocus,
                                  obscureText: _obscure,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  textInputAction: TextInputAction.done,
                                  // Enter submits the admin form.
                                  onFieldSubmitted: (_) {
                                    if (!_submitting) _submit();
                                  },
                                  // Black text (and cursor) as soon as the field
                                  // is focused, so the entry is clearly visible.
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: Colors.black,
                                  decoration: _dec(
                                    'Password',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  onChanged: (_) {
                                    if (_passError != null) {
                                      setState(() => _passError = null);
                                    }
                                  },
                                  validator: (v) {
                                    if (_passError != null) return _passError;
                                    if (v == null || v.isEmpty) {
                                      return 'Enter your password.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: _cardGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _submitting ? null : _submit,
                                    child: _submitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _cardGreen,
                                            ),
                                          )
                                        : const Text(
                                            'Log in to console',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Back to user login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
