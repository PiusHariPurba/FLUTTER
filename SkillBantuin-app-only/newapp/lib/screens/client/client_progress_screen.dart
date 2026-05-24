// ─────────────────────────────────────────────────────────────────────────────
//  client_progress_screen.dart  —  Real data edition
//
//  FIXED:
//    - Panggil GET /my-tasks (bukan GET /tasks) → hanya task milik client
//    - Total budget dihitung dari task yang di-load, bukan hardcode
//    - Review sheet terhubung ke POST /offers/{offerId}/review via OfferService
//    - _Proj membawa offerId + progress real dari accepted offer
//    - Semua dummy data dihapus
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/offer_service.dart';
import '../../services/task_service.dart';
import 'client_search_screen.dart';
import '../../widgets/app_animations.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';

class ClientProgressScreen extends StatefulWidget {
  const ClientProgressScreen({super.key});
  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _svc = TaskService();
  final _offerSvc = OfferService();

  bool _loading = true;
  String? _error;
  List<_Proj> _projects = [];
  int _totalBudget = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    LanguageNotifier.instance.addListener(_r);
    _loadProjects();
  }

  @override
  void dispose() {
    _tab.dispose();
    LanguageNotifier.instance.removeListener(_r);
    super.dispose();
  }

  void _r() => setState(() {});

  /// Fetch task milik client via GET /my-tasks, konversi ke _Proj.
  Future<void> _loadProjects() async {
    setState(() { _loading = true; _error = null; });

    try {
      // Ambil semua status relevan sekaligus dalam satu request (no status filter = semua)
      final res = await _svc.getMyTasks();

      if (!res.success) {
        setState(() { _error = res.message ?? 'Gagal memuat proyek'; _loading = false; });
        return;
      }

      final raw = res['data'];
      List<dynamic> allRaw = [];
      if (raw is Map && raw['data'] is List) {
        allRaw = raw['data'] as List;
      } else if (raw is List) {
        allRaw = raw;
      }

      // Filter: hanya status yang relevan untuk progress
      final relevant = allRaw.where((r) {
        final s = (r as Map<String, dynamic>)['status'] as String? ?? '';
        return s == 'in_progress' || s == 'submitted' || s == 'completed';
      }).toList();

      _projects = relevant
          .map((raw) => _projFromRaw(raw as Map<String, dynamic>))
          .toList();

      // Hitung total budget dari agreed/max budget semua task
      _totalBudget = _projects.fold(0, (sum, p) => sum + p.budgetRaw);
    } catch (e) {
      _error = 'Error: $e';
      _projects = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await _loadProjects();
  }

  /// Konversi raw JSON task (dari /my-tasks) ke _Proj struct UI.
  _Proj _projFromRaw(Map<String, dynamic> t) {
    final status = (t['status'] as String?) ?? 'open';

    final pStatus = switch (status) {
      'completed'   => _PStatus.done,
      'submitted'   => _PStatus.review,
      'in_progress' => _PStatus.onTrack,
      _             => _PStatus.new_,
    };

    // Budget: accepted offer price > budget_max > budget_min
    final acceptedOffer = t['accepted_offer'] as Map<String, dynamic>?;
    final agreedBudget  = (acceptedOffer?['price'] as num?)?.toInt()
        ?? (t['budget_max'] as num?)?.toInt()
        ?? (t['budget_min'] as num?)?.toInt()
        ?? 0;

    final budget = agreedBudget > 0 ? 'Rp ${_fmtBudget(agreedBudget)}' : 'Negosiasi';

    // Deadline
    final deadlineRaw = t['deadline'] as String?;
    final deadline = pStatus == _PStatus.done
        ? 'Selesai'
        : _fmtDeadline(deadlineRaw);

    // Progress 0.0–1.0
    final progressPct = switch (status) {
      'completed'   => 100,
      'submitted'   => 90,
      'in_progress' => (acceptedOffer?['progress_percent'] as int?) ?? 30,
      _             => 0,
    };
    final progress = progressPct / 100.0;

    // Freelancer name dari accepted offer
    final freelancerMap = acceptedOffer?['freelancer'] as Map<String, dynamic>?;
    final freelancer = (freelancerMap?['name'] as String?)
        ?? (t['assigned_freelancer'] as String?)
        ?? '-';

    // Offer ID untuk review
    final offerId = acceptedOffer?['id']?.toString();

    return _Proj(
      t['title'] as String? ?? 'Proyek',
      freelancer,
      (t['category'] as String?) ?? 'Umum',
      progress,
      pStatus,
      budget,
      deadline,
      offerId,
      agreedBudget,
    );
  }

  String _fmtBudget(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}jt';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}rb';
    return n.toString();
  }

  String _fmtDeadline(String? raw) {
    if (raw == null || raw.isEmpty) return 'Tidak ada deadline';
    try {
      final d = DateTime.parse(raw);
      final diff = d.difference(DateTime.now()).inDays;
      if (diff < 0) return 'Lewat deadline';
      if (diff == 0) return 'Deadline hari ini!';
      return '$diff hari lagi';
    } catch (_) {
      return raw;
    }
  }

  // ── Review handler ────────────────────────────────────────────────
  void _openReviewSheet(_Proj p) {
    if (p.offerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Offer ID tidak tersedia untuk review ini'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    _showRatingSheet(context, p, _offerSvc);
  }

  @override
  Widget build(BuildContext context) {
    final isId  = LanguageNotifier.instance.isIndonesian;
    final active = _projects.where((p) => p.status != _PStatus.done).length;
    final done   = _projects.where((p) => p.status == _PStatus.done).length;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: FPal.inkMuted),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: FPal.inkMuted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: FPal.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _ProgressHeader(
            active: active, done: done, total: _projects.length,
            totalBudget: _totalBudget,
            isId: isId)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(tab: _tab, isId: isId),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: FPal.primary, strokeWidth: 2.5,
          child: TabBarView(
            controller: _tab,
            children: [
              _ProjectList(projects: _projects, filter: null, onReview: _openReviewSheet),
              _ProjectList(projects: _projects,
                filter: (p) => p.status != _PStatus.done, onReview: _openReviewSheet),
              _ProjectList(projects: _projects,
                filter: (p) => p.status == _PStatus.done, onReview: _openReviewSheet),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress Header ────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int active, done, total, totalBudget;
  final bool isId;
  const _ProgressHeader({required this.active, required this.done,
    required this.total, required this.totalBudget, required this.isId});

  String _fmtBudget(int n) {
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}jt';
    if (n >= 1000)    return 'Rp ${(n / 1000).round()}rb';
    return 'Rp $n';
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0C2B1E), Color(0xFF1A6B55)])),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isId ? 'Progress Proyek' : 'Project Progress',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: -0.4)),
            Text(isId ? '$total proyek total' : '$total total projects',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65))),
          ]),
          const Spacer(),
          SpringPress(
            onTap: () => Navigator.push(context, slideRightRoute(const ClientSearchScreen())),
            child: Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _HeaderStat('$active', isId ? 'Aktif' : 'Active',
            Icons.rocket_launch_rounded, const Color(0xFF6EE7B7)),
          const SizedBox(width: 10),
          _HeaderStat('$done', isId ? 'Selesai' : 'Done',
            Icons.check_circle_rounded, const Color(0xFFFBBF24)),
          const SizedBox(width: 10),
          _HeaderStat(
            totalBudget > 0 ? _fmtBudget(totalBudget) : '-',
            'Total Budget',
            Icons.payments_outlined, const Color(0xFFA78BFA)),
        ]),
      ]),
    )),
  );
}

class _HeaderStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _HeaderStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: StaggerItem(index: 0, fromY: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16,
            fontWeight: FontWeight.w900, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 11,
            color: Colors.white.withOpacity(0.6))),
        ]),
      )));
}

// ── Tab Header ─────────────────────────────────────────────────────────────────

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tab;
  final bool isId;
  const _TabHeaderDelegate({required this.tab, required this.isId});

  @override double get minExtent => 52;
  @override double get maxExtent => 52;
  @override bool shouldRebuild(_) => false;

  @override
  Widget build(BuildContext context, double shrink, bool overlap) =>
    Container(
      color: Colors.white,
      child: TabBar(
        controller: tab,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        labelColor: FPal.primary,
        unselectedLabelColor: FPal.inkMuted,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: FPal.primary, width: 2.5),
          insets: EdgeInsets.symmetric(horizontal: 16)),
        tabs: [
          Tab(text: isId ? 'Semua' : 'All'),
          Tab(text: isId ? 'Aktif' : 'Active'),
          Tab(text: isId ? 'Selesai' : 'Done'),
        ],
      ),
    );
}

// ── Project List ───────────────────────────────────────────────────────────────

class _ProjectList extends StatelessWidget {
  final List<_Proj> projects;
  final bool Function(_Proj)? filter;
  final void Function(_Proj) onReview;
  const _ProjectList({required this.projects, this.filter, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final list = filter == null ? projects : projects.where(filter!).toList();
    if (list.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => StaggerItem(
        index: i, fromY: 20,
        child: _ProjectCard(p: list[i], onReview: () => onReview(list[i]))),
    );
  }
}

// ── Project Card ───────────────────────────────────────────────────────────────

class _ProjectCard extends StatefulWidget {
  final _Proj p;
  final VoidCallback onReview;
  const _ProjectCard({required this.p, required this.onReview});
  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return SpringPress(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
      scaleDown: 0.985,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.status.bg, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: p.status.color)),
                    const SizedBox(width: 5),
                    Text(p.status.label, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: p.status.color)),
                  ])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: FPal.bgMuted, borderRadius: BorderRadius.circular(8)),
                  child: Text(p.category, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: FPal.inkMuted))),
                const Spacer(),
                Text(p.deadline, style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600,
                  color: p.status == _PStatus.done ? FPal.success : FPal.warning)),
              ]),
              const SizedBox(height: 10),
              Text(p.title, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: FPal.ink)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_rounded, size: 13, color: FPal.inkMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(p.freelancer, style: const TextStyle(
                  fontSize: 12.5, color: FPal.inkMuted), overflow: TextOverflow.ellipsis)),
                Text(p.budget, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: FPal.primary)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AnimatedProgressBar(
                  value: p.progress, color: p.status.color,
                  height: 8, delay: const Duration(milliseconds: 100))),
                const SizedBox(width: 10),
                Text('${(p.progress * 100).round()}%', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: p.status.color)),
              ]),
            ]),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _CardActions(p: p, onReview: widget.onReview),
            crossFadeState: _expanded
              ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250)),
        ]),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final _Proj p;
  final VoidCallback onReview;
  const _CardActions({required this.p, required this.onReview});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Row(children: [
      if (p.status != _PStatus.done) ...[
        Expanded(child: _ActionBtn(
          label: 'Chat', icon: Icons.chat_bubble_outline_rounded,
          color: FPal.primary, bg: FPal.primaryLight,
          onTap: () => Navigator.pop(context))),
        const SizedBox(width: 8),
        Expanded(child: _ActionBtn(
          label: 'Detail', icon: Icons.info_outline_rounded,
          color: const Color(0xFF0369A1), bg: const Color(0xFFE0F2FE),
          onTap: () => _showDetailSheet(context, p))),
      ] else
        Expanded(child: _ActionBtn(
          label: p.offerId != null ? 'Beri Rating' : 'Selesai',
          icon: Icons.star_outline_rounded,
          color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7),
          onTap: onReview)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
    required this.color, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => SpringPress(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12.5,
          fontWeight: FontWeight.w700, color: color)),
      ])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72,
        decoration: const BoxDecoration(color: FPal.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.assignment_outlined, size: 32, color: FPal.primary)),
      const SizedBox(height: 14),
      const Text('Belum ada proyek', style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, color: FPal.ink)),
      const SizedBox(height: 5),
      const Text('Proyek kamu akan muncul di sini.',
        style: TextStyle(fontSize: 13, color: FPal.inkMuted)),
    ]));
}

// ── Detail Sheet ────────────────────────────────────────────────────────────────

void _showDetailSheet(BuildContext ctx, _Proj p) {
  showModalBottomSheet(
    context: ctx, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => Container(
      margin: const EdgeInsets.fromLTRB(12, 60, 12, 28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFDDD9D4), borderRadius: BorderRadius.circular(2)))),
          const Text('Detail Proyek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: FPal.ink)),
          const SizedBox(height: 16),
          _dRow('Judul', p.title), _dRow('Freelancer', p.freelancer),
          _dRow('Kategori', p.category), _dRow('Budget', p.budget),
          _dRow('Deadline', p.deadline), _dRow('Progress', '${(p.progress * 100).round()}%'),
          _dRow('Status', p.status.label),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))),
        ]),
      )));
}

Widget _dRow(String label, String val) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12.5, color: FPal.inkMuted))),
    const Text(': ', style: TextStyle(color: FPal.inkMuted)),
    Expanded(child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FPal.ink))),
  ]));

// ── Rating Sheet — TERHUBUNG KE API ────────────────────────────────────────────

void _showRatingSheet(BuildContext ctx, _Proj p, OfferService offerSvc) {
  int sel = 5;
  final commentCtrl = TextEditingController();
  bool isSubmitting = false;

  showModalBottomSheet(
    context: ctx,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (bCtx) => StatefulBuilder(builder: (bCtx, setS) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFDDD9D4), borderRadius: BorderRadius.circular(2)))),
          Text('Rating untuk ${p.freelancer}', style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: FPal.ink)),
          const SizedBox(height: 20),
          // Star selector
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setS(() => sel = i + 1),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(i < sel ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFBBF24), size: 44))))),
          const SizedBox(height: 8),
          Text(sel == 5 ? '⭐ Luar biasa!'
              : sel == 4 ? '😊 Bagus sekali!'
              : sel >= 3 ? '🙂 Cukup baik'
              : '😐 Perlu perbaikan',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FPal.ink)),
          const SizedBox(height: 16),
          // Comment field
          TextField(
            controller: commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis komentar tentang pengerjaan proyek ini...',
              hintStyle: const TextStyle(color: FPal.inkMuted, fontSize: 13),
              filled: true, fillColor: FPal.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              setS(() => isSubmitting = true);
              try {
                final res = await offerSvc.submitReview(
                  int.parse(p.offerId!),
                  rating: sel,
                  comment: commentCtrl.text.trim(),
                );
                Navigator.pop(bCtx);
                if (res.success) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Review berhasil dikirim! Terima kasih.'),
                    backgroundColor: FPal.primary, behavior: SnackBarBehavior.floating));
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(res.message ?? 'Gagal mengirim review'),
                    backgroundColor: FPal.danger, behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setS(() => isSubmitting = false);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: FPal.danger, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: FPal.primary, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Kirim Review',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))),
        ]),
      ),
    )));
}

// ── Data structs ───────────────────────────────────────────────────────────────

enum _PStatus { new_, onTrack, review, done }

extension on _PStatus {
  String get label => switch (this) {
    _PStatus.new_    => 'Baru',
    _PStatus.onTrack => 'Berjalan',
    _PStatus.review  => 'Ditinjau',
    _PStatus.done    => 'Selesai',
  };
  Color get color => switch (this) {
    _PStatus.new_    => const Color(0xFF0369A1),
    _PStatus.onTrack => FPal.primary,
    _PStatus.review  => const Color(0xFFD97706),
    _PStatus.done    => const Color(0xFF059669),
  };
  Color get bg => switch (this) {
    _PStatus.new_    => const Color(0xFFE0F2FE),
    _PStatus.onTrack => FPal.primaryLight,
    _PStatus.review  => const Color(0xFFFEF3C7),
    _PStatus.done    => const Color(0xFFD1FAE5),
  };
}

class _Proj {
  final String title, freelancer, category, budget, deadline;
  final double progress;
  final _PStatus status;
  final String? offerId;
  final int budgetRaw;
  const _Proj(this.title, this.freelancer, this.category, this.progress,
    this.status, this.budget, this.deadline, this.offerId, this.budgetRaw);
}
