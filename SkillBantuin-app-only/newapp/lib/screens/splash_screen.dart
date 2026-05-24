// splash_screen.dart — Laravel design: pale green bg · clean logo · minimal
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/providers.dart';
import '../models/user_role.dart';
import 'client/client_navigation_screen.dart';
import 'freelancer/freelancer_navigation_screen.dart';
import 'onboarding_screen.dart';
import 'role_selection_screen.dart';

// ── Design tokens (Laravel palette) ─────────────────────────────────────────
const _deepGreen   = Color(0xFF1A5C3A);
const _midGreen    = Color(0xFF2D7A52);
const _brightGreen = Color(0xFF3DA668);
const _paleGreen   = Color(0xFFF0FAF4);
const _lightGreen  = Color(0xFFE8F5EE);
const _charcoal    = Color(0xFF1C1F1E);
const _slate       = Color(0xFF4A5550);
const _mist        = Color(0xFF8FA89E);
const _border      = Color(0xFFD6E8DE);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _orbCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset>  _textSlide;
  late final Animation<double> _tagFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _orbCtrl  = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat(reverse: true);

    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..forward();
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));

    _textCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _tagFade = CurvedAnimation(parent: _textCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    Widget target;
    if (auth.isAuthenticated && auth.user != null) {
      target = auth.user!.role == UserRole.client
          ? const ClientNavigationScreen()
          : const FreelancerNavigationScreen();
    } else if (!onboardingSeen) {
      target = const OnboardingScreen();
    } else {
      target = const RoleSelectionScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => target,
      transitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: c),
    ));
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleGreen,
      body: Stack(children: [
        // ── Ambient orbs (Laravel style) ─────────────────────
        AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) {
            final t = _orbCtrl.value;
            return Stack(children: [
              Positioned(
                top: -120 + t * 20,
                right: -80 + t * 15,
                child: Container(
                  width: 340, height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _brightGreen.withOpacity(0.14),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: -80 - t * 10,
                left: -60 + t * 10,
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _deepGreen.withOpacity(0.10),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ]);
          },
        ),

        // ── Content ──────────────────────────────────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo mark
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const _LogoMark(size: 88),
                ),
              ),

              const SizedBox(height: 28),

              // Brand name
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'SkillBantuin',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: _charcoal,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              FadeTransition(
                opacity: _tagFade,
                child: const Text(
                  'Platform Karir Digital Indonesia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _mist,
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Loading dots
              FadeTransition(
                opacity: _tagFade,
                child: _LoadingDots(ctrl: _orbCtrl),
              ),
            ],
          ),
        ),

        // Version
        Positioned(
          bottom: 32, left: 0, right: 0,
          child: FadeTransition(
            opacity: _tagFade,
            child: const Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(fontSize: 12, color: _mist),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Logo mark (shared by all pre-login screens) ──────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({this.size = 48});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.18;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: _deepGreen,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: _deepGreen.withOpacity(0.30),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontSize: size * 0.46,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontStyle: FontStyle.italic,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Loading dots ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  final AnimationController ctrl;
  const _LoadingDots({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.22;
          final t = ((ctrl.value - delay + 1) % 1.0);
          final s = 0.4 + 0.6 * math.sin(t * math.pi).clamp(0.0, 1.0);
          return Container(
            width: 6, height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(_border, _midGreen, s),
            ),
          );
        }),
      ),
    );
  }
}
