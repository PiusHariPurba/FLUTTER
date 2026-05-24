// ─────────────────────────────────────────────────────────────────────────────
//  freelancer_progress_screen.dart
//
//  FIXED:
//    - Sebelumnya: OfferProvider.fetchMyOffers() hard-return []. Screen ini
//      selalu tampil empty state walau ada offer accepted di DB.
//    - Sekarang: panggil GET /freelancer/progress yang di-handle
//      ProgressController.dashboard() → data real dari DB.
//      FreelancerWorkItem.fromProgressApi() dipakai untuk parsing response.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../models/task_models.dart';
import '../../services/offer_service.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/app_theme.dart';

class FreelancerProgressScreen extends StatefulWidget {
  const FreelancerProgressScreen({super.key});

  @override
  State<FreelancerProgressScreen> createState() =>
      _FreelancerProgressScreenState();
}

class _FreelancerProgressScreenState extends State<FreelancerProgressScreen> {
  final _svc = OfferService();

  bool _isLoading = true;
  String? _error;

  int _activeJobs = 0;
  int _nearestDeadlines = 0;
  List<FreelancerWorkItem> _projects = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // FIXED: panggil GET /freelancer/progress (route yang sebelumnya hilang)
      final res = await _svc.getProgressDashboard();

      if (!mounted) return;

      if (res.success) {
        final d = res['data'] as Map<String, dynamic>? ?? {};

        _activeJobs       = (d['active_jobs'] as num?)?.toInt() ?? 0;
        _nearestDeadlines = (d['nearest_deadlines'] as num?)?.toInt() ?? 0;

        final rawProjects = d['running_projects'] as List<dynamic>? ?? [];
        _projects = rawProjects
            .map((p) => FreelancerWorkItem.fromProgressApi(
                p as Map<String, dynamic>))
            .toList();
      } else {
        _error = res.message ?? 'Gagal memuat data progress';
      }
    } catch (e) {
      _error = 'Terjadi error: $e';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Progress Kerja',
              style: TextStyle(
                color: FPal.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FPal.primary))
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: FPal.primary,
                    onRefresh: _load,
                    child: _projects.isEmpty
                        ? const _EmptyState()
                        : _ProjectList(
                            activeJobs: _activeJobs,
                            nearestDeadlines: _nearestDeadlines,
                            projects: _projects,
                            onUpdateProgress: _load,
                          ),
                  ),
      ),
    );
  }
}

// ── Stats Header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int activeJobs, nearestDeadlines;
  const _StatsHeader({
    required this.activeJobs,
    required this.nearestDeadlines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FPal.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _StatBox(label: 'Aktif', value: '$activeJobs'),
        const SizedBox(width: 12),
        Container(width: 1, height: 40, color: Colors.white24),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Deadline ≤ 3 hari',
          value: '$nearestDeadlines',
          valueColor: nearestDeadlines > 0
              ? const Color(0xFFFBBF24)
              : Colors.white,
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor ?? Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ]),
      );
}

// ── Project List ──────────────────────────────────────────────────────────────

class _ProjectList extends StatelessWidget {
  final int activeJobs, nearestDeadlines;
  final List<FreelancerWorkItem> projects;
  final VoidCallback onUpdateProgress;

  const _ProjectList({
    required this.activeJobs,
    required this.nearestDeadlines,
    required this.projects,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: projects.length + 1, // +1 untuk header stats
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox.shrink() : const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _StatsHeader(
            activeJobs: activeJobs,
            nearestDeadlines: nearestDeadlines,
          );
        }
        final item = projects[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ProgressCard(
            item: item,
            onTapUpdate: onUpdateProgress,
          ),
        );
      },
    );
  }
}

// ── Progress Card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final FreelancerWorkItem item;
  final VoidCallback onTapUpdate;
  const _ProgressCard({required this.item, required this.onTapUpdate});

  Color _statusColor() {
    switch (item.workStatus) {
      case 'completed':   return const Color(0xFF16A34A);
      case 'revision':    return FPal.danger;
      case 'in_progress': return const Color(0xFFF59E0B);
      default:            return FPal.primary;
    }
  }

  String _statusLabel() {
    switch (item.workStatus) {
      case 'completed':   return 'Selesai';
      case 'revision':    return 'Revisi';
      case 'in_progress': return 'Sedang Dikerjakan';
      default:            return 'On Track';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return BounceIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + status badge
          Row(children: [
            Expanded(
              child: Text(
                item.taskTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: FPal.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 6),

          Text(
            item.clientName,
            style: const TextStyle(fontSize: 12.5, color: FPal.inkMuted),
          ),

          const SizedBox(height: 12),

          // Progress bar
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.progress / 100,
                  backgroundColor: const Color(0xFFE8E5E0),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${item.progress}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Deadline info
          Row(children: [
            Icon(
              item.deadlineType == 'warning'
                  ? Icons.warning_rounded
                  : Icons.schedule_rounded,
              size: 14,
              color: item.deadlineType == 'warning'
                  ? const Color(0xFFD97706)
                  : FPal.inkMuted,
            ),
            const SizedBox(width: 4),
            Text(
              item.deadlineLabel,
              style: TextStyle(
                fontSize: 12,
                color: item.deadlineType == 'warning'
                    ? const Color(0xFFD97706)
                    : FPal.inkMuted,
                fontWeight: item.deadlineType == 'warning'
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // Budget
            Icon(Icons.attach_money_rounded,
                size: 14, color: FPal.inkMuted),
            const SizedBox(width: 2),
            Text(
              'Rp ${_fmt(item.agreedBudget)}',
              style: const TextStyle(fontSize: 12, color: FPal.inkMuted),
            ),
          ]),

          // Progress notes
          if (item.progressNotes != null &&
              item.progressNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FPal.bgMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.progressNotes!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: FPal.inkMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Next step hint
          const SizedBox(height: 10),
          Text(
            item.nextStep,
            style: const TextStyle(
              fontSize: 11.5,
              color: FPal.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),

          // "Rate Client" button — tampil ketika task completed
          if (item.workStatus == 'completed') ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEECE8)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showClientRatingSheet(context, item),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Text('Beri Penilaian ke Client', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

// ── Client Rating Sheet (Freelancer → Client) ────────────────────────────────

void _showClientRatingSheet(BuildContext ctx, FreelancerWorkItem item) {
  int sel = 5;
  final commentCtrl = TextEditingController();
  bool isSubmitting = false;
  final offerSvc = OfferService();

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
          Text('Penilaian untuk ${item.clientName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FPal.ink),
            textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text('Bagaimana pengalaman bekerja dengan client ini?',
            style: TextStyle(fontSize: 12.5, color: FPal.inkMuted),
            textAlign: TextAlign.center),
          const SizedBox(height: 18),
          // Star selector
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setS(() => sel = i + 1),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(i < sel ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFBBF24), size: 42))))),
          const SizedBox(height: 8),
          Text(sel == 5 ? '⭐ Client terbaik!'
              : sel == 4 ? '😊 Komunikasi bagus'
              : sel >= 3 ? '🙂 Cukup kooperatif'
              : '😐 Kurang responsif',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FPal.ink)),
          const SizedBox(height: 14),
          TextField(
            controller: commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalamanmu bekerja dengan client ini...',
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
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              setS(() => isSubmitting = true);
              try {
                final res = await offerSvc.submitReview(
                  int.parse(item.id),
                  rating: sel,
                  comment: commentCtrl.text.trim(),
                );
                Navigator.pop(bCtx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(res.success
                      ? 'Penilaian berhasil dikirim!'
                      : (res.message ?? 'Gagal mengirim penilaian')),
                  backgroundColor: res.success ? FPal.primary : FPal.danger,
                  behavior: SnackBarBehavior.floating));
              } catch (e) {
                setS(() => isSubmitting = false);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: FPal.danger,
                  behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706), elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Kirim Penilaian',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)))),
        ]),
      ),
    )));
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          Icons.work_outline_rounded,
          size: 72,
          color: FPal.inkMuted.withOpacity(0.35),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum ada pekerjaan aktif',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: FPal.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Offer yang diterima client akan muncul di sini',
          style: TextStyle(fontSize: 13, color: FPal.inkMuted),
        ),
      ]),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_rounded,
              size: 64, color: FPal.inkMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: FPal.inkMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FPal.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}
