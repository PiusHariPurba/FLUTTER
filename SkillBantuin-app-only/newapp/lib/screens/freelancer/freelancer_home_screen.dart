// ─────────────────────────────────────────────────────────────────────────────
//  freelancer_home_screen.dart — L99 Edition
//  Dashboard Freelancer: greeting · earnings · stats · quick actions
//  · proyek rekomendasi · activity feed
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/task_models.dart';
import '../../providers/providers.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';
import 'freelancer_profile_screen.dart';
import 'freelancer_progress_screen.dart';
import '../shared/notification_screen.dart';
import 'freelancer_search_screen.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});
  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _activeCat = 0;
  late final AnimationController _heroCtrl;

  static const _categories = [
    ('🌐', 'Semua'),
    ('🎨', 'Design'),
    ('💻', 'Dev'),
    ('✍️', 'Writing'),
    ('📊', 'Marketing'),
    ('📱', 'Mobile'),
  ];

  // _staticProjects dihapus — hanya gunakan data real dari TaskProvider

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    LanguageNotifier.instance.addListener(_r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks(status: 'open');
      context.read<NotificationProvider>().fetchNotifications();
      context.read<OfferProvider>().fetchMyOffers();
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
    MaterialPageRoute(builder: (_) => const FreelancerSearchScreen()));

  void _showEarningsSheet(BuildContext ctx) {
    final offers = context.read<OfferProvider>().acceptedOffers;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFDDD9D4),
              borderRadius: BorderRadius.circular(2))),
          const Text('Ringkasan Penghasilan', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w900, color: FPal.ink)),
          const SizedBox(height: 20),
          ...offers.map((o) {
            final title = (o['task']?['title'] ?? 'Proyek') as String;
            final price = (o['price'] as num?)?.toInt() ?? 0;
            final status = (o['task']?['status'] ?? '') as String;
            return Padding(padding: const EdgeInsets.only(bottom: 8),
              child: _EarnRow(
                title.length > 30 ? '${title.substring(0,28)}…' : title,
                'Rp ${price >= 1000000 ? "${(price/1000000).toStringAsFixed(1)}jt" : "${(price/1000).round()}rb"}',
                status == 'completed' ? const Color(0xFF059669) : FPal.primary));
          }),
          if (offers.isEmpty)
            const Text('Belum ada proyek aktif.', style: TextStyle(color: FPal.inkMuted)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FPal.primaryLight,
              borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: FPal.primary, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Fitur penarikan dana akan segera hadir.',
                style: TextStyle(fontSize: 12.5, color: FPal.primary))),
            ])),
        ]),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.fullName.split(' ').first ?? 'Freelancer';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Pagi' : hour < 17 ? 'Siang' : 'Malam';

    return Scaffold(
      backgroundColor: FPal.bg,
      floatingActionButton: FadeScaleIn(
        delay: const Duration(milliseconds: 1200),
        child: FloatingActionButton.extended(
          onPressed: _goSearch,
          backgroundColor: FPal.primary,
          elevation: 4,
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          label: const Text('Cari Proyek',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverToBoxAdapter(child: _FLHeroHeader(
            greeting:  greeting,
            name:      name,
            heroCtrl:  _heroCtrl,
            onSearch:  _goSearch,
          )),

          // ── Earnings Summary ─────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SlideUp(delay: const Duration(milliseconds: 350),
              child: _EarningsSummary()),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Quick Stats ──────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SlideUp(delay: const Duration(milliseconds: 420),
              child: Builder(builder: (ctx) {
                final offerProv = ctx.watch<OfferProvider>();
                final activeCount = offerProv.acceptedOffers.length;
                final totalSent   = offerProv.myOffers.length;
                return Row(children: [
                  _SmallStat('$activeCount', 'Aktif\nSekarang', Icons.work_outline_rounded, FPal.primary),
                  const SizedBox(width: 10),
                  _SmallStat('$totalSent', 'Lamaran\nDikirim', Icons.send_rounded, const Color(0xFF059669)),
                  const SizedBox(width: 10),
                  _SmallStat('—', 'Rating\nKamu', Icons.star_outline_rounded, const Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  _SmallStat('—', 'Ulasan\nDiterima', Icons.reviews_outlined, const Color(0xFF0369A1)),
                ]);
              }),
            ),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Quick Actions ────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Aksi Cepat', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: FPal.ink)),
              const SizedBox(height: 12),
              Row(children: [
                _QuickAction(
                  emoji: '🔍', label: 'Cari\nProyek',
                  color: FPal.primary, bg: FPal.primaryLight,
                  onTap: _goSearch),
                const SizedBox(width: 10),
                _QuickAction(
                  emoji: '📋', label: 'Lamaran\nSaya',
                  color: const Color(0xFF0369A1), bg: const Color(0xFFE0F2FE),
                  onTap: () => Navigator.push(context,
                    slideRightRoute(const FreelancerProgressScreen()))),
                const SizedBox(width: 10),
                _QuickAction(
                  emoji: '💰', label: 'Penghasilan',
                  color: const Color(0xFF059669), bg: const Color(0xFFD1FAE5),
                  onTap: () => _showEarningsSheet(context)),
                const SizedBox(width: 10),
                _QuickAction(
                  emoji: '⭐', label: 'Portofolio',
                  color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7),
                  onTap: () => Navigator.push(context,
                    slideRightRoute(const FreelancerProfileScreen()))),
              ]),
            ]),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Category Filter ──────────────────────────────────────
          SliverToBoxAdapter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Proyek Untukmu', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: FPal.ink)),
              ),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = i == _activeCat;
                    return GestureDetector(
                      onTap: () => setState(() => _activeCat = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? FPal.primary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: active ? FPal.primary : const Color(0xFFDDE2EE))),
                        child: Row(children: [
                          Text(_categories[i].$1,
                            style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(_categories[i].$2, style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : FPal.inkSoft)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── Project Cards — REAL DATA from TaskProvider ────────────────────────────
          Builder(builder: (ctx) {
            final rawTasks = ctx.watch<TaskProvider>().tasks;
            final openTasks = rawTasks.where((t) => t['status'] == 'open').toList();
            final displayTasks = openTasks.isNotEmpty ? openTasks : <Map<String,dynamic>>[];
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: displayTasks.isNotEmpty
                  ? SliverList(delegate: SliverChildBuilderDelegate(
                      (ctx2, i) {
                        if (i >= displayTasks.length) return null;
                        final t = displayTasks[i];
                        final budget = (t['budget_min'] as num?) ?? 0;
                        final budgetMax = (t['budget_max'] as num?) ?? 0;
                        final budgetLabel = budget > 0
                            ? 'Rp ${budget >= 1000000 ? "${(budget/1000000).toStringAsFixed(1)}jt" : "${(budget/1000).round()}rb"}'
                              '–Rp ${budgetMax >= 1000000 ? "${(budgetMax/1000000).toStringAsFixed(1)}jt" : "${(budgetMax/1000).round()}rb"}'
                            : 'Negosiasi';
                        final deadline = t['deadline'] as String? ?? '-';
                        final applicants = (t['offers_count'] as num?)?.toInt() ?? 0;
                        final isUrgent = deadline.isNotEmpty && deadline != '-' &&
                            DateTime.tryParse(deadline)?.difference(DateTime.now()).inDays.abs() != null &&
                            (DateTime.tryParse(deadline)?.difference(DateTime.now()).inDays ?? 99) <= 5;
                        final colors2 = const [Color(0xFF1A6B55), Color(0xFF0369A1), Color(0xFF7C3AED),
                          Color(0xFFD97706), Color(0xFFDC2626)];
                        final color = colors2[i % colors2.length];
                        // Use static _Proj for card rendering
                        final p = _Proj(
                          t['title'] ?? 'Proyek',
                          (t['client']?['name'] ?? 'Client') as String,
                          budgetLabel,
                          deadline.isEmpty ? '-' : deadline,
                          applicants,
                          isUrgent,
                          color,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SlideInRight(
                            delay: Duration(milliseconds: 200 + i * 80),
                            child: _ProjectCard(p: p),
                          ),
                        );
                      },
                      childCount: displayTasks.take(5).length,
                    ))
                  : SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: FPal.inkMuted),
                          const SizedBox(height: 12),
                          const Text('Belum ada proyek terbuka',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: FPal.ink)),
                          const SizedBox(height: 6),
                          const Text('Proyek baru akan muncul di sini.',
                            style: TextStyle(fontSize: 13, color: FPal.inkMuted)),
                        ])),
                      )),
            );
          }),


          // ── Activity Feed ─────────────────────────────────────────
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Aktivitas Terbaru', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: FPal.ink)),
          )),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: Builder(builder: (ctx) {
              final notifs = ctx.watch<NotificationProvider>().notifications;
              if (notifs.isNotEmpty) {
                return SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx2, i) {
                    if (i >= notifs.length) return null;
                    final n = notifs[i];
                    final color = switch (n.type) {
                      'offer_accepted' => FPal.primary,
                      'new_message'    => const Color(0xFF0369A1),
                      'review_received'=> const Color(0xFFD97706),
                      _                => const Color(0xFF7C3AED),
                    };
                    final emoji = switch (n.type) {
                      'offer_accepted' => '🎉',
                      'new_message'    => '💬',
                      'review_received'=> '⭐',
                      'progress_update'=> '📊',
                      _                => '🔔',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ActivityItem(
                        emoji: emoji, text: n.body,
                        time: _timeAgo(n.createdAt), color: color),
                    );
                  },
                  childCount: notifs.take(3).length,
                ));
              }
              // Fallback statis
              return SliverList(delegate: SliverChildListDelegate([
                _ActivityItem(
                  emoji: '🎉',
                  text: 'Penawaran kamu diterima untuk "UI Redesign App"',
                  time: '2 jam lalu', color: FPal.primary),
                const SizedBox(height: 8),
                _ActivityItem(
                  emoji: '💬',
                  text: 'Pesan baru dari client',
                  time: '5 jam lalu', color: const Color(0xFF0369A1)),
              ]));
            }),
          ),
        ],
      ),
    );
  }
}

// ── Time ago helper ──────────────────────────────────────────────────────────────
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${dt.day}/${dt.month}/${dt.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FL HERO HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _FLHeroHeader extends StatelessWidget {
  final String greeting, name;
  final AnimationController heroCtrl;
  final VoidCallback onSearch;

  const _FLHeroHeader({required this.greeting, required this.name,
    required this.heroCtrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: heroCtrl,
      curve: const Interval(0, 0.6, curve: Curves.easeOut));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0C2B1E), Color(0xFF1A6B55), Color(0xFF27A473)],
          stops: [0.0, 0.5, 1.0]),
      ),
      child: SafeArea(bottom: false,
        child: Stack(children: [
          // Decorative arcs
          Positioned(top: -40, right: -30,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04)))),
          Positioned(top: 30, right: 50,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03)))),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // App bar
              Row(children: [
                FadeTransition(opacity: fade,
                  child: const Row(children: [
                    Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('SkillBantuin', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ])),
                const Spacer(),
                Consumer<NotificationProvider>(
                  builder: (ctx2, notifProv, _) => GestureDetector(
                    onTap: () => Navigator.push(context,
                      slideRightRoute(const NotificationScreen())),
                    child: Stack(children: [
                      Container(width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20)),
                      if (notifProv.unreadCount > 0)
                        Positioned(top: 6, right: 6,
                          child: Container(width: 9, height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBBF24), shape: BoxShape.circle))),
                    ])),
                ),
                const SizedBox(width: 10),
                BounceIn(delay: const Duration(milliseconds: 300),
                  child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white, width: 1.5)),
                    child: Center(child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'F',
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white))))),
              ]),
              const SizedBox(height: 20),

              // Greeting
              FadeTransition(opacity: fade,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6EE7B7).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6EE7B7).withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.verified_rounded,
                          color: Color(0xFF6EE7B7), size: 12),
                        const SizedBox(width: 4),
                        Text('Verified Freelancer', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: const Color(0xFF6EE7B7).withOpacity(0.9))),
                      ])),
                  ]),
                  const SizedBox(height: 8),
                  Text('Selamat $greeting, $name! 👋', style: TextStyle(
                    fontSize: 14, color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Siap kerja\nproyek baru?', style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, height: 1.1, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Builder(builder: (ctx2) {
                    final count = ctx2.watch<TaskProvider>().tasks.length;
                    return Text(
                      count > 0
                          ? 'Ada $count proyek menunggu keahlianmu.'
                          : 'Cari proyek yang sesuai keahlianmu.',
                      style: TextStyle(fontSize: 14,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w500));
                  }),
                ])),
              const SizedBox(height: 20),

              // Search bar
              SlideUp(delay: const Duration(milliseconds: 400), distance: 0.15,
                child: GestureDetector(
                  onTap: onSearch,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Row(children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search_rounded, color: FPal.inkMuted, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Cari proyek berdasarkan skill...',
                        style: TextStyle(color: FPal.inkMuted, fontSize: 13.5,
                          fontWeight: FontWeight.w500))),
                      Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: FPal.primary, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Cari', style: TextStyle(
                          color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))),
                    ]),
                  ),
                )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Earnings Summary (real data from OfferProvider) ─────────────────────────

class _EarningsSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final offers = context.watch<OfferProvider>().acceptedOffers;
    final totalEarnings = offers.fold<int>(0,
        (sum, o) => sum + ((o['price'] as num?)?.toInt() ?? 0));

    final month = const ['','Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'][DateTime.now().month];
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A6B55), Color(0xFF2D9470)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: FPal.primary.withOpacity(0.25),
          blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Penghasilan Aktif', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: Text('$month $year', style: const TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
        const SizedBox(height: 6),
        Text(
          totalEarnings > 0
              ? 'Rp ${totalEarnings >= 1000000
                  ? "${(totalEarnings/1000000).toStringAsFixed(1)}jt"
                  : "${(totalEarnings/1000).round()}rb"}'
              : 'Rp 0',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
            color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF6EE7B7), size: 16),
          const SizedBox(width: 4),
          Text(
            '${offers.length} proyek aktif berjalan',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: Color(0xFF6EE7B7))),
          const Spacer(),
          const Text('Fitur pembayaran segera', style: TextStyle(
            fontSize: 11, color: Colors.white54)),
        ]),
      ]),
    );
  }
}

// ── Small Stat ──────────────────────────────────────────────────────────────────

class _SmallStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _SmallStat(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(
          fontSize: 9.5, fontWeight: FontWeight.w600, color: FPal.inkMuted,
          height: 1.2), textAlign: TextAlign.center),
      ]),
    ));
}

// ── Quick Action ────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final Color color, bg;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label,
    required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color,
            height: 1.2), textAlign: TextAlign.center),
        ]),
      ),
    ));
}

// ── Project Card (Freelancer view) ─────────────────────────────────────────────

class _Proj {
  final String title, company, budget, deadline;
  final int applicants;
  final bool isUrgent;
  final Color color;
  const _Proj(this.title, this.company, this.budget, this.deadline,
    this.applicants, this.isUrgent, this.color);
}

class _ProjectCard extends StatelessWidget {
  final _Proj p;
  const _ProjectCard({required this.p});

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: () => Navigator.push(context,
      slideRightRoute(const FreelancerSearchScreen())),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Color indicator bar
        Container(
          width: 4, height: 80,
          decoration: BoxDecoration(
            color: p.color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (p.isUrgent) Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
              child: const Text('🔥 Urgent', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)))),
            Expanded(child: Text(p.title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(p.company, style: const TextStyle(
            fontSize: 12, color: FPal.inkMuted)),
          const SizedBox(height: 8),
          Row(children: [
            _tag(p.budget, p.color, p.color.withOpacity(0.1)),
            const SizedBox(width: 8),
            _tag('⏰ ${p.deadline}', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
            const SizedBox(width: 8),
            _tag('👤 ${p.applicants}', FPal.inkMuted, FPal.bgMuted),
          ]),
        ])),
        // Apply btn
        const SizedBox(width: 10),
        SpringPress(
          onTap: () => Navigator.push(context,
            slideRightRoute(const FreelancerSearchScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FPal.primary, borderRadius: BorderRadius.circular(10)),
            child: const Text('Lamar', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
      ]),
    ));

  Widget _tag(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
    child: Text(text, style: TextStyle(
      fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)));
}

// ── Activity Item ──────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final String emoji, text, time;
  final Color color;
  const _ActivityItem({required this.emoji, required this.text,
    required this.time, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: color, width: 3)),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 6, offset: const Offset(0, 2))]),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: FPal.ink, height: 1.3)),
        const SizedBox(height: 3),
        Text(time, style: const TextStyle(fontSize: 11.5, color: FPal.inkMuted)),
      ])),
      Icon(Icons.chevron_right_rounded, color: FPal.inkMuted.withOpacity(0.5), size: 18),
    ]),
  );
}

// ── Helper for earnings sheet ─────────────────────────────────────────────────
class _EarnRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EarnRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, color: FPal.inkSoft)),
      Text(value, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    ]);
}
