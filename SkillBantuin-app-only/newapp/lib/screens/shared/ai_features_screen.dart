import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import '../../ai/ai_service.dart';
import '../../ai/sentiment_analyzer.dart';
import '../../ai/fuzzy_matcher.dart';
import '../../ai/genetic_optimizer.dart';
import '../../ai/concept_learner.dart';
import '../../ai/search_engine.dart';
import '../../models/task_models.dart';

/// Halaman demonstrasi interaktif semua modul AI SkillBantuin
class AIFeaturesScreen extends StatefulWidget {
  const AIFeaturesScreen({super.key});

  @override
  State<AIFeaturesScreen> createState() => _AIFeaturesScreenState();
}

class _AIFeaturesScreenState extends State<AIFeaturesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.bg,
      appBar: AppBar(
        title: const Text('Fitur AI SkillBantuin'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.search_rounded, size: 16), text: 'BM25'),
            Tab(icon: Icon(Icons.psychology_rounded, size: 16), text: 'Pakar'),
            Tab(icon: Icon(Icons.translate_rounded, size: 16), text: 'NLP'),
            Tab(icon: Icon(Icons.blur_on_rounded, size: 16), text: 'Fuzzy'),
            Tab(icon: Icon(Icons.biotech_rounded, size: 16), text: 'GA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BM25DemoTab(),
          _ExpertDemoTab(),
          _NLPDemoTab(),
          _FuzzyDemoTab(),
          _GADemoTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: BM25 Demo ────────────────────────────────────────────────────────

class _BM25DemoTab extends StatefulWidget {
  const _BM25DemoTab();
  @override
  State<_BM25DemoTab> createState() => _BM25DemoTabState();
}

class _BM25DemoTabState extends State<_BM25DemoTab> {
  final _ctrl = TextEditingController();
  List<TaskSearchResult> _results = [];

  // Dokumen dummy untuk demo
  static final _demoTasks = [
    const _DemoTask('Instalasi Atap Baja Ringan', 'Konstruksi', 'Pemasangan atap baja ringan untuk rumah 2 lantai di Surabaya', 2500000),
    const _DemoTask('Desain Logo Startup', 'Desain Grafis', 'Buat logo modern untuk startup teknologi fintech', 800000),
    const _DemoTask('Perbaikan Plafon Retak', 'Konstruksi', 'Perbaikan plafon gypsum yang retak dan bocor', 500000),
    const _DemoTask('Website Company Profile', 'IT & Web', 'Buat website company profile responsif dengan CMS', 3000000),
    const _DemoTask('Pemasangan Keramik', 'Konstruksi', 'Pemasangan keramik lantai dan dinding kamar mandi', 1200000),
    const _DemoTask('Aplikasi Mobile Android', 'IT & Web', 'Develop aplikasi tracking order untuk UMKM', 5000000),
    const _DemoTask('Cat Ulang Rumah', 'Renovasi', 'Pengecatan interior dan eksterior rumah 3 kamar', 1800000),
    const _DemoTask('Instalasi Listrik', 'Elektrikal', 'Instalasi listrik baru untuk rumah baru', 900000),
  ];

  void _search(String query) {
    final avTasks = _demoTasks.map((d) => _toAvailableTask(d)).toList();
    final results = AIService.instance.searchTasks(avTasks, query);
    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.search_rounded,
            title: 'BM25 — Best Match 25',
            subtitle: 'Algoritma ranking IR yang memperhitungkan TF-IDF + normalisasi panjang dokumen.',
            color: const Color(0xFF2980B9),
          ),
          const SizedBox(height: 14),
          _InfoFormula(
            formula: 'Score(D,Q) = Σ IDF(qi) × tf(qi,D)×(k₁+1) / [tf + k₁×(1−b+b×|D|/avgdl)]',
            params: 'k₁=1.5 (saturasi TF)  •  b=0.75 (normalisasi panjang)',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE2EE)),
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Coba: "atap baja", "website", "instalasi"...',
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF2980B9)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_results.isEmpty && _ctrl.text.isNotEmpty)
            const _EmptyState(message: 'Tidak ada hasil')
          else
            ..._results.map((r) => _BM25ResultRow(result: r)),
          if (_results.isEmpty && _ctrl.text.isEmpty)
            const _EmptyState(message: 'Ketik query untuk melihat ranking BM25'),
        ],
      ),
    );
  }
}

class _BM25ResultRow extends StatelessWidget {
  final TaskSearchResult result;
  const _BM25ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.task.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Pal.ink, fontSize: 13)),
                const SizedBox(height: 3),
                Text(result.task.category, style: const TextStyle(color: Pal.inkMuted, fontSize: 11)),
                if (result.highlights.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Match: ${result.highlights.join(", ")}', style: const TextStyle(color: Color(0xFF2980B9), fontSize: 10)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(result.score * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2980B9), fontSize: 15)),
              const Text('skor', style: TextStyle(fontSize: 9, color: Pal.inkMuted)),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: result.score,
                    backgroundColor: const Color(0xFFDEEDFF),
                    color: const Color(0xFF2980B9),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Expert System Demo ───────────────────────────────────────────────

class _ExpertDemoTab extends StatefulWidget {
  const _ExpertDemoTab();
  @override
  State<_ExpertDemoTab> createState() => _ExpertDemoTabState();
}

class _ExpertDemoTabState extends State<_ExpertDemoTab> {
  double _rating = 4.5;
  int _tasks = 15;
  int _budget = 1000000;
  int _clientBudget = 1200000;

  @override
  Widget build(BuildContext context) {
    // Buat fake offer & task untuk demo
    final offer = _makeFakeOffer(rating: _rating, tasks: _tasks, budget: _budget);
    final task = _makeFakeTask(budget: _clientBudget);
    final recs = AIService.instance.rankOffers([offer], task);
    final rec = recs.isNotEmpty ? recs.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.psychology_rounded,
            title: 'Sistem Pakar — Forward Chaining',
            subtitle: 'Knowledge base berbasis aturan IF-THEN. Mekanisme: forward chaining mengakumulasi bobot aturan yang terpicu.',
            color: const Color(0xFF8E44AD),
          ),
          const SizedBox(height: 14),
          // Sliders
          _SliderControl(label: 'Rating Freelancer', value: _rating, min: 1.0, max: 5.0, divisions: 40, display: _rating.toStringAsFixed(1), onChanged: (v) => setState(() => _rating = v)),
          _SliderControl(label: 'Tugas Selesai', value: _tasks.toDouble(), min: 0, max: 50, divisions: 50, display: '$_tasks', onChanged: (v) => setState(() => _tasks = v.round())),
          _SliderControl(label: 'Budget Tawaran', value: _budget.toDouble(), min: 500000, max: 2000000, divisions: 30, display: 'Rp ${_formatK(_budget)}', onChanged: (v) => setState(() => _budget = v.round())),
          _SliderControl(label: 'Budget Client', value: _clientBudget.toDouble(), min: 500000, max: 2000000, divisions: 30, display: 'Rp ${_formatK(_clientBudget)}', onChanged: (v) => setState(() => _clientBudget = v.round())),
          const SizedBox(height: 14),
          if (rec != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Skor Pakar:', style: TextStyle(fontWeight: FontWeight.w700, color: Pal.ink)),
                      const Spacer(),
                      Text('${(rec.score * 100).round()}/100', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8E44AD), fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: rec.score, backgroundColor: const Color(0xFFEEDDFF), color: const Color(0xFF8E44AD), minHeight: 8),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF8E44AD).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(rec.verdict, style: const TextStyle(color: Color(0xFF8E44AD), fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Aturan yang Terpicu:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pal.ink)),
                  const SizedBox(height: 6),
                  ...rec.firedRules.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF8E44AD)),
                        const SizedBox(width: 6),
                        Expanded(child: Text('[${r.id}] ${r.description} (+${r.weight})', style: const TextStyle(fontSize: 11, color: Pal.inkSoft))),
                      ],
                    ),
                  )),
                  if (rec.firedRules.isEmpty)
                    const Text('Tidak ada aturan terpicu', style: TextStyle(fontSize: 11, color: Pal.inkMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 3: NLP Sentiment Demo ───────────────────────────────────────────────

class _NLPDemoTab extends StatefulWidget {
  const _NLPDemoTab();
  @override
  State<_NLPDemoTab> createState() => _NLPDemoTabState();
}

class _NLPDemoTabState extends State<_NLPDemoTab> {
  final _ctrl = TextEditingController();
  SentimentResult? _result;

  static const _presets = [
    'Freelancer sangat profesional dan tepat waktu! Sangat memuaskan.',
    'Pekerjaan mengecewakan, lambat dan tidak sesuai ekspektasi.',
    'Hasilnya lumayan, ada beberapa hal yang perlu diperbaiki.',
    'Highly professional and responsive, I really recommend this freelancer!',
    'Tidak jujur dan kabur setelah pembayaran. Penipuan!',
  ];

  void _analyze(String text) {
    if (text.trim().isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() => _result = AIService.instance.analyzeSentiment(text));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.translate_rounded,
            title: 'NLP — Analisis Sentimen Ulasan',
            subtitle: 'VADER-inspired lexicon analysis dengan deteksi negasi, amplifier, dan compound score. Mendukung Bahasa Indonesia & Inggris.',
            color: const Color(0xFF27AE60),
          ),
          const SizedBox(height: 14),
          _InfoFormula(
            formula: 'compound = rawScore / √(rawScore² + α)  [α=15]',
            params: 'Positif ≥ 0.05  •  Negatif ≤ -0.05  •  Netral: antara keduanya',
          ),
          const SizedBox(height: 12),
          // Preset chips
          const Text('Contoh cepat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pal.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _presets.map((p) => ActionChip(
              label: Text(p.substring(0, p.length.clamp(0, 28)) + (p.length > 28 ? '…' : ''), style: const TextStyle(fontSize: 11)),
              onPressed: () { _ctrl.text = p; _analyze(p); },
              backgroundColor: Pal.bgMuted,
            )).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDDE2EE))),
            child: TextField(
              controller: _ctrl,
              onChanged: _analyze,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ketik atau pilih contoh di atas...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 13, color: Pal.inkMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_result != null) _SentimentResultCard(result: _result!),
        ],
      ),
    );
  }
}

class _SentimentResultCard extends StatelessWidget {
  final SentimentResult result;
  const _SentimentResultCard({required this.result});

  Color get _mainColor => result.label == SentimentLabel.positive
      ? const Color(0xFF27AE60)
      : result.label == SentimentLabel.negative
          ? const Color(0xFFE74C3C)
          : const Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mainColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(result.label.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.label.display, style: TextStyle(fontWeight: FontWeight.w800, color: _mainColor, fontSize: 16)),
                  Text('Keyakinan: ${result.confidencePercent}%', style: const TextStyle(fontSize: 11, color: Pal.inkMuted)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(result.compoundScore.toStringAsFixed(3), style: TextStyle(fontWeight: FontWeight.w900, color: _mainColor, fontSize: 18)),
                  const Text('compound', style: TextStyle(fontSize: 9, color: Pal.inkMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sentiment bar (-1 to +1)
          Row(
            children: [
              const Text('-1', style: TextStyle(fontSize: 10, color: Color(0xFFE74C3C))),
              const SizedBox(width: 4),
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: 1.0, backgroundColor: const Color(0xFFFFE8E8), color: const Color(0xFFFFE8E8), minHeight: 8),
                    ),
                    Align(
                      alignment: Alignment((result.compoundScore).clamp(-1.0, 1.0), 0),
                      child: Container(width: 3, height: 12, color: _mainColor),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FractionallySizedBox(
                        widthFactor: (result.compoundScore + 1) / 2,
                        child: Container(height: 8, color: _mainColor.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Text('+1', style: TextStyle(fontSize: 10, color: Color(0xFF27AE60))),
            ],
          ),
          if (result.tokenScores.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Token Berpengaruh:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pal.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: result.tokenScores.map((ts) {
                final isPos = ts.adjustedScore > 0;
                final col = isPos ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: col.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${ts.wasNegated ? "¬" : ""}${ts.token}  ${isPos ? "+" : ""}${ts.adjustedScore.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: col, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 4: Fuzzy Logic Demo ─────────────────────────────────────────────────

class _FuzzyDemoTab extends StatefulWidget {
  const _FuzzyDemoTab();
  @override
  State<_FuzzyDemoTab> createState() => _FuzzyDemoTabState();
}

class _FuzzyDemoTabState extends State<_FuzzyDemoTab> {
  double _rating = 4.3;
  int _completedTasks = 20;
  int _taskBudget = 1500000;
  int _offeredBudget = 1200000;

  @override
  Widget build(BuildContext context) {
    final result = AIService.instance.evaluateSuitability(
      taskBudget: _taskBudget,
      offeredBudget: _offeredBudget,
      rating: _rating,
      completedTasks: _completedTasks,
    );
    final hexColor = Color(int.parse(result.colorHex.replaceFirst('#', '0xFF')));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.blur_on_rounded,
            title: 'Logika Fuzzy — FIS Mamdani',
            subtitle: 'Fuzzy Inference System 3 input: budget gap, rating, pengalaman → output: skor kesesuaian (0–100).',
            color: const Color(0xFF9B59B6),
          ),
          const SizedBox(height: 14),
          _InfoFormula(
            formula: 'Pipeline: Fuzzifikasi → Evaluasi IF-THEN (20 aturan) → Agregasi (max) → Defuzzifikasi (centroid)',
            params: 'Fungsi keanggotaan: trapezoid, segitiga, shoulder',
          ),
          const SizedBox(height: 14),
          _SliderControl(label: 'Rating', value: _rating, min: 1.0, max: 5.0, divisions: 40, display: _rating.toStringAsFixed(1), onChanged: (v) => setState(() => _rating = v)),
          _SliderControl(label: 'Tugas Selesai', value: _completedTasks.toDouble(), min: 0, max: 80, divisions: 80, display: '$_completedTasks', onChanged: (v) => setState(() => _completedTasks = v.round())),
          _SliderControl(label: 'Budget Task', value: _taskBudget.toDouble(), min: 500000, max: 3000000, divisions: 50, display: 'Rp ${_formatK(_taskBudget)}', onChanged: (v) => setState(() => _taskBudget = v.round())),
          _SliderControl(label: 'Budget Tawaran', value: _offeredBudget.toDouble(), min: 300000, max: 3500000, divisions: 60, display: 'Rp ${_formatK(_offeredBudget)}', onChanged: (v) => setState(() => _offeredBudget = v.round())),
          const SizedBox(height: 16),
          // Result card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Skor Kesesuaian Fuzzy', style: TextStyle(fontWeight: FontWeight.w700, color: Pal.ink)),
                          Text(result.label, style: TextStyle(fontWeight: FontWeight.w600, color: hexColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${result.scoreInt}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: hexColor)),
                    Text(' /100', style: TextStyle(color: hexColor.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: result.score / 100, backgroundColor: hexColor.withValues(alpha: 0.15), color: hexColor, minHeight: 12),
                ),
                const SizedBox(height: 14),
                // Membership breakdown (key ones)
                const Text('Derajat Keanggotaan (top):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pal.ink)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: result.membershipBreakdown.entries
                      .where((e) => e.value > 0.01 && !e.key.startsWith('budget_gap'))
                      .map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBF8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${e.key}: ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Color(0xFF9B59B6), fontWeight: FontWeight.w600)),
                      )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 5: Genetic Algorithm Demo ──────────────────────────────────────────

class _GADemoTab extends StatefulWidget {
  const _GADemoTab();
  @override
  State<_GADemoTab> createState() => _GADemoTabState();
}

class _GADemoTabState extends State<_GADemoTab> {
  double _rating = 4.2;
  int _completedTasks = 12;
  int _clientBudget = 2000000;
  int _clientDeadline = 30;
  GAResult? _result;
  bool _loading = false;

  Future<void> _runGA() async {
    setState(() { _loading = true; _result = null; });
    await Future.delayed(const Duration(milliseconds: 700));
    final r = AIService.instance.optimizeOffer(
      clientBudget: _clientBudget,
      clientDeadlineDays: _clientDeadline,
      freelancerRating: _rating,
      completedTasks: _completedTasks,
    );
    setState(() { _result = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.biotech_rounded,
            title: 'Algoritma Genetika — Optimasi Penawaran',
            subtitle: 'GA menemukan budget & deadline optimal via seleksi tournament + uniform crossover + gaussian mutation + elitisme.',
            color: const Color(0xFF2980B9),
          ),
          const SizedBox(height: 14),
          _InfoFormula(
            formula: 'Fitness = budget×0.4 + deadline×0.3 + kredibilitas×0.3',
            params: 'Pop: 60  •  Gen: 80  •  Crossover: 80%  •  Mutasi: 15%  •  Elite: 3',
          ),
          const SizedBox(height: 14),
          _SliderControl(label: 'Rating Freelancer', value: _rating, min: 1.0, max: 5.0, divisions: 40, display: _rating.toStringAsFixed(1), onChanged: (v) => setState(() { _rating = v; _result = null; })),
          _SliderControl(label: 'Tugas Selesai', value: _completedTasks.toDouble(), min: 0, max: 50, divisions: 50, display: '$_completedTasks', onChanged: (v) => setState(() { _completedTasks = v.round(); _result = null; })),
          _SliderControl(label: 'Budget Client', value: _clientBudget.toDouble(), min: 500000, max: 5000000, divisions: 90, display: 'Rp ${_formatK(_clientBudget)}', onChanged: (v) => setState(() { _clientBudget = v.round(); _result = null; })),
          _SliderControl(label: 'Deadline Client (hari)', value: _clientDeadline.toDouble(), min: 3, max: 90, divisions: 87, display: '$_clientDeadline hari', onChanged: (v) => setState(() { _clientDeadline = v.round(); _result = null; })),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _runGA,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_loading ? 'Menjalankan GA...' : 'Jalankan Algoritma Genetika'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2980B9), foregroundColor: Colors.white),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Color(0xFF2980B9), size: 18),
                      SizedBox(width: 6),
                      Text('Hasil Optimasi', style: TextStyle(fontWeight: FontWeight.w800, color: Pal.ink, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _GAResultTile(label: 'Budget Optimal', value: 'Rp ${_formatK(_result!.recommendedBudget)}', icon: Icons.payments_outlined, color: const Color(0xFF2980B9))),
                      const SizedBox(width: 10),
                      Expanded(child: _GAResultTile(label: 'Deadline Optimal', value: _result!.deadlineLabel, icon: Icons.schedule_rounded, color: const Color(0xFF2980B9))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Fitness Score: ${_result!.fitnessPercent}%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2980B9))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: _result!.fitnessScore, backgroundColor: const Color(0xFFDEEDFF), color: const Color(0xFF2980B9), minHeight: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_result!.explanation, style: const TextStyle(fontSize: 12, color: Pal.inkSoft, height: 1.4)),
                  // Convergence chart
                  if (_result!.fitnessHistory.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Kurva Konvergensi (fitness per generasi):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pal.ink)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: CustomPaint(
                        painter: _ConvergencePainter(_result!.fitnessHistory),
                        child: Container(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GAResultTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _GAResultTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Pal.inkMuted)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          )),
        ],
      ),
    );
  }
}

/// Painter untuk kurva konvergensi GA
class _ConvergencePainter extends CustomPainter {
  final List<double> history;
  const _ConvergencePainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final paint = Paint()
      ..color = const Color(0xFF2980B9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = const Color(0xFFDEEDFF)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final dx = size.width / (history.length - 1);

    final maxVal = history.reduce((a, b) => a > b ? a : b);
    final minVal = history.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    double y(double v) => range < 0.001 ? size.height / 2 : size.height - ((v - minVal) / range * (size.height - 10) + 5);

    fillPath.moveTo(0, size.height);
    for (int i = 0; i < history.length; i++) {
      final x = i * dx;
      final yVal = y(history[i]);
      if (i == 0) {
        path.moveTo(x, yVal);
        fillPath.lineTo(x, yVal);
      } else {
        path.lineTo(x, yVal);
        fillPath.lineTo(x, yVal);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, bgPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConvergencePainter old) => old.history != history;
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Pal.inkSoft, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFormula extends StatelessWidget {
  final String formula;
  final String params;
  const _InfoFormula({required this.formula, required this.params});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F7F4), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formula, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Pal.ink, height: 1.4)),
          const SizedBox(height: 4),
          Text(params, style: const TextStyle(fontSize: 10, color: Pal.inkMuted)),
        ],
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;
  const _SliderControl({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.display, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pal.inkSoft)),
          ),
          Expanded(child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged)),
          SizedBox(
            width: 70,
            child: Text(display, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Pal.ink), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: const TextStyle(color: Pal.inkMuted, fontSize: 13)),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatK(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
  if (v >= 1000) return '${(v / 1000).round()}rb';
  return '$v';
}

// Helper to create fake VolunteerOffer for demo

VolunteerOffer _makeFakeOffer({required double rating, required int tasks, required int budget}) {
  return VolunteerOffer(
    id: 'demo',
    freelancerName: 'Demo Freelancer',
    freelancerSkill: 'Konstruksi',
    rating: rating,
    completedTasks: tasks,
    offeredBudget: budget,
    proposedDeadline: '7 hari',
    message: 'Saya berpengalaman dan siap mengerjakan proyek ini dengan profesional.',
    status: OfferStatus.pending,
  );
}

ClientTask _makeFakeTask({required int budget}) {
  return ClientTask(
    id: 'demo',
    title: 'Demo Task',
    category: 'Konstruksi',
    description: 'Demo task untuk demonstrasi sistem pakar.',
    initialBudget: budget,
    deadlineLabel: '14 hari',
    createdAtLabel: '1 hari lalu',
    status: TaskStatus.open,
    paymentStatus: PaymentStatus.unpaid,
    assistanceType: AssistanceType.onsite,
    nearestAction: '',
    progress: 0,
    offers: [],
  );
}

class _DemoTask {
  final String title;
  final String category;
  final String description;
  final int budget;
  const _DemoTask(this.title, this.category, this.description, this.budget);
}

AvailableTask _toAvailableTask(_DemoTask d) => AvailableTask(
  id: d.title,
  title: d.title,
  category: d.category,
  description: d.description,
  initialBudget: d.budget,
  deadlineLabel: '7 hari',
  assistanceType: AssistanceType.onsite,
  clientName: 'Client Demo',
  postedLabel: '1 hari lalu',
  applicantsCount: 0,
  budgetRangeLabel: 'Rp ${_formatK(d.budget)}',
  location: 'Surabaya',
);
