// ─────────────────────────────────────────────────────────────────────────────
//  client_home_screen.dart — L99 Edition
//  FIXED:
//   - Notification bell now navigates to NotificationScreen
//   - Freelancer cards use FreelancerProvider (fallback to static if empty)
//   - Active projects use TaskProvider in_progress data (fallback to static)
//   - Stats wired to real TaskProvider counts
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/task_models.dart';
import '../../providers/providers.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/app_theme.dart';
import '../shared/notification_screen.dart';
import 'client_search_screen.dart';
import 'hire_freelancer_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});
  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  int _activeCat = 0;
  late final AnimationController _heroCtrl;

  static const _categories = [
    ('🎨', 'UI/UX Design'),
    ('💻', 'Web Dev'),
    ('📱', 'Mobile App'),
    ('✍️', 'Copywriting'),
    ('🎬', 'Video'),
    ('📊', 'Marketing'),
    ('🔧', 'Backend'),
  ];



  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    LanguageNotifier.instance.addListener(_r);
    // Load providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FreelancerProvider>().loadFreelancers();
      context.read<TaskProvider>().loadTasks(status: 'in_progress');
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    LanguageNotifier.instance.removeListener(_r);
    super.dispose();
  }

  void _r() => setState(() {});

  void _goSearch() => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ClientSearchScreen()));

  String _avgRating(List<Map<String, dynamic>> freelancers) {
    // FreelancerProvider returns FreelancerProfile objects where 'rating' is at root
    final ratings = freelancers
        .map((f) => (f['rating'] as num?)?.toDouble() ?? 0.0)
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return '—';
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    return avg.toStringAsFixed(1);
  }

  void _goNotif() => Navigator.push(context,   // FIXED: was () {}
    slideRightRoute(const NotificationScreen()));

  void _hireFromApi(Map<String, dynamic> raw) {
    final user    = raw['user'] as Map<String, dynamic>? ?? raw;
    final profile = raw['profile'] as Map<String, dynamic>? ?? {};
    final fl = RecommendedFreelancer.fromApiJson(raw);
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => HireFreelancerScreen(
        freelancer: FreelancerHireData(
          id:    user['id']?.toString() ?? '',
          name:  fl.name,
          skill: fl.skill,
          rating: fl.rating,
          baseRate: fl.baseRate,
          avatar: fl.avatar,
        )),
      transitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (_, a, __, c) => SlideTransition(
        position: Tween(begin: const Offset(1.0, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic)).animate(a),
        child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.fullName.split(' ').first ?? 'Client';
    final isId = LanguageNotifier.instance.isIndonesian;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat Pagi' : hour < 17 ? 'Selamat Siang' : 'Selamat Malam';

    // Real data from providers
    final freelancerProv = context.watch<FreelancerProvider>();
    final taskProv       = context.watch<TaskProvider>();

    final apiFreelancers = freelancerProv.freelancers;
    final activeTasks    = taskProv.tasks
        .where((t) => t['status'] == 'in_progress').toList();
    final activeCount    = activeTasks.length;
    final totalCount     = taskProv.tasks.length;

    return Scaffold(
      backgroundColor: FPal.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ─────────────────────────────────────────
          SliverToBoxAdapter(child: _HeroHeader(
            greeting:  greeting,
            name:      name,
            heroCtrl:  _heroCtrl,
            onSearch:  _goSearch,
            onNotif:   _goNotif,          // FIXED: real navigation
          )),

          // ── Stats Row ───────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SlideUp(delay: const Duration(milliseconds: 400),
              child: Row(children: [
                _StatCard(
                  activeCount > 0 ? '$activeCount' : '0',
                  isId ? 'Proyek\nAktif' : 'Active\nProjects',
                  Icons.rocket_launch_rounded, FPal.primary),
                const SizedBox(width: 10),
                _StatCard(
                  totalCount > 0 ? '$totalCount' : '0',
                  isId ? 'Total\nProyek' : 'Total\nProjects',
                  Icons.assignment_turned_in_rounded, const Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                _StatCard(
                  freelancerProv.freelancers.isNotEmpty
                      ? _avgRating(freelancerProv.freelancers)
                      : '—',
                  isId ? 'Rating\nRata²' : 'Avg\nRating',
                  Icons.star_rounded, const Color(0xFFD97706)),
              ])),
          )),

          // ── Category ────────────────────────────────────────────
          SliverToBoxAdapter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isId ? 'Kategori Layanan' : 'Service Categories',
                      style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w800, color: FPal.ink)),
                    GestureDetector(onTap: _goSearch,
                      child: Text(isId ? 'Lihat semua' : 'See all',
                        style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: FPal.primary))),
                  ],
                ),
              ),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final active = i == _activeCat;
                    return SlideInLeft(
                      delay: Duration(milliseconds: 200 + i * 60),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeCat = i),
                        child: _CatChip(
                          emoji: _categories[i].$1,
                          label: _categories[i].$2,
                          active: active),
                      ),
                    );
                  },
                ),
              ),
            ],
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Freelancer Rekomendasi — REAL DATA ──────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isId ? 'Freelancer Pilihan' : 'Top Freelancers',
                  style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: FPal.ink)),
                GestureDetector(
                  onTap: _goSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FPal.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.tune_rounded, color: FPal.primary, size: 14),
                      SizedBox(width: 4),
                      Text('Filter', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: FPal.primary)),
                    ]),
                  ),
                ),
              ],
            ),
          )),

          SliverToBoxAdapter(child: SizedBox(
            height: 218,
            child: freelancerProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: FPal.primary, strokeWidth: 2))
                : apiFreelancers.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        itemCount: apiFreelancers.take(8).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (ctx, i) {
                          final raw = apiFreelancers[i];
                          final fl  = RecommendedFreelancer.fromApiJson(raw);
                          return SlideInRight(
                            delay: Duration(milliseconds: 300 + i * 80),
                            child: _FreelancerCardApi(
                              fl: fl, isId: isId,
                              onHire: () => _hireFromApi(raw)),
                          );
                        },
                      )
                    : Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.people_outline_rounded, size: 40, color: FPal.inkMuted),
                          const SizedBox(height: 8),
                          Text(isId ? 'Belum ada freelancer' : 'No freelancers yet',
                            style: const TextStyle(color: FPal.inkMuted, fontSize: 13)),
                        ])),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Active Projects — REAL DATA ──────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(isId ? 'Proyek Berjalan' : 'Active Projects',
              style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: FPal.ink)),
          )),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: activeTasks.isNotEmpty
                // FIXED: pakai data real dari TaskProvider
                ? SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i >= activeTasks.length) return null;
                      final t = activeTasks[i];
                      final accepted = (t['offers'] as List?)
                          ?.where((o) => o['status'] == 'accepted').toList() ?? [];
                      final freelancerName = accepted.isNotEmpty
                          ? (accepted.first['freelancer']?['name'] ?? '-')
                          : isId ? 'Menunggu freelancer' : 'Awaiting freelancer';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProjectCard(
                          title: t['title'] ?? 'Proyek',
                          freelancer: freelancerName,
                          progress: 0.5,
                          deadline: t['deadline'] ?? '-',
                          status: isId ? 'Dalam Proses' : 'In Progress',
                          statusColor: FPal.primary),
                      );
                    },
                    childCount: activeTasks.take(2).length,
                  ))
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.work_outline_rounded, size: 40, color: FPal.inkMuted),
                        const SizedBox(height: 8),
                        Text(isId ? 'Belum ada proyek aktif' : 'No active projects',
                          style: const TextStyle(color: FPal.inkMuted, fontSize: 13)),
                      ])),
                    )),
          ),

          // ── Spotlight Banner ─────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: FadeScaleIn(
              delay: const Duration(milliseconds: 700),
              child: FloatingWidget(
                amplitude: 3,
                duration: const Duration(milliseconds: 3000),
                child: _SpotlightBanner(isId: isId, onTap: _goSearch),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════════════
//  HERO HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final String greeting, name;
  final AnimationController heroCtrl;
  final VoidCallback onSearch, onNotif;

  const _HeroHeader({
    required this.greeting, required this.name, required this.heroCtrl,
    required this.onSearch, required this.onNotif});

  @override
  Widget build(BuildContext context) {
    final fadeAnim = CurvedAnimation(parent: heroCtrl,
      curve: const Interval(0, 0.6, curve: Curves.easeOut));
    final slideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
      .animate(CurvedAnimation(parent: heroCtrl,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2B1E), Color(0xFF1A6B55), Color(0xFF2D9470)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(children: [
          // Background decorative circles
          Positioned(top: -30, right: -20,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04)))),
          Positioned(bottom: 10, left: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03)))),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppBar row
                Row(children: [
                  // Logo
                  FadeTransition(opacity: fadeAnim,
                    child: const Row(children: [
                      Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('SkillBantuin', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -0.3)),
                    ])),
                  const Spacer(),
                  // Notification badge — dari NotificationProvider.unreadCount
                  Consumer<NotificationProvider>(
                    builder: (ctx, notifProv, _) => GestureDetector(onTap: onNotif,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: Stack(children: [
                          const Center(child: Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22)),
                          if (notifProv.unreadCount > 0)
                            Positioned(top: 6, right: 6,
                              child: Container(
                                width: 9, height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFBBF24), shape: BoxShape.circle))),
                        ])))),
                  const SizedBox(width: 10),
                  // Avatar
                  BounceIn(delay: const Duration(milliseconds: 300),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white, width: 1.5)),
                      child: Center(child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900,
                          color: Colors.white))))),
                ]),
                const SizedBox(height: 22),

                // Greeting
                SlideTransition(position: slideAnim,
                  child: FadeTransition(opacity: fadeAnim,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$greeting, $name 👋', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 4),
                      const Text('Temukan\ntalenta terbaik',
                        style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.1, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('untuk proyek impianmu.',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7))),
                    ]))),
                const SizedBox(height: 20),

                // Search bar
                SlideUp(delay: const Duration(milliseconds: 350), distance: 0.15,
                  child: GestureDetector(
                    onTap: onSearch,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(children: [
                        const SizedBox(width: 16),
                        Icon(Icons.search_rounded, color: FPal.inkMuted.withOpacity(0.7), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(child: Text(
                          'Cari skill, nama, atau layanan...',
                          style: TextStyle(color: FPal.inkMuted, fontSize: 14,
                            fontWeight: FontWeight.w500))),
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: FPal.primary, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Cari', style: TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                      ]),
                    ),
                  )),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Category chip ──────────────────────────────────────────────────────────────

class _CatChip extends StatelessWidget {
  final String emoji, label;
  final bool active;
  const _CatChip({required this.emoji, required this.label, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: 80,
    decoration: BoxDecoration(
      color: active ? FPal.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: active ? FPal.primary : const Color(0xFFE0DDD9),
        width: active ? 0 : 1),
      boxShadow: active ? [BoxShadow(
        color: FPal.primary.withOpacity(0.25),
        blurRadius: 8, offset: const Offset(0, 3))] : [BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 4)],
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: active ? Colors.white : FPal.inkSoft),
        textAlign: TextAlign.center, maxLines: 1,
        overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Stat Card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: FPal.inkMuted, height: 1.3)),
      ]),
    ));
}

// _FreelancerCard (static/dummy) removed — menggunakan _FreelancerCardApi dari API saja

// ── Active Project Card ────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final String title, freelancer, deadline, status;
  final double progress;
  final Color statusColor;
  const _ProjectCard({required this.title, required this.freelancer,
    required this.progress, required this.deadline,
    required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.person_rounded, size: 13, color: FPal.inkMuted),
        const SizedBox(width: 4),
        Text(freelancer, style: const TextStyle(fontSize: 12, color: FPal.inkMuted)),
        const Spacer(),
        const Icon(Icons.calendar_today_rounded, size: 13, color: FPal.inkMuted),
        const SizedBox(width: 4),
        Text(deadline, style: const TextStyle(fontSize: 12, color: FPal.inkMuted)),
      ]),
      const SizedBox(height: 10),
      // Progress bar
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: FPal.bgMuted,
            valueColor: AlwaysStoppedAnimation(statusColor),
            minHeight: 6))),
        const SizedBox(width: 8),
        Text('${(progress * 100).round()}%', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
      ]),
    ]),
  );
}

// ── Spotlight Banner ───────────────────────────────────────────────────────────

class _SpotlightBanner extends StatelessWidget {
  final bool isId;
  final VoidCallback onTap;
  const _SpotlightBanner({required this.isId, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0C2B1E), Color(0xFF1A6B55)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: FPal.primary.withOpacity(0.3),
        blurRadius: 20, offset: const Offset(0, 8))]),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8)),
          child: const Text('✨  WEEKLY SPOTLIGHT', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            color: Color(0xFFFBBF24), letterSpacing: 1))),
        const SizedBox(height: 10),
        Text(isId
          ? 'Mulai proyek\nimpianmu hari ini'
          : 'Launch your dream\nproject today',
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900,
            color: Colors.white, height: 1.2, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(isId ? 'Mulai Sekarang' : 'Get Started',
                style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w800, color: FPal.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                size: 14, color: FPal.primary),
            ])),
        ),
      ])),
      const SizedBox(width: 16),
      // Illustration
      Column(children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle),
          child: const Center(child: Text('🚀', style: TextStyle(fontSize: 32)))),
        const SizedBox(height: 8),
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            shape: BoxShape.circle),
          child: const Center(child: Text('💼', style: TextStyle(fontSize: 22)))),
      ]),
    ]),
  );
}

// ── Freelancer Card (dari API RecommendedFreelancer) ─────────────────────────

class _FreelancerCardApi extends StatelessWidget {
  final RecommendedFreelancer fl;
  final bool isId;
  final VoidCallback onHire;
  const _FreelancerCardApi({required this.fl, required this.isId, required this.onHire});

  static const _colors = [
    Color(0xFF2E7D5E), Color(0xFF7C3AED), Color(0xFF0369A1),
    Color(0xFFD97706), Color(0xFFDC2626), Color(0xFF059669),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[fl.name.codeUnitAt(0) % _colors.length];
    return TapScale(
      onTap: onHire,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
              child: fl.avatar != null && fl.avatar!.startsWith('http')
                  ? ClipOval(child: Image.network(fl.avatar!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(
                        fl.name.isNotEmpty ? fl.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)))))
                  : Center(child: Text(
                      fl.name.isNotEmpty ? fl.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                const SizedBox(width: 2),
                Text(fl.rating.toStringAsFixed(1), style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
              ])),
          ]),
          const SizedBox(height: 12),
          Text(fl.name, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(fl.skill, style: const TextStyle(
            fontSize: 11.5, color: FPal.inkMuted, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text(fl.baseRate > 0 ? 'Rp ${(fl.baseRate / 1000).round()}k/jam' : 'Negosiasi',
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: FPal.primary)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A6B55), Color(0xFF2D9470)]),
              borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('Hire',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                color: Colors.white))),
          ),
        ]),
      ),
    );
  }
}
