// register_screen.dart — Laravel auth card design
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/auth_flow_mode.dart';
import '../models/user_role.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import 'client/client_navigation_screen.dart';
import 'freelancer/freelancer_navigation_screen.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

// ── Tokens ───────────────────────────────────────────────────────────────────
const _deepGreen  = Color(0xFF1A5C3A);
const _midGreen   = Color(0xFF2D7A52);
const _brightGreen= Color(0xFF3DA668);
const _lightGreen = Color(0xFFE8F5EE);
const _paleGreen  = Color(0xFFF0FAF4);
const _charcoal   = Color(0xFF1C1F1E);
const _slate      = Color(0xFF4A5550);
const _mist       = Color(0xFF8FA89E);
const _border     = Color(0xFFD6E8DE);
const _danger     = Color(0xFFDC2626);
const _dangerBg   = Color(0xFFFEF2F2);

class RegisterScreen extends StatefulWidget {
  final UserRole selectedRole;
  const RegisterScreen({super.key, required this.selectedRole});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _auth         = AuthService();

  final _nameFN     = FocusNode();
  final _emailFN    = FocusNode();
  final _usernameFN = FocusNode();
  final _phoneFN    = FocusNode();
  final _passFN     = FocusNode();
  final _confirmFN  = FocusNode();

  bool _obscure     = true;
  bool _obscureConf = true;
  bool _loading     = false;
  bool _agreeTerms  = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  bool get _isClient => widget.selectedRole == UserRole.client;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _fade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    for (final c in [_nameCtrl, _emailCtrl, _usernameCtrl, _phoneCtrl,
      _passCtrl, _confirmCtrl]) c.dispose();
    for (final f in [_nameFN, _emailFN, _usernameFN, _phoneFN,
      _passFN, _confirmFN]) f.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      setState(() => _error = 'Kamu harus menyetujui syarat & ketentuan.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    HapticFeedback.lightImpact();

    final authProv = context.read<AuthProvider>();
    final ok = await authProv.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
      role: widget.selectedRole.name,
      username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => _isClient
              ? const ClientNavigationScreen()
              : const FreelancerNavigationScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c)),
        (r) => false);
    } else {
      HapticFeedback.heavyImpact();
      setState(() { _loading = false; _error = authProv.error ?? 'Registrasi gagal.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleGreen,
      body: Stack(children: [
        // ── Orbs ─────────────────────────────────────────────
        Positioned(top: -120, right: -80,
          child: Container(width: 380, height: 380,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _brightGreen.withOpacity(0.12), Colors.transparent])))),
        Positioned(bottom: -80, left: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _deepGreen.withOpacity(0.08), Colors.transparent])))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(children: [
              // ── Top bar ──────────────────────────────────────
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border)),
                    child: const Icon(Icons.arrow_back_rounded,
                      color: _charcoal, size: 18)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_isClient ? '👤' : '💼',
                      style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(_isClient ? 'Client' : 'Freelancer',
                      style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600, color: _midGreen)),
                  ]),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Auth Card ─────────────────────────────────────
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.07),
                          blurRadius: 32, offset: const Offset(0, 8)),
                        BoxShadow(color: Colors.black.withOpacity(0.03),
                          blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Logo
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _deepGreen,
                              borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Text('S', style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: Colors.white, fontStyle: FontStyle.italic)))),
                          const SizedBox(width: 9),
                          const Text('SkillBantuin', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal)),
                        ]),

                        const SizedBox(height: 22),

                        const Text('Bergabung Gratis', style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w500,
                          color: _charcoal, letterSpacing: -0.5, height: 1.2)),
                        const SizedBox(height: 6),
                        const Text('Buat akun dan temukan peluang karir terbaikmu.',
                          style: TextStyle(fontSize: 14, color: _slate, height: 1.4)),

                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        // Fields
                        _FL('Nama Lengkap *'),
                        const SizedBox(height: 6),
                        _CF(ctrl: _nameCtrl, fn: _nameFN,
                          hint: 'Budi Santoso',
                          action: TextInputAction.next,
                          onNext: () => FocusScope.of(context).requestFocus(_emailFN),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null),

                        const SizedBox(height: 14),
                        _FL('Email *'),
                        const SizedBox(height: 6),
                        _CF(ctrl: _emailCtrl, fn: _emailFN,
                          hint: 'nama@email.com',
                          keyboard: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          onNext: () => FocusScope.of(context).requestFocus(_usernameFN),
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Email wajib diisi';
                            if (!v!.contains('@')) return 'Format tidak valid';
                            return null;
                          }),

                        const SizedBox(height: 14),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const _FL('Username'),
                            const SizedBox(height: 6),
                            _CF(ctrl: _usernameCtrl, fn: _usernameFN,
                              hint: 'budi_s',
                              action: TextInputAction.next,
                              onNext: () => FocusScope.of(context).requestFocus(_phoneFN)),
                          ])),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const _FL('No. HP'),
                            const SizedBox(height: 6),
                            _CF(ctrl: _phoneCtrl, fn: _phoneFN,
                              hint: '08xxxxxx',
                              keyboard: TextInputType.phone,
                              action: TextInputAction.next,
                              onNext: () => FocusScope.of(context).requestFocus(_passFN)),
                          ])),
                        ]),

                        const SizedBox(height: 14),
                        _FL('Password *'),
                        const SizedBox(height: 6),
                        _CF(ctrl: _passCtrl, fn: _passFN,
                          hint: 'Min. 8 karakter',
                          obscure: _obscure,
                          action: TextInputAction.next,
                          onNext: () => FocusScope.of(context).requestFocus(_confirmFN),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Wajib diisi';
                            if ((v?.length ?? 0) < 8) return 'Min. 8 karakter';
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, color: _mist, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure))),

                        const SizedBox(height: 14),
                        _FL('Konfirmasi Password *'),
                        const SizedBox(height: 6),
                        _CF(ctrl: _confirmCtrl, fn: _confirmFN,
                          hint: 'Ulangi password',
                          obscure: _obscureConf,
                          action: TextInputAction.done,
                          onSubmit: (_) => _register(),
                          validator: (v) => v != _passCtrl.text
                              ? 'Password tidak cocok' : null,
                          suffix: IconButton(
                            icon: Icon(_obscureConf
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, color: _mist, size: 18),
                            onPressed: () => setState(() => _obscureConf = !_obscureConf))),

                        const SizedBox(height: 18),

                        // Terms checkbox
                        GestureDetector(
                          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(top: 1),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: _agreeTerms ? _deepGreen : Colors.white,
                                border: Border.all(
                                  color: _agreeTerms ? _deepGreen : _border,
                                  width: 1.5)),
                              child: _agreeTerms
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 13)
                                  : null),
                            const SizedBox(width: 10),
                            Expanded(child: Text.rich(TextSpan(children: [
                              const TextSpan(text: 'Saya setuju dengan ',
                                style: TextStyle(fontSize: 13.5, color: _slate)),
                              const TextSpan(text: 'Syarat & Ketentuan',
                                style: TextStyle(fontSize: 13.5,
                                  fontWeight: FontWeight.w600, color: _deepGreen)),
                              const TextSpan(text: ' dan ',
                                style: TextStyle(fontSize: 13.5, color: _slate)),
                              const TextSpan(text: 'Kebijakan Privasi',
                                style: TextStyle(fontSize: 13.5,
                                  fontWeight: FontWeight.w600, color: _deepGreen)),
                              const TextSpan(text: ' SkillBantuin.',
                                style: TextStyle(fontSize: 13.5, color: _slate)),
                            ]))),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        // CTA
                        _PillButton(
                          label: 'Daftar Sekarang',
                          loading: _loading,
                          onTap: _register,
                        ),

                        const SizedBox(height: 18),

                        // Footer
                        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Sudah punya akun? ',
                            style: TextStyle(fontSize: 14, color: _slate)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                  LoginScreen(selectedRole: widget.selectedRole),
                                transitionDuration: const Duration(milliseconds: 350),
                                transitionsBuilder: (_, a, __, c) =>
                                  FadeTransition(opacity: a, child: c))),
                            child: const Text('Masuk di sini', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: _deepGreen))),
                        ])),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Compact field widgets ────────────────────────────────────────────────────

class _FL extends StatelessWidget {
  final String text;
  const _FL(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _charcoal));
}

class _CF extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode fn;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onNext;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const _CF({required this.ctrl, required this.fn, required this.hint,
    this.obscure = false, this.keyboard, this.action, this.onSubmit,
    this.onNext, this.validator, this.suffix});
  @override
  State<_CF> createState() => _CFState();
}

class _CFState extends State<_CF> {
  bool _f = false;
  @override
  void initState() { super.initState(); widget.fn.addListener(_l); }
  @override
  void dispose() { widget.fn.removeListener(_l); super.dispose(); }
  void _l() => setState(() => _f = widget.fn.hasFocus);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _f ? const Color(0xFFF0FAF4) : const Color(0xFFF7FAF8),
      border: Border.all(color: _f ? _deepGreen : _border, width: _f ? 1.5 : 1.0),
      boxShadow: _f
          ? [BoxShadow(color: _deepGreen.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
          : [],
    ),
    child: TextFormField(
      controller: widget.ctrl, focusNode: widget.fn,
      obscureText: widget.obscure, keyboardType: widget.keyboard,
      textInputAction: widget.action, onFieldSubmitted: widget.onSubmit,
      onEditingComplete: widget.onNext, validator: widget.validator,
      style: const TextStyle(fontSize: 15, color: _charcoal),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: _mist, fontSize: 14),
        suffixIcon: widget.suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
    ),
  );
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        color: loading ? _midGreen.withOpacity(0.7) : _deepGreen,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(
          color: _deepGreen.withOpacity(0.22),
          blurRadius: 14, offset: const Offset(0, 5))]),
      child: Center(child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _dangerBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _danger.withOpacity(0.25))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: _danger, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
        style: const TextStyle(fontSize: 13, color: _danger))),
    ]),
  );
}
