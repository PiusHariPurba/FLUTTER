// role_selection_screen.dart — Laravel design: pale bg, white cards, editorial
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/auth_flow_mode.dart';
import '../models/user_role.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ── Tokens ───────────────────────────────────────────────────────────────────
const _deepGreen  = Color(0xFF1A5C3A);
const _midGreen   = Color(0xFF2D7A52);
const _lightGreen = Color(0xFFE8F5EE);
const _paleGreen  = Color(0xFFF0FAF4);
const _charcoal   = Color(0xFF1C1F1E);
const _slate      = Color(0xFF4A5550);
const _mist       = Color(0xFF8FA89E);
const _border     = Color(0xFFD6E8DE);
const _offWhite   = Color(0xFFF7FAF8);

class RoleSelectionScreen extends StatefulWidget {
  final AuthFlowMode mode;
  const RoleSelectionScreen({super.key, this.mode = AuthFlowMode.login});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _orbCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 10))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() { _orbCtrl.dispose(); _entryCtrl.dispose(); super.dispose(); }

  void _select(UserRole role) {
    HapticFeedback.lightImpact();
    final screen = widget.mode == AuthFlowMode.login
        ? LoginScreen(selectedRole: role)
        : RegisterScreen(selectedRole: role);
    Navigator.push(context, _slideRoute(screen));
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (_, a, __, c) => SlideTransition(
      position: Tween(begin: const Offset(0.0, 0.04), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: a, child: c)),
  );

  bool get _isLogin => widget.mode == AuthFlowMode.login;

  @override
  Widget build(BuildContext context) {
    final fade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: _paleGreen,
      body: Stack(children: [
        // ── Orbs ─────────────────────────────────────────────
        AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) => Stack(children: [
            Positioned(
              top: -120 + _orbCtrl.value * 25,
              right: -80 + _orbCtrl.value * 15,
              child: Container(width: 360, height: 360,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF3DA668).withOpacity(0.13),
                    Colors.transparent]))),
            ),
            Positioned(
              bottom: -80 + _orbCtrl.value * 10,
              left: -60,
              child: Container(width: 240, height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _deepGreen.withOpacity(0.09),
                    Colors.transparent]))),
            ),
          ]),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: fade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ─────────────────────────────────────
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _deepGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: Text('S',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white, fontStyle: FontStyle.italic))),
                      ),
                      const SizedBox(width: 9),
                      const Text('SkillBantuin', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: _charcoal)),
                    ]),

                    const SizedBox(height: 44),

                    // ── Headline ──────────────────────────────────
                    Text(
                      _isLogin ? 'Halo,\nSelamat Datang.' : 'Bergabung\nBersama Kami.',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        color: _charcoal,
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _isLogin ? 'Pilih peranmu untuk melanjutkan.' : 'Mulai perjalanan karirmu sekarang.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: _slate,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Role cards ────────────────────────────────
                    Expanded(
                      child: Column(children: [
                        _RoleCard(
                          role: UserRole.client,
                          isLogin: _isLogin,
                          onTap: () => _select(UserRole.client),
                        ),
                        const SizedBox(height: 14),
                        _RoleCard(
                          role: UserRole.freelancer,
                          isLogin: _isLogin,
                          onTap: () => _select(UserRole.freelancer),
                        ),
                      ]),
                    ),

                    // ── Toggle ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28, top: 16),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(
                          _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                          style: const TextStyle(fontSize: 14, color: _mist),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => RoleSelectionScreen(
                                mode: _isLogin ? AuthFlowMode.register : AuthFlowMode.login),
                              transitionDuration: const Duration(milliseconds: 350),
                              transitionsBuilder: (_, a, __, c) =>
                                  FadeTransition(opacity: a, child: c))),
                          child: Text(
                            _isLogin ? 'Daftar' : 'Masuk',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _deepGreen,
                              decoration: TextDecoration.underline,
                              decorationColor: _deepGreen,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Role Card (white, clean, editorial) ──────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final UserRole role;
  final bool isLogin;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.isLogin, required this.onTap});
  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  bool get _isClient => widget.role == UserRole.client;

  static const _clientFeatures = ['Post Proyek', 'Review Freelancer', 'Chat Langsung'];
  static const _flFeatures     = ['Lamar Proyek', 'Kelola Portofolio', 'Terima Pembayaran'];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _pressed ? _lightGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed ? _deepGreen : _border,
              width: _pressed ? 1.5 : 1.0,
            ),
            boxShadow: _pressed
                ? [BoxShadow(color: _deepGreen.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            // Role icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56, height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _pressed ? _deepGreen : _lightGreen,
                border: Border.all(color: _border),
              ),
              child: Center(child: Text(
                _isClient ? '👤' : '💼',
                style: const TextStyle(fontSize: 26))),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _isClient ? 'Saya Client' : 'Saya Freelancer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _pressed ? _deepGreen : _charcoal,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isClient
                    ? 'Cari & hire freelancer\nuntuk proyekmu'
                    : 'Temukan proyek &\ntingkatkan penghasilan',
                style: const TextStyle(
                  fontSize: 13, color: _slate, height: 1.4),
              ),
              const SizedBox(height: 10),

              // Feature tags
              Wrap(spacing: 6, runSpacing: 6,
                children: (_isClient ? _clientFeatures : _flFeatures).map((f) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: _lightGreen,
                      border: Border.all(color: _border),
                    ),
                    child: Text(f, style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w500,
                      color: _midGreen)),
                  )).toList()),
            ])),

            // Arrow
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _pressed ? _deepGreen : _mist),
          ]),
        ),
      ),
    );
  }
}
