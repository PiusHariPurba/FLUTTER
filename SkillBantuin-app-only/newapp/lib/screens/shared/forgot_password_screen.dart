// forgot_password_screen.dart — Laravel auth card design
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

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
const _successGreen = Color(0xFF059669);
const _successBg    = Color(0xFFF0FDF4);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _focus   = FocusNode();
  final _auth    = AuthService();

  bool   _loading = false;
  bool   _sent    = false;
  String? _error;

  late final AnimationController _successCtrl;
  late final Animation<double>   _successScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _successCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _successScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose(); _focus.dispose(); _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    HapticFeedback.lightImpact();

    final res = await _auth.forgotPassword(_ctrl.text.trim());

    if (!mounted) return;
    if (res.success) {
      HapticFeedback.mediumImpact();
      setState(() { _loading = false; _sent = true; });
      _successCtrl.forward();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _loading = false;
        _error   = res.message ?? 'Email tidak ditemukan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleGreen,
      body: Stack(children: [
        // ── Orbs ─────────────────────────────────────────────
        Positioned(top: -100, right: -80,
          child: Container(width: 320, height: 320,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _brightGreen.withOpacity(0.11), Colors.transparent])))),

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
              ]),

              const SizedBox(height: 28),

              // ── Auth Card ─────────────────────────────────────
              Container(
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _sent
                      ? _SuccessView(
                          email: _ctrl.text.trim(),
                          scaleAnim: _successScale,
                          onBack: () => Navigator.pop(context))
                      : _FormView(
                          formKey: _formKey,
                          ctrl: _ctrl,
                          focus: _focus,
                          loading: _loading,
                          error: _error,
                          onSend: _send),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool loading;
  final String? error;
  final VoidCallback onSend;
  const _FormView({required this.formKey, required this.ctrl, required this.focus,
    required this.loading, required this.error, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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

        const SizedBox(height: 24),

        // Icon
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border)),
          child: const Icon(Icons.lock_reset_outlined, color: _deepGreen, size: 26)),

        const SizedBox(height: 18),

        const Text('Lupa Password?', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w500,
          color: _charcoal, letterSpacing: -0.4)),

        const SizedBox(height: 6),
        const Text(
          'Masukkan emailmu dan kami kirimkan link untuk reset password.',
          style: TextStyle(fontSize: 14, color: _slate, height: 1.5)),

        const SizedBox(height: 24),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dangerBg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _danger.withOpacity(0.25))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: _danger, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(error!, style: const TextStyle(
                fontSize: 13, color: _danger))),
            ])),
          const SizedBox(height: 14),
        ],

        // Email label
        const Text('Alamat Email', style: TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w500, color: _charcoal)),
        const SizedBox(height: 6),

        _FocusField(
          ctrl: ctrl, focus: focus,
          hint: 'nama@email.com',
          keyboard: TextInputType.emailAddress,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'Email wajib diisi';
            if (!v!.contains('@')) return 'Format email tidak valid';
            return null;
          },
          onSubmit: (_) => onSend()),

        const SizedBox(height: 24),

        // Button
        GestureDetector(
          onTap: loading ? null : onSend,
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
                : const Text('Kirim Link Reset', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
          ),
        ),

        const SizedBox(height: 20),

        // Footer
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Ingat passwordmu? ',
            style: TextStyle(fontSize: 14, color: _mist)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Masuk Sekarang', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _deepGreen))),
        ])),
      ]),
    );
  }
}

// ── Success view ─────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String email;
  final Animation<double> scaleAnim;
  final VoidCallback onBack;
  const _SuccessView({required this.email, required this.scaleAnim, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScaleTransition(
        scale: scaleAnim,
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _successBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0))),
          child: const Icon(Icons.mark_email_read_outlined,
            color: _successGreen, size: 30)),
      ),

      const SizedBox(height: 18),

      const Text('Link Terkirim!', style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w500,
        color: _charcoal, letterSpacing: -0.4)),

      const SizedBox(height: 8),

      Text(
        'Kami sudah mengirimkan link reset password ke\n$email',
        style: const TextStyle(fontSize: 14, color: _slate, height: 1.5)),

      const SizedBox(height: 14),

      // Hint box
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tidak menerima email?', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _charcoal)),
          const SizedBox(height: 6),
          const Text('• Cek folder Spam atau Junk\n'
            '• Pastikan email yang dimasukkan benar\n'
            '• Tunggu beberapa menit, ada kemungkinan delay',
            style: TextStyle(fontSize: 12.5, color: _slate, height: 1.6)),
        ]),
      ),

      const SizedBox(height: 24),

      GestureDetector(
        onTap: onBack,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: _deepGreen,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(
              color: _deepGreen.withOpacity(0.22),
              blurRadius: 14, offset: const Offset(0, 5))]),
          child: const Center(child: Text('Kembali ke Login', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
        ),
      ),
    ]);
  }
}

// ── Focus field ───────────────────────────────────────────────────────────────
class _FocusField extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmit;
  const _FocusField({required this.ctrl, required this.focus, required this.hint,
    this.keyboard, this.validator, this.onSubmit});
  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
  bool _f = false;
  @override
  void initState() { super.initState(); widget.focus.addListener(_l); }
  @override
  void dispose() { widget.focus.removeListener(_l); super.dispose(); }
  void _l() => setState(() => _f = widget.focus.hasFocus);

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
      controller: widget.ctrl, focusNode: widget.focus,
      keyboardType: widget.keyboard,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: widget.onSubmit,
      validator: widget.validator,
      style: const TextStyle(fontSize: 15, color: _charcoal),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: _mist, fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    ),
  );
}
