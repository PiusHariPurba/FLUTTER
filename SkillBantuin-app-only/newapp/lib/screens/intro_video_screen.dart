import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/auth_flow_mode.dart';
import '../widgets/app_theme.dart';
import 'role_selection_screen.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  Timer? _autoSkip;

  late AnimationController _skipAnim;
  late Animation<double> _skipProgress; // 0→1 selama 8 detik

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _skipAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _skipProgress = _skipAnim;

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoCtrl = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _videoCtrl!.initialize();
      if (!mounted) return;
      await _videoCtrl!.setLooping(false);
      await _videoCtrl!.setVolume(0);
      await _videoCtrl!.play();
      setState(() => _videoReady = true);

      // Auto skip saat video selesai
      _videoCtrl!.addListener(() {
        if (_videoCtrl!.value.position >= _videoCtrl!.value.duration) {
          _goNext();
        }
      });
    } catch (_) {
      // Video tidak ada → langsung skip
      _goNext();
      return;
    }

    // Mulai animasi skip timer
    _skipAnim.forward();
    _autoSkip = Timer(const Duration(seconds: 8), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    _autoSkip?.cancel();
    _videoCtrl?.pause();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            const RoleSelectionScreen(mode: AuthFlowMode.login),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _autoSkip?.cancel();
    _skipAnim.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video atau fallback hijau ──
          if (_videoReady && _videoCtrl != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(gradient: FPal.heroGradient),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandMark(size: 80, dark: true),
                    SizedBox(height: 24),
                    Text(
                      'SkillBantuin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Platform Freelance Terpercaya',
                      style: TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Gradient overlay bawah ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Tombol skip ──
          Positioned(
            bottom: 40, right: 24,
            child: GestureDetector(
              onTap: _goNext,
              child: AnimatedBuilder(
                animation: _skipProgress,
                builder: (_, __) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            value: _skipProgress.value,
                            strokeWidth: 2,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Brand kecil di atas ──
          Positioned(
            top: 54, left: 24,
            child: Row(
              children: [
                const BrandMark(size: 32, dark: true),
                const SizedBox(width: 10),
                Text(
                  'SkillBantuin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}