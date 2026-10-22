import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Keys used to scroll to (trace) the first field that is missing input.
  final _firstKey = GlobalKey();
  final _lastKey = GlobalKey();
  final _monthKey = GlobalKey();
  final _dayKey = GlobalKey();
  final _yearKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passKey = GlobalKey();
  final _confirmKey = GlobalKey();

  final _firstCtl = TextEditingController();
  final _lastCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  // Dropdown selections (null = not chosen yet).
  int? _month;
  int? _day;
  int? _year;
  String? _gender;
  String? _role;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _agreeTerms = false;
  bool _success = false;
  String? _banner;

  static const _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _genders = <String>[
    'Male', 'Female', 'Other', 'Prefer not to say',
  ];

  static const _roles = <String>[
    'Student', 'Farmer', 'Agriculturist',
  ];

  List<int> get _years {
    final now = DateTime.now().year;
    return List<int>.generate(now - 1949, (i) => now - i);
  }

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Trace: scroll to the first field that has no input.
      _scrollToFirstError();
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please accept the terms to continue.')));
      return;
    }
    setState(() {
      _submitting = true;
      _banner = null;
    });
    try {
      final first = _firstCtl.text.trim();
      final last = _lastCtl.text.trim();
      await AuthController.instance.register(
        name: '$first $last'.trim(),
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
        firstName: first,
        lastName: last,
        birthday: DateTime(_year!, _month!, _day!),
        gender: _gender,
        role: switch (_role) {
          'Student' => 'student',
          'Farmer' => 'farmer',
          'Agriculturist' => 'agriculturist',
          _ => 'user',
        },
      );
      if (!mounted) return;
      // Success state: "Registration successful! You can now log in."
      setState(() {
        _success = true;
      });
    } catch (e) {
      setState(() {
        _banner = e.toString().contains('duplicate_email')
            ? 'This e-mail is already registered. Log in instead.'
            : 'Could not create account. Try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ------------------------------------------------------------------
  // Trace: find the first field that is missing input and scroll to it.
  // ------------------------------------------------------------------
  List<GlobalKey> get _orderedKeys => [
        _firstKey,
        _lastKey,
        _monthKey,
        _dayKey,
        _yearKey,
        _emailKey,
        _passKey,
        _confirmKey,
      ];

  FormFieldState<dynamic>? _stateOf(BuildContext ctx) {
    FormFieldState<dynamic>? found;
    void walk(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is FormFieldState) {
        found = element.state as FormFieldState;
        return;
      }
      element.visitChildElements(walk);
    }
    walk(ctx as Element);
    return found;
  }

  void _scrollToFirstError() {
    for (final key in _orderedKeys) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final state = _stateOf(ctx);
      if (state != null && state.hasError) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.30,
        );
        return;
      }
    }
  }

  // ------------------------------------------------------------------
  // Validators
  // ------------------------------------------------------------------
  static const _requiredMsg = 'This field is required.';

  String? _firstValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return _requiredMsg;
    if (value.length < 2) return 'Too short';
    if (!RegExp(r"^[A-Za-z .'\-]+$").hasMatch(value)) return 'Letters only';
    return null;
  }

  String? _lastValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return _requiredMsg;
    if (value.length < 2) return 'Too short';
    if (!RegExp(r"^[A-Za-z .'\-]+$").hasMatch(value)) return 'Letters only';
    return null;
  }

  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return _requiredMsg;
    if (value.length > 100) return 'Enter a valid e-mail, e.g. name@example.com.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid e-mail, e.g. name@example.com.';
    }
    return null;
  }

  String? _passValidator(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return _requiredMsg;
    if (value.length < 8) return 'Use at least 8 characters with a letter and a number.';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use at least 8 characters with a letter and a number.';
    }
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return _requiredMsg;
    if (v != _passCtl.text) return 'Passwords do not match.';
    return null;
  }

  /// Checks that the chosen day actually exists in the chosen month/year.
  String? _dayValidator(int? day) {
    if (day == null) return _requiredMsg;
    final m = _month;
    final y = _year;
    if (m == null || y == null) return null;
    final lastDay = DateTime(y, m + 1, 0).day;
    if (day > lastDay) return 'Invalid date';
    return null;
  }

  String? _requiredSelect(Object? v) => (v == null) ? _requiredMsg : null;

  // ------------------------------------------------------------------
  // Decoration helpers
  // ------------------------------------------------------------------
  InputDecoration _dec(String hint, {Widget? suffix, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(fontSize: 11, height: 1.1),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );

  List<DropdownMenuItem<int>> _dayItems() => [
        for (int d = 1; d <= 31; d++)
          DropdownMenuItem<int>(value: d, child: Text('$d')),
      ];

  /// Shown after a successful registration.
  Widget _successPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.eco, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('SmartCoco',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 18),
              const Text(
                'Registration successful! You can now log in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Log in',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rightSide = width >= 740;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/smartcoco_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black38,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: rightSide ? const Alignment(0.60, 0) : Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(28),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                        ),
                        child: _success ? _successPanel() : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ---------------- brand + heading --------------
                                Row(
                                  children: const [
                                    Icon(Icons.eco, color: AppColors.primary, size: 28),
                                    SizedBox(width: 8),
                                    Text('SmartCoco',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Register',
                                    style: Theme.of(context).textTheme.headlineLarge),
                                if (_banner != null) ...[
                                  const SizedBox(height: 10),
                                  Text(_banner!,
                                      style: const TextStyle(color: AppColors.error)),
                                ],
                                const SizedBox(height: 18),

                                // ---------------- Name ----------------------
                                _label('Name'),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        key: _firstKey,
                                        controller: _firstCtl,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: _dec('First name'),
                                        validator: _firstValidator,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        key: _lastKey,
                                        controller: _lastCtl,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: _dec('Last name'),
                                        validator: _lastValidator,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Birthday ------------------
                                _label('Birthday'),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: DropdownButtonFormField<int>(
                                        key: _monthKey,
                                        initialValue: _month,
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        hint: const Text('Month'),
                                        items: [
                                          for (int i = 0; i < _months.length; i++)
                                            DropdownMenuItem<int>(
                                                value: i + 1, child: Text(_months[i])),
                                        ],
                                        onChanged: (v) => setState(() {
                                          _month = v;
                                          _day = null;
                                        }),
                                        decoration: _dec(''),
                                        validator: (v) => _requiredSelect(v),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<int>(
                                        key: _dayKey,
                                        initialValue: _day,
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        hint: const Text('Day'),
                                        items: _dayItems(),
                                        onChanged: (v) => setState(() => _day = v),
                                        decoration: _dec(''),
                                        validator: _dayValidator,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 4,
                                      child: DropdownButtonFormField<int>(
                                        key: _yearKey,
                                        initialValue: _year,
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        hint: const Text('Year'),
                                        items: [
                                          for (final y in _years)
                                            DropdownMenuItem<int>(value: y, child: Text('$y')),
                                        ],
                                        onChanged: (v) => setState(() => _year = v),
                                        decoration: _dec(''),
                                        validator: (v) => _requiredSelect(v),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Gender --------------------
                                _label('Gender'),
                                DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  hint: const Text('Select gender (Optional)'),
                                  items: [
                                    for (final g in _genders)
                                      DropdownMenuItem<String>(value: g, child: Text(g)),
                                  ],
                                  onChanged: (v) => setState(() => _gender = v),
                                  decoration: _dec(''),
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Role ----------------------
                                _label('Role'),
                                DropdownButtonFormField<String>(
                                  initialValue: _role,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  hint: const Text('Select role'),
                                  items: [
                                    for (final r in _roles)
                                      DropdownMenuItem<String>(value: r, child: Text(r)),
                                  ],
                                  onChanged: (v) => setState(() => _role = v),
                                  decoration: _dec(''),
                                  validator: (v) => _requiredSelect(v),
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Email ---------------------
                                _label('Email'),
                                TextFormField(
                                  key: _emailKey,
                                  controller: _emailCtl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _dec('name@example.com'),
                                  validator: _emailValidator,
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Password ------------------
                                _label('Password'),
                                TextFormField(
                                  key: _passKey,
                                  controller: _passCtl,
                                  obscureText: _obscurePass,
                                  decoration: _dec(
                                    'Password (at least 8 characters)',
                                    suffix: IconButton(
                                      tooltip: _obscurePass ? 'Show' : 'Hide',
                                      icon: Icon(
                                          _obscurePass
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 20),
                                      onPressed: () =>
                                          setState(() => _obscurePass = !_obscurePass),
                                    ),
                                  ),
                                  validator: _passValidator,
                                ),
                                const SizedBox(height: 16),

                                // ---------------- Confirm password ---------
                                _label('Confirm password'),
                                TextFormField(
                                  key: _confirmKey,
                                  controller: _confirmCtl,
                                  obscureText: _obscureConfirm,
                                  decoration: _dec(
                                    'Re-enter your password',
                                    suffix: IconButton(
                                      tooltip: _obscureConfirm ? 'Show' : 'Hide',
                                      icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 20),
                                      onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  validator: _confirmValidator,
                                ),
                                const SizedBox(height: 10),

                                // ---------------- Terms ----------------------
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: _agreeTerms,
                                      activeColor: AppColors.primary,
                                      onChanged: (v) =>
                                          setState(() => _agreeTerms = v ?? false),
                                    ),
                                    const Expanded(
                                      child: Text('I agree to Terms and Privacy',
                                          style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // ---------------- Submit ---------------------
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _submitting ? null : _submit,
                                    child: _submitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2))
                                        : const Text('Register',
                                            style: TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text('Already have an account? Log in'),
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
        ),
      ),
    );
  }
}
