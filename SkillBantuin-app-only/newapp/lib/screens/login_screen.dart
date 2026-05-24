// login_screen.dart — Laravel auth card design: white card, pale green bg
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/auth_flow_mode.dart';
import '../models/user_role.dart';
import '../providers/providers.dart';
import 'client/client_navigation_screen.dart';
import 'freelancer/freelancer_navigation_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';
import 'shared/forgot_password_screen.dart';

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

class LoginScreen extends StatefulWidget {
  final UserRole selectedRole;
  const LoginScreen({super.key, required this.selectedRole});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  bool _obscure    = true;
  bool _loading    = false;
  bool _remember   = true;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _cardFade;
  late final Animation<Offset>   _cardSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _cardFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    _emailFocus.dispose(); _passFocus.dispose();
    super.dispose();
  }

  bool get _isClient => widget.selectedRole == UserRole.client;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      identity: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role:     widget.selectedRole.name,
    );

    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      if (_isClient) context.read<TaskProvider>().loadTasks();
      else context.read<FreelancerProvider>().loadFreelancers();
      context.read<ChatProvider>().loadChats(
        myUserId: auth.user?.id ?? '',
        myRole:   widget.selectedRole.name);
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
      setState(() { _loading = false; _error = auth.error ?? 'Login gagal.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleGreen,
      body: Stack(children: [
        // ── Ambient orbs ──────────────────────────────────────
        Positioned(top: -100, right: -80,
          child: Container(width: 380, height: 380,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _brightGreen.withOpacity(0.13), Colors.transparent])))),
        Positioned(bottom: -80, left: -60,
          child: Container(width: 280, height: 280,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _deepGreen.withOpacity(0.09), Colors.transparent])))),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(children: [
              // ── Top bar ────────────────────────────────────────
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: _charcoal, size: 18)),
                ),
                const Spacer(),
                // Role pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_isClient ? '👤' : '💼',
                      style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(_isClient ? 'Client' : 'Freelancer',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _midGreen)),
                  ]),
                ),
              ]),

              const SizedBox(height: 28),

              // ── Auth Card ─────────────────────────────────────
              SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 32, offset: const Offset(0, 8)),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Logo + brand
                        Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _deepGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('S', style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700,
                              color: Colors.white, fontStyle: FontStyle.italic))),
                          ),
                          const SizedBox(width: 9),
                          const Text('SkillBantuin', style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal)),
                        ]),

                        const SizedBox(height: 22),

                        // Title
                        const Text(
                          'Selamat Datang Kembali',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: _charcoal,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Masuk untuk melanjutkan perjalanan karirmu.',
                          style: TextStyle(fontSize: 14, color: _slate, height: 1.4),
                        ),

                        const SizedBox(height: 26),

                        // Error
                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        _FieldLabel('Email'),
                        const SizedBox(height: 6),
                        _CleanField(
                          ctrl: _emailCtrl, focus: _emailFocus,
                          hint: 'nama@email.com',
                          keyboard: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          onNext: () => FocusScope.of(context).requestFocus(_passFocus),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Email wajib diisi' : null,
                        ),

                        const SizedBox(height: 16),

                        // Password row
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const _FieldLabel2('Password'),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                              _slideUp(const ForgotPasswordScreen())),
                            child: const Text('Lupa password?', style: TextStyle(
                              fontSize: 13, color: _deepGreen, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        _CleanField(
                          ctrl: _passCtrl, focus: _passFocus,
                          hint: '••••••••',
                          obscure: _obscure,
                          action: TextInputAction.done,
                          onSubmit: (_) => _login(),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Password wajib diisi' : null,
                          suffix: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                              color: _mist, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure)),
                        ),

                        const SizedBox(height: 16),

                        // Remember me
                        GestureDetector(
                          onTap: () => setState(() => _remember = !_remember),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: _remember ? _deepGreen : Colors.white,
                                border: Border.all(
                                  color: _remember ? _deepGreen : _border,
                                  width: 1.5)),
                              child: _remember
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                                  : null),
                            const SizedBox(width: 9),
                            const Text('Ingat saya', style: TextStyle(
                              fontSize: 13.5, color: _slate, fontWeight: FontWeight.w400)),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        // Login button
                        _PillButton(
                          label: 'Masuk Sekarang',
                          loading: _loading,
                          onTap: _login,
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        const _Divider(text: 'atau masuk dengan'),
                        const SizedBox(height: 16),

                        // Social (UI only, extensible)
                        Row(children: [
                          Expanded(child: _SocialBtn(
                            label: 'Google',
                            icon: const _GoogleIcon(),
                            onTap: () {},
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _SocialBtn(
                            label: 'GitHub',
                            icon: const Icon(Icons.code_rounded,
                              color: _charcoal, size: 18),
                            onTap: () {},
                          )),
                        ]),

                        const SizedBox(height: 20),

                        // Footer
                        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Belum punya akun? ',
                            style: TextStyle(fontSize: 14, color: _slate)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context,
                              _slideUp(RegisterScreen(selectedRole: widget.selectedRole))),
                            child: const Text('Daftar gratis', style: TextStyle(
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

// ── Shared widgets ────────────────────────────────────────────────────────────

Route _slideUp(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 420),
  transitionsBuilder: (_, a, __, c) => SlideTransition(
    position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: a, child: c)),
);

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _charcoal));
}

class _FieldLabel2 extends StatelessWidget {
  final String text;
  const _FieldLabel2(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _charcoal));
}

class _CleanField extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmit;
  final VoidCallback? onNext;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const _CleanField({required this.ctrl, required this.focus, required this.hint,
    this.obscure = false, this.keyboard, this.action, this.onSubmit,
    this.onNext, this.validator, this.suffix});
  @override
  State<_CleanField> createState() => _CleanFieldState();
}

class _CleanFieldState extends State<_CleanField> {
  bool _focused = false;
  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_onFocus);
  }
  @override
  void dispose() { widget.focus.removeListener(_onFocus); super.dispose(); }
  void _onFocus() => setState(() => _focused = widget.focus.hasFocus);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _focused ? const Color(0xFFF0FAF4) : const Color(0xFFF7FAF8),
      border: Border.all(
        color: _focused ? _deepGreen : _border,
        width: _focused ? 1.5 : 1.0),
      boxShadow: _focused
          ? [BoxShadow(color: _deepGreen.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2))]
          : [],
    ),
    child: TextFormField(
      controller: widget.ctrl, focusNode: widget.focus,
      obscureText: widget.obscure,
      keyboardType: widget.keyboard,
      textInputAction: widget.action,
      onFieldSubmitted: widget.onSubmit,
      onEditingComplete: widget.onNext,
      validator: widget.validator,
      style: const TextStyle(fontSize: 15, color: _charcoal, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: _mist, fontSize: 14),
        suffixIcon: widget.suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
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
          color: _deepGreen.withOpacity(0.25),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Center(child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
    ),
  );
}

class _Divider extends StatelessWidget {
  final String text;
  const _Divider({required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: _border)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _mist))),
    const Expanded(child: Divider(color: _border)),
  ]);
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon,
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w500, color: _charcoal)),
      ]),
    ),
  );
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18, height: 18,
    child: CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paints = [
      Paint()..color = const Color(0xFF4285F4),
      Paint()..color = const Color(0xFF34A853),
      Paint()..color = const Color(0xFFFBBC05),
      Paint()..color = const Color(0xFFEA4335),
    ];
    // Simplified G icon segments
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
      -0.5, 2.3, false, paints[0]..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
      1.8, 1.6, false, paints[1]..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
      3.4, 0.8, false, paints[2]..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
      4.2, 1.1, false, paints[3]..style = PaintingStyle.stroke..strokeWidth = 3);
  }
  @override bool shouldRepaint(_) => false;
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
