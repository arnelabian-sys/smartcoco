import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  final String? returnTo;
  const LoginScreen({super.key, this.returnTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _submitting = false;
  String? _banner;
  String? _passError;
  bool _showMsgHandled = false;
  bool _remember = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showMsgHandled) return;
    _showMsgHandled = true;
    final uri = Uri.tryParse(ModalRoute.of(context)?.settings.name ?? '');
    final msg = uri?.queryParameters['msg'];
    if (msg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      });
    }
  }

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
      await AuthController.instance.login(_emailCtl.text.trim(), _passCtl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.returnTo ?? '/dashboard');
    } catch (e) {
      final msg = e.toString();
      if (!mounted) return;
      if (msg.contains('account_disabled') || msg.contains('403')) {
        setState(() => _banner = 'This account is disabled. Contact the administrator.');
      } else {
        // Wrong e-mail or password: warn on the password box only, then clear
        // it and focus it so the user can type the password again.
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
      prefixIcon: icon != null ? Icon(icon, color: AppColors.grey800) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rightSide = width >= 740;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: Image(image: AssetImage('assets/images/smartcoco_background.png'), fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(color: Colors.black38),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: rightSide ? const Alignment(0.60, 0) : Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.eco, color: AppColors.primary, size: 30),
                                  SizedBox(width: 8),
                                  Text('SmartCoco', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Welcome back', style: Theme.of(context).textTheme.headlineLarge),
                              const SizedBox(height: 2),
                              Text('Sign in to classify coconut varieties and access history.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey800)),
                              const SizedBox(height: 18),
                              if (_banner != null) ...[
                                Text(_banner!, style: const TextStyle(color: AppColors.error)),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailCtl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _dec('Email', icon: Icons.mail_outline),
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.isEmpty) return 'Enter your e-mail.';
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Enter a valid e-mail.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtl,
                                focusNode: _passFocus,
                                obscureText: _obscure,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: _dec(
                                  'Password',
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (_passError != null) {
                                    setState(() => _passError = null);
                                  }
                                },
                                validator: (v) {
                                  // A rejected password keeps its warning until
                                  // the user starts typing again.
                                  if (_passError != null) return _passError;
                                  if (v == null || v.isEmpty) return 'Enter your password.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false)),
                                  const Expanded(child: Text('Remember me', style: TextStyle(fontSize: 13))),
                                  TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon: password reset via e-mail'))), child: const Text('Forgot?')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: _submitting ? null : _submit,
                                  child: _submitting
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Log in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: const [
                                  Expanded(child: Divider()),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or', style: TextStyle(fontSize: 12, color: AppColors.grey800))),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in placeholder'))),
                                  icon: const Icon(Icons.g_mobiledata, size: 22),
                                  label: const Text('Continue with Google'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple sign-in placeholder'))),
                                  icon: const Icon(Icons.apple, size: 22),
                                  label: const Text('Continue with Apple'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                child: const Text('New here? Create an account'),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                                child: const Text('Demo: user@smartcoco.ph / User1234   or   admin@smartcoco.ph / Admin123', style: TextStyle(fontSize: 11, color: AppColors.grey800), textAlign: TextAlign.center),
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
        ],
      ),
    );
  }
}







