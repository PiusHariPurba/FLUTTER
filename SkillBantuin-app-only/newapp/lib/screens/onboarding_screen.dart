// onboarding_screen.dart — Laravel design: editorial, white, minimal
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/session_service.dart';
import 'role_selection_screen.dart';

// ── Tokens ───────────────────────────────────────────────────────────────────
const _deepGreen  = Color(0xFF1A5C3A);
const _midGreen   = Color(0xFF2D7A52);
const _lightGreen = Color(0xFFE8F5EE);
const _paleGreen  = Color(0xFFF0FAF4);
const _charcoal   = Color(0xFF1C1F1E);
const _slate      = Color(0xFF4A5550);
const _mist       = Color(0xFF8FA89E);
const _border     = Color(0xFFD6E8DE);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _orbCtrl;
  int _page = 0;

  static const _pages = [
    _Page(
      number: '01',
      tag:    'Koneksi',
      title:  'Temukan\nTalenta Terbaik',
      desc:   'SkillBantuin menghubungkan klien dengan freelancer profesional Indonesia — dikurasi, terverifikasi, dan siap bekerja.',
      icon:   Icons.people_alt_outlined,
      accent: Color(0xFF1A5C3A),
    ),
    _Page(
      number: '02',
      tag:    'Kepercayaan',
      title:  'Kerja Dengan\nAman & Nyaman',
      desc:   'Sistem escrow, review mutual, dan progress tracking real-time memastikan setiap proyek berjalan transparan.',
      icon:   Icons.verified_outlined,
      accent: Color(0xFF2D7A52),
    ),
    _Page(
      number: '03',
      tag:    'Karir',
      title:  'Tumbuh\nBersama Kami',
      desc:   'Lebih dari 50.000 talenta digital telah bergabung. Saatnya kamu mulai perjalanan karirmu bersama SkillBantuin.',
      icon:   Icons.trending_up_outlined,
      accent: Color(0xFF1A5C3A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _orbCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pc.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await SessionService().markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _pages.length - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // ── Ambient orb ───────────────────────────────────────
        AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) => Positioned(
            top: -100 + _orbCtrl.value * 30,
            right: -80 + _orbCtrl.value * 20,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3DA668).withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // ── Header: logo + skip ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 20, 0),
                child: Row(children: [
                  // Logo mark small
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _deepGreen,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(child: Text('S', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white, fontStyle: FontStyle.italic))),
                  ),
                  const SizedBox(width: 9),
                  const Text('SkillBantuin', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: _charcoal, letterSpacing: -0.3)),
                  const Spacer(),
                  if (_page < _pages.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Lewati', style: TextStyle(
                        fontSize: 14, color: _mist, fontWeight: FontWeight.w500)),
                    ),
                ]),
              ),

              // ── Page content ──────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _page = i);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // ── Bottom: dots + CTA ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: i == _page ? 28 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page ? _deepGreen : _border,
                      ),
                    )),
                  ),

                  const SizedBox(height: 28),

                  // CTA button (pill, solid green)
                  GestureDetector(
                    onTap: _next,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _deepGreen,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: _deepGreen.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _page < _pages.length - 1 ? 'Lanjutkan' : 'Mulai Sekarang',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Page content ──────────────────────────────────────────────────────────────
class _PageContent extends StatefulWidget {
  final _Page page;
  const _PageContent({super.key, required this.page});
  @override
  State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Illustration area ──────────────────────────────
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: _paleGreen,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Stack(children: [
                  // Number watermark
                  Positioned(
                    right: 24, bottom: 16,
                    child: Text(
                      widget.page.number,
                      style: TextStyle(
                        fontSize: 88,
                        fontWeight: FontWeight.w700,
                        color: _border.withOpacity(0.8),
                        height: 1,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  // Icon center
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: _lightGreen,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _border),
                          ),
                          child: Icon(widget.page.icon,
                              color: _deepGreen, size: 38),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 36),

              // Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  widget.page.tag.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _midGreen,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title (editorial feel)
              Text(
                widget.page.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: _charcoal,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 14),

              // Description
              Text(
                widget.page.desc,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _slate,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────
class _Page {
  final String number, tag, title, desc;
  final IconData icon;
  final Color accent;
  const _Page({required this.number, required this.tag, required this.title,
    required this.desc, required this.icon, required this.accent});
}
