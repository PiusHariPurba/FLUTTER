// ─────────────────────────────────────────────────────────────────────────────
//  freelancer_search_screen.dart  —  L99 Edition
//  Search Task/Proyek · Algoritma Genetika · 9 filter · Radar Chart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../ai/genetic_search.dart';
import '../../models/task_models.dart';
import '../../providers/providers.dart';
import '../../widgets/app_theme.dart';

class FreelancerSearchScreen extends StatefulWidget {
  const FreelancerSearchScreen({super.key});
  @override
  State<FreelancerSearchScreen> createState() => _FreelancerSearchScreenState();
}

class _FreelancerSearchScreenState extends State<FreelancerSearchScreen>
    with SingleTickerProviderStateMixin {

  final _searchCtrl = TextEditingController();
  late final AnimationController _pulseCtrl;

  SearchFilter _filter    = const SearchFilter();
  bool _showFilter        = false;
  bool _showGAPanel       = false;
  bool _isRunning         = false;
  SortMode _sortMode      = SortMode.gaOptimal;

  int              _currentGen  = 0;
  int              _totalGen    = 60;
  GenerationStat?  _latestStat;
  List<GenerationStat> _allStats = [];
  GARunResult<AvailableTask>? _gaResult;

  final List<String> _recentSearches = [];

  static const _suggestions = [
    'Desain Logo', 'Landing Page', 'Flutter App', 'SEO Artikel',
    'Edit Video', 'Copywriting', 'Data Analysis', 'Social Media',
    'WordPress', 'UI Mockup', 'Motion Graphic', 'Python Script',
  ];

  static const _quickFilters = [
    ('🆕 Terbaru', 'new'),
    ('🏆 Budget Besar', 'big'),
    ('⚡ Deadline Fleksibel', 'flex'),
    ('🌐 Remote', 'remote'),
    ('👤 Sedikit Pelamar', 'low'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _searchCtrl.addListener(_onQuery);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  DateTime? _lastTyped;
  void _onQuery() {
    final now = _lastTyped = DateTime.now();
    if (_searchCtrl.text.trim().isEmpty) return;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (_lastTyped == now && mounted) _runGA();
    });
  }

  void _applyQuick(String key) {
    setState(() {
      _filter = switch (key) {
        'new'    => _filter.copyWith(responseTimePref: '<1j'),
        'big'    => _filter.copyWith(minPrice: 5000000),
        'flex'   => _filter.copyWith(urgentOnly: false),
        'remote' => _filter.copyWith(locationPref: LocationPref.remote),
        'low'    => _filter.copyWith(maxApplicants: 5),
        _        => _filter,
      };
    });
    _runGA();
  }

  Future<void> _runGA() async {
    final raw  = context.read<TaskProvider>().tasks;
    final data = raw.isNotEmpty
        ? raw.map((m) => AvailableTask.fromApiJson(m)).toList()
        : _dummyTasks;

    final currentFilter = _filter.copyWith(query: _searchCtrl.text.trim());

    setState(() {
      _isRunning = true; _currentGen = 0;
      _allStats = []; _latestStat = null; _gaResult = null;
    });
    HapticFeedback.selectionClick();

    final result = await GeneticSearchEngine.searchTasks(
      tasks:  data,
      filter: currentFilter,
      onProgress: (gen, total, stat) {
        if (!mounted) return;
        setState(() {
          _currentGen = gen; _totalGen = total;
          _latestStat = stat; _allStats.add(stat);
        });
      },
    );

    if (!mounted) return;
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty && !_recentSearches.contains(q)) {
      _recentSearches.insert(0, q);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    }
    setState(() { _isRunning = false; _gaResult = result; });
    HapticFeedback.mediumImpact();
  }

  List<GASearchResult<AvailableTask>> get _sortedResults {
    final r = List<GASearchResult<AvailableTask>>.from(_gaResult?.results ?? []);
    switch (_sortMode) {
      case SortMode.gaOptimal: break;
      case SortMode.price:
        r.sort((a, b) => b.item.initialBudget.compareTo(a.item.initialBudget)); break;
      case SortMode.recency:
        r.sort((a, b) => b.rawScores.responseSpeed.compareTo(a.rawScores.responseSpeed)); break;
      case SortMode.competition:
        r.sort((a, b) => a.item.applicantsCount.compareTo(b.item.applicantsCount)); break;
      default: break;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      body: SafeArea(child: Column(children: [
        _buildHeader(),

        if (!_showFilter && !_isRunning && _gaResult == null)
          _QuickFilterRow(filters: _quickFilters, onSelect: _applyQuick),

        if (_gaResult != null && !_isRunning)
          _GAToggleBar(
            label:     '${_gaResult!.results.length} proyek · ${_gaResult!.convergenceLabel}',
            desc:      _gaResult!.convergenceDescription,
            showPanel: _showGAPanel,
            onToggle:  () => setState(() => _showGAPanel = !_showGAPanel),
          ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: _showGAPanel || _isRunning
              ? _GAPanel(
                  isRunning:  _isRunning,
                  currentGen: _currentGen,
                  totalGen:   _totalGen,
                  stats:      _allStats,
                  latestStat: _latestStat,
                  result:     _gaResult,
                  pulseCtrl:  _pulseCtrl,
                )
              : const SizedBox.shrink(),
        ),

        if (_gaResult != null && !_isRunning && !_showFilter)
          _SortBar(
            current:     _sortMode,
            count:       _gaResult!.results.length,
            filterCount: _filter.activeFilterCount,
            onChange:    (m) => setState(() => _sortMode = m),
          ),

        Expanded(child: _showFilter
            ? _FilterPanel(
                filter:   _filter,
                onChange: (f) => setState(() => _filter = f),
                onApply:  () { setState(() => _showFilter = false); _runGA(); },
                onReset:  () => setState(() {
                  _filter = const SearchFilter();
                  _showFilter = false; _gaResult = null;
                }),
              )
            : _gaResult == null && !_isRunning
                ? _EmptyView(
                    recent:      _recentSearches,
                    suggestions: _suggestions,
                    onSuggest:   (s) { _searchCtrl.text = s; _runGA(); },
                  )
                : _isRunning
                    ? _ResultSkeleton()
                    : _TaskResultList(results: _sortedResults)),
      ])),
    );
  }

  Widget _buildHeader() {
    final fc = _filter.activeFilterCount;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: FPal.bgMuted, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded, color: FPal.inkMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari proyek, kategori, klien...',
                    hintStyle: TextStyle(color: FPal.inkMuted, fontSize: 14),
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  style: const TextStyle(fontSize: 14, color: FPal.ink),
                )),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _gaResult = null); },
                    child: const Padding(padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, color: FPal.inkMuted, size: 18))),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _showFilter = !_showFilter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_showFilter || fc > 0) ? FPal.primary : FPal.bgMuted),
              child: Stack(children: [
                Center(child: Icon(Icons.tune_rounded,
                  color: (_showFilter || fc > 0) ? Colors.white : FPal.inkMuted, size: 20)),
                if (fc > 0) Positioned(right: 4, top: 4,
                  child: Container(width: 16, height: 16,
                    decoration: BoxDecoration(color: const Color(0xFFEF4444),
                      shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    child: Center(child: Text('$fc',
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white))))),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: FPal.primaryLight, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hub_rounded, color: FPal.primary, size: 13),
            SizedBox(width: 5),
            Text('GA · BLX-α · NDCG · Fitness Sharing · 60 Gen',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: FPal.primary)),
          ]),
        ),
      ]),
    );
  }
}

// ─── GA Toggle + Panel ────────────────────────────────────────────────────────

class _GAToggleBar extends StatelessWidget {
  final String label, desc;
  final bool showPanel;
  final VoidCallback onToggle;
  const _GAToggleBar({required this.label, required this.desc,
    required this.showPanel, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2A), Color(0xFF1A6B55)]),
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 12.5)),
          Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        ])),
        Icon(showPanel ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
      ]),
    ),
  );
}

class _GAPanel extends StatelessWidget {
  final bool isRunning;
  final int currentGen, totalGen;
  final List<GenerationStat> stats;
  final GenerationStat? latestStat;
  final GARunResult? result;
  final AnimationController pulseCtrl;
  const _GAPanel({required this.isRunning, required this.currentGen,
    required this.totalGen, required this.stats, required this.latestStat,
    required this.result, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0D2B1F), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (isRunning) AnimatedBuilder(animation: pulseCtrl,
          builder: (_, __) => Container(width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Color.lerp(const Color(0xFF6EE7B7), Colors.white, pulseCtrl.value))))
        else const Icon(Icons.check_circle_rounded, color: Color(0xFF6EE7B7), size: 14),
        const SizedBox(width: 8),
        Text(isRunning ? 'Evolusi Gen $currentGen/$totalGen'
            : 'Selesai ${result?.generationsRun ?? totalGen} Generasi',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        const Spacer(),
        if (latestStat != null)
          Text('NDCG=${latestStat!.best.toStringAsFixed(3)}',
            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11)),
      ]),
      if (isRunning && latestStat != null) ...[
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: totalGen > 0 ? currentGen / totalGen : 0,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF6EE7B7)),
            minHeight: 5)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _StatPill('best',  latestStat!.best,      const Color(0xFF6EE7B7)),
          _StatPill('avg',   latestStat!.avg,        const Color(0xFFFBBF24)),
          _StatPill('worst', latestStat!.worst,      const Color(0xFFF87171)),
          _StatPill('div',   latestStat!.diversity,  const Color(0xFFA78BFA)),
          _StatPill('sh',    latestStat!.sharedBest, const Color(0xFF60A5FA)),
        ]),
      ],
      if (stats.length > 3) ...[
        const SizedBox(height: 10),
        SizedBox(height: 50, child: CustomPaint(
          painter: _DualSparkline(
            best: stats.map((s) => s.best).toList(),
            avg:  stats.map((s) => s.avg).toList()),
          size: const Size(double.infinity, 50))),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegDot(color: Color(0xFF6EE7B7), label: 'Best NDCG'),
          SizedBox(width: 12),
          _LegDot(color: Color(0xFFFBBF24), label: 'Avg NDCG'),
        ]),
      ],
      if (!isRunning && result != null) ...[
        const SizedBox(height: 10),
        const Text('Bobot Optimal GA:',
          style: TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 6),
        _WeightBars(chromosome: result!.bestChromosome),
      ],
    ]),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toStringAsFixed(3),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
  ]);
}

class _LegDot extends StatelessWidget {
  final Color color; final String label;
  const _LegDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);
}

class _WeightBars extends StatelessWidget {
  final GAChromosome chromosome;
  const _WeightBars({required this.chromosome});
  static const _colors = [
    Color(0xFF6EE7B7), Color(0xFFFBBF24), Color(0xFF60A5FA),
    Color(0xFFA78BFA), Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF34D399)];
  @override
  Widget build(BuildContext context) {
    final w = chromosome.weights;
    return Column(children: [
      Row(children: List.generate(GAChromosome.dim, (i) => Expanded(
        flex: (w[i] * 100).round().clamp(1, 100),
        child: Container(height: 8, margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(4))),
      ))),
      const SizedBox(height: 4),
      Row(children: List.generate(GAChromosome.dim, (i) => Expanded(
        flex: (w[i] * 100).round().clamp(1, 100),
        child: Center(child: Text('${GAChromosome.labelsShort[i]}\n${(w[i]*100).round()}%',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: _colors[i % _colors.length],
            fontWeight: FontWeight.w700))),
      ))),
    ]);
  }
}

class _DualSparkline extends CustomPainter {
  final List<double> best, avg;
  const _DualSparkline({required this.best, required this.avg});
  @override
  void paint(Canvas canvas, Size size) {
    if (best.length < 2) return;
    _draw(canvas, size, best, const Color(0xFF6EE7B7), 2.0);
    _draw(canvas, size, avg,  const Color(0xFFFBBF24), 1.5);
  }
  void _draw(Canvas canvas, Size size, List<double> data, Color color, double w) {
    final paint = Paint()..color = color..strokeWidth = w
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    final maxV = data.reduce(math.max).clamp(0.01, 1.0);
    final step = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxV) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.08)..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_DualSparkline old) => old.best.length != best.length;
}

// ─── Sort Bar ─────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final SortMode current;
  final int count, filterCount;
  final ValueChanged<SortMode> onChange;
  const _SortBar({required this.current, required this.count,
    required this.filterCount, required this.onChange});

  static const _modes = [
    (SortMode.gaOptimal,  '🧬 GA'),
    (SortMode.price,      '💰 Budget'),
    (SortMode.recency,    '🕐 Terbaru'),
    (SortMode.competition,'👤 Sepi'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    child: Row(children: [
      Text('$count proyek', style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w800, color: FPal.ink)),
      if (filterCount > 0) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: FPal.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Text('$filterCount filter',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: FPal.primary))),
      ],
      const Spacer(),
      ..._modes.map((m) {
        final active = current == m.$1;
        return GestureDetector(
          onTap: () => onChange(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active ? FPal.primary : FPal.bgMuted,
              borderRadius: BorderRadius.circular(16)),
            child: Text(m.$2, style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700,
              color: active ? Colors.white : FPal.inkSoft)),
          ),
        );
      }),
    ]),
  );
}

// ─── Quick Filter Row ─────────────────────────────────────────────────────────

class _QuickFilterRow extends StatelessWidget {
  final List<(String, String)> filters;
  final ValueChanged<String> onSelect;
  const _QuickFilterRow({required this.filters, required this.onSelect});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      itemCount: filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onSelect(filters[i].$2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE2EE)),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
          child: Center(child: Text(filters[i].$1,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: FPal.inkSoft))),
        ),
      ),
    ),
  );
}

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final List<String> recent, suggestions;
  final ValueChanged<String> onSuggest;
  const _EmptyView({required this.recent, required this.suggestions, required this.onSuggest});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      if (recent.isNotEmpty) ...[
        _Label('Pencarian Terbaru', Icons.history_rounded),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: recent.map((s) =>
          GestureDetector(onTap: () => onSuggest(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE2EE))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history_rounded, size: 13, color: FPal.inkMuted),
                const SizedBox(width: 5),
                Text(s, style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: FPal.inkSoft)),
              ])))).toList()),
        const SizedBox(height: 20),
      ],
      _Label('Proyek Populer', Icons.trending_up_rounded),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: suggestions.map((s) =>
        GestureDetector(onTap: () => onSuggest(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: FPal.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FPal.primary.withOpacity(0.2))),
            child: Text(s, style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: FPal.primary))))).toList()),
      const SizedBox(height: 24),
      // GA algo cards
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEECE8))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.hub_rounded, color: FPal.primary, size: 18),
            SizedBox(width: 8),
            Text('Cara Kerja Ranking Proyek',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink)),
          ]),
          const SizedBox(height: 12),
          ...[
            ('🧬', '7 Dimensi Scoring', 'Keyword · Budget · Kategori · Pengalaman · Recency · Kompetisi · Urgensi'),
            ('📊', 'NDCG Fitness', 'Normalized Discounted Cumulative Gain — standar IR penelitian'),
            ('🎲', 'BLX-α Crossover', 'Eksplorasi ruang bobot di sekitar kedua parent'),
            ('🌡️', 'Adaptive σ Mutation', 'σ: 0.30 → 0.04 selama 60 generasi'),
            ('⚡', 'Early Stopping', 'Otomatis berhenti jika konvergen 8 gen berturut'),
          ].map((e) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$2, style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: FPal.ink)),
                Text(e.$3, style: const TextStyle(
                  fontSize: 11, color: FPal.inkMuted, height: 1.3)),
              ])),
            ]))).toList(),
        ]),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  final String text; final IconData icon;
  const _Label(this.text, this.icon);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: FPal.inkMuted),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800, color: FPal.inkSoft)),
  ]);
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _ResultSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
    itemCount: 5,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 12), height: 160,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16))),
  );
}

// ─── Task Result List ─────────────────────────────────────────────────────────

class _TaskResultList extends StatelessWidget {
  final List<GASearchResult<AvailableTask>> results;
  const _TaskResultList({required this.results});
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
    itemCount: results.length,
    itemBuilder: (ctx, i) => _TaskCard(result: results[i], rank: i + 1),
  );
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  final GASearchResult<AvailableTask> result;
  final int rank;
  const _TaskCard({required this.result, required this.rank});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r     = widget.result;
    final t     = r.item;
    final pct   = r.matchPercent;
    final color = pct >= 80 ? FPal.primary
        : pct >= 60 ? const Color(0xFFD97706) : FPal.inkMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: r.isPareto
            ? Border.all(color: const Color(0xFFFBBF24).withOpacity(0.6), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [BoxShadow(
          color: r.isPareto
              ? const Color(0xFFFBBF24).withOpacity(0.1)
              : const Color(0x08000000),
          blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        // Top
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Rank
            Column(children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(
                  color: widget.rank <= 3
                      ? FPal.primary.withOpacity(0.1) : FPal.bgMuted,
                  shape: BoxShape.circle),
                child: Center(child: Text('#${widget.rank}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: widget.rank <= 3 ? FPal.primary : FPal.inkMuted)))),
              if (r.isPareto) ...[
                const SizedBox(height: 3),
                Container(width: 28, height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7)),
                  child: const Center(child: Text('⭐', style: TextStyle(fontSize: 8)))),
              ],
            ]),
            const SizedBox(width: 10),
            // Icon kategori
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                color: FPal.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.work_outline_rounded,
                color: FPal.primary, size: 24)),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14.5, color: FPal.ink),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(t.clientName, style: const TextStyle(
                fontSize: 12, color: FPal.inkMuted)),
            ])),
            // Match %
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$pct%', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text('match', style: TextStyle(fontSize: 10, color: color)),
            ]),
          ]),
        ),
        // Tags
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _Tag(t.category, FPal.primary, FPal.primaryLight),
            _Tag(t.budgetRangeLabel, const Color(0xFF0369A1), const Color(0xFFE0F2FE)),
            _Tag('⏰ ${t.deadlineLabel}', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
            _Tag('📍 ${t.location}', FPal.inkMuted, FPal.bgMuted),
            _Tag('👤 ${t.applicantsCount} pelamar',
              t.applicantsCount < 5 ? FPal.primary : FPal.inkMuted,
              t.applicantsCount < 5 ? FPal.primaryLight : FPal.bgMuted),
          ]),
        ),
        // Radar + bars
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(children: [
            SizedBox(width: 80, height: 80,
              child: CustomPaint(painter: _RadarPainter(
                scores: r.rawScores.asList, weights: r.bestChromosome.weights))),
            const SizedBox(width: 12),
            Expanded(child: Column(children: List.generate(GAChromosome.dim, (i) {
              final s = r.rawScores[i];
              final w = r.bestChromosome.weights[i];
              final colors2 = [
                const Color(0xFF1A6B55), const Color(0xFFF59E0B), const Color(0xFF0369A1),
                const Color(0xFF7C3AED), const Color(0xFFD97706), const Color(0xFFEC4899), const Color(0xFF34D399),
              ];
              final c = colors2[i % colors2.length];
              return Padding(padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  SizedBox(width: 20, child: Text(GAChromosome.labelsShort[i],
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c))),
                  Expanded(child: Stack(children: [
                    Container(height: 6, decoration: BoxDecoration(
                      color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(widthFactor: s.clamp(0.0, 1.0),
                      child: Container(height: 6, decoration: BoxDecoration(
                        color: c.withOpacity(0.7), borderRadius: BorderRadius.circular(3)))),
                  ])),
                  const SizedBox(width: 4),
                  Text('${(w * 100).round()}%',
                    style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w700)),
                ]));
            }))),
          ]),
        ),
        // Reason
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: FPal.inkMuted),
            const SizedBox(width: 5),
            Expanded(child: Text(r.matchReason,
              style: const TextStyle(
                fontSize: 11.5, color: FPal.inkMuted, fontStyle: FontStyle.italic))),
          ]),
        ),
        // Expanded detail
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FPal.bgMuted, borderRadius: BorderRadius.circular(10)),
            child: Text(r.detailReason,
              style: const TextStyle(fontSize: 11, color: FPal.inkSoft, height: 1.5))),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FPal.bgMuted, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_expanded ? 'Tutup' : 'Detail',
                    style: const TextStyle(fontSize: 11.5,
                      fontWeight: FontWeight.w700, color: FPal.inkSoft)),
                  Icon(_expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                    size: 14, color: FPal.inkMuted),
                ])),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: FPal.primary, borderRadius: BorderRadius.circular(10)),
              child: const Text('Lamar Sekarang',
                style: TextStyle(fontSize: 11.5,
                  fontWeight: FontWeight.w800, color: Colors.white))),
          ]),
        ),
      ]),
    );
  }
}

// ─── Radar Painter ────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<double> scores, weights;
  const _RadarPainter({required this.scores, required this.weights});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = math.min(cx, cy) - 4;
    final n  = scores.length;
    final gridP = Paint()..color = const Color(0xFFE8F4F0)
        ..style = PaintingStyle.stroke..strokeWidth = 0.8;
    for (final f in [0.33, 0.67, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final a = 2 * math.pi * i / n - math.pi / 2;
        final p = Offset(cx + r * f * math.cos(a), cy + r * f * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), gridP);
    }
    final spokeP = Paint()..color = const Color(0xFFD4EDE6)..strokeWidth = 0.6;
    for (int i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n - math.pi / 2;
      canvas.drawLine(Offset(cx, cy), Offset(cx + r * math.cos(a), cy + r * math.sin(a)), spokeP);
    }
    final scorePath = Path();
    for (int i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n - math.pi / 2;
      final rv = r * scores[i];
      final p = Offset(cx + rv * math.cos(a), cy + rv * math.sin(a));
      i == 0 ? scorePath.moveTo(p.dx, p.dy) : scorePath.lineTo(p.dx, p.dy);
    }
    scorePath.close();
    canvas.drawPath(scorePath, Paint()..color = FPal.primary.withOpacity(0.18)..style = PaintingStyle.fill);
    canvas.drawPath(scorePath, Paint()..color = FPal.primary..style = PaintingStyle.stroke..strokeWidth = 1.8);
    for (int i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n - math.pi / 2;
      final rv = r * scores[i];
      canvas.drawCircle(Offset(cx + rv * math.cos(a), cy + rv * math.sin(a)),
        2.5, Paint()..color = FPal.primary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Tag extends StatelessWidget {
  final String text; final Color fg, bg;
  const _Tag(this.text, this.fg, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(
      fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)));
}

// ─── Filter Panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChange;
  final VoidCallback onApply, onReset;
  const _FilterPanel({required this.filter, required this.onChange,
    required this.onApply, required this.onReset});
  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late SearchFilter _local;
  static const _cats = ['Design', 'Web Dev', 'Mobile', 'Copywriting',
    'Marketing', 'Data', 'Finance', 'Video', 'Audio', 'AI/ML'];
  static const _skillTags = ['Flutter', 'React', 'Figma', 'Python', 'Laravel',
    'Node.js', 'SEO', 'Photoshop', 'After Effects', 'WordPress'];

  @override
  void initState() { super.initState(); _local = widget.filter; }
  void _u(SearchFilter f) { setState(() => _local = f); widget.onChange(f); }

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _Sec('Kategori Proyek', Wrap(spacing: 7, runSpacing: 7, children: _cats.map((c) {
          final on = _local.categories.contains(c);
          return _Chip(label: c, active: on,
            onTap: () {
              final s = Set<String>.from(_local.categories);
              on ? s.remove(c) : s.add(c);
              _u(_local.copyWith(categories: s));
            });
        }).toList())),
        _Sec('Skill Dibutuhkan', Wrap(spacing: 7, runSpacing: 7, children: _skillTags.map((s) {
          final on = _local.skills.contains(s);
          return _Chip(label: '#$s', active: on,
            activeColor: const Color(0xFF7C3AED),
            activeBg:    const Color(0xFFEDE9FE),
            onTap: () {
              final sk = Set<String>.from(_local.skills);
              on ? sk.remove(s) : sk.add(s);
              _u(_local.copyWith(skills: sk));
            });
        }).toList())),
        // ✅ FIX: child dipindah ke posisi arg ke-2 (positional), bukan named
        _Sec(
          'Rentang Budget',
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FPal.primary, inactiveTrackColor: const Color(0xFFE0E0E0),
              thumbColor: FPal.primary, trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11)),
            child: RangeSlider(
              values: RangeValues(_local.minPrice, _local.maxPrice),
              min: 0, max: 50000000, divisions: 200,
              onChanged: (v) => _u(_local.copyWith(minPrice: v.start, maxPrice: v.end))),
          ),
          subtitle: 'Rp ${_f(_local.minPrice.toInt())} – '
            '${_local.maxPrice >= 50000000 ? "Tak terbatas" : "Rp ${_f(_local.maxPrice.toInt())}"}',
        ),
        _Sec('Level Proyek', Column(children: [
          _ExpRow('Semua Level', '', _local.experienceLevel == -1, () => _u(_local.copyWith(experienceLevel: -1))),
          const SizedBox(height: 7),
          _ExpRow('Entry Level', 'Cocok untuk pemula', _local.experienceLevel == 0, () => _u(_local.copyWith(experienceLevel: 0))),
          const SizedBox(height: 7),
          _ExpRow('Intermediate', 'Pengalaman 2–5 tahun', _local.experienceLevel == 1, () => _u(_local.copyWith(experienceLevel: 1))),
          const SizedBox(height: 7),
          _ExpRow('Expert', 'Proyek kompleks senior', _local.experienceLevel == 2, () => _u(_local.copyWith(experienceLevel: 2))),
        ])),
        _Sec('Tipe Kerja', Row(children: [
          _Chip(label: 'Semua', active: _local.locationPref == LocationPref.any,
            onTap: () => _u(_local.copyWith(locationPref: LocationPref.any))),
          const SizedBox(width: 7),
          _Chip(label: '🌐 Remote', active: _local.locationPref == LocationPref.remote,
            onTap: () => _u(_local.copyWith(locationPref: LocationPref.remote))),
          const SizedBox(width: 7),
          _Chip(label: '🏢 Onsite', active: _local.locationPref == LocationPref.onsite,
            onTap: () => _u(_local.copyWith(locationPref: LocationPref.onsite))),
          const SizedBox(width: 7),
          _Chip(label: '↔ Hybrid', active: _local.locationPref == LocationPref.hybrid,
            onTap: () => _u(_local.copyWith(locationPref: LocationPref.hybrid))),
        ])),
        // ✅ FIX: child dipindah ke posisi arg ke-2 (positional), bukan named
        _Sec(
          'Jumlah Pelamar (Maks)',
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FPal.primary, thumbColor: FPal.primary, trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10)),
            child: Slider(
              value: _local.maxApplicants.toDouble().clamp(0, 999),
              min: 0, max: 999, divisions: 100,
              onChanged: (v) => _u(_local.copyWith(maxApplicants: v.toInt()))),
          ),
          subtitle: _local.maxApplicants >= 999 ? 'Semua' : '≤ ${_local.maxApplicants}',
        ),
        _Sec('Preferensi Lain', _ToggleRow(
          label: '🔥 Hanya Proyek Urgent',
          desc: 'Deadline kurang dari 7 hari',
          value: _local.urgentOnly,
          onChanged: (v) => _u(_local.copyWith(urgentOnly: v)))),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35))),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${_local.activeFilterCount} filter aktif. '
              'GA akan meningkatkan bobot dimensi yang berkorelasi dengan filter kamu.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4))),
          ])),
      ],
    )),
    Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, -2))]),
      child: Row(children: [
        OutlinedButton(onPressed: widget.onReset,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: FPal.primary),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Reset', style: TextStyle(color: FPal.primary, fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(onPressed: widget.onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: FPal.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.hub_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text('Jalankan GA'
              '${_local.activeFilterCount > 0 ? " (${_local.activeFilterCount})" : ""}',
              style: const TextStyle(
                fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
          ]))),
      ]),
    ),
  ]);

  Widget _Sec(String title, Widget child, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
          fontSize: 14.5, fontWeight: FontWeight.w800, color: FPal.ink)),
        if (subtitle != null) Text(subtitle, style: const TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w700, color: FPal.primary)),
      ]),
      const SizedBox(height: 10),
      child,
    ]));

  Widget _Chip({required String label, required bool active,
    required VoidCallback onTap, Color? activeColor, Color? activeBg}) =>
    GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? (activeBg ?? FPal.primary) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? (activeBg ?? FPal.primary) : const Color(0xFFDDE2EE))),
      child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
        color: active ? (activeBg != null ? (activeColor ?? FPal.primary) : Colors.white) : FPal.inkSoft))));

  Widget _ExpRow(String label, String desc, bool active, VoidCallback onTap) =>
    GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? FPal.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? FPal.primary : const Color(0xFFDDE2EE),
          width: active ? 1.5 : 1)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
            color: active ? FPal.primary : FPal.ink)),
          if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 11,
            color: active ? FPal.primary.withOpacity(0.7) : FPal.inkMuted)),
        ])),
        Container(width: 22, height: 22, decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: active ? FPal.primary : const Color(0xFFCCC8C3),
            width: active ? 6.5 : 2),
          color: Colors.white)),
      ])));

  Widget _ToggleRow({required String label, required String desc,
    required bool value, required ValueChanged<bool> onChanged}) =>
    GestureDetector(onTap: () => onChanged(!value), child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? FPal.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? FPal.primary : const Color(0xFFDDE2EE),
          width: value ? 1.5 : 1)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: value ? FPal.primary : FPal.ink)),
          Text(desc, style: TextStyle(fontSize: 11,
            color: value ? FPal.primary.withOpacity(0.7) : FPal.inkMuted)),
        ])),
        AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: 42, height: 24,
          decoration: BoxDecoration(
            color: value ? FPal.primary : const Color(0xFFDDD9D4),
            borderRadius: BorderRadius.circular(12)),
          child: AnimatedAlign(duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 20, height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle)))),
      ])));

  String _f(int n) {
    if (n == 0) return '0';
    final s = n.toString(); final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.'); buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── Dummy Tasks ──────────────────────────────────────────────────────────────
final _dummyTasks = [
  const AvailableTask(
    id: '1',
    title: 'Design a Logo',
    category: 'Design',
    description: 'Create a professional logo for a startup.',
    initialBudget: 500000,
    deadlineLabel: '2026-06-01',
    assistanceType: AssistanceType.remote,
    clientName: 'John Doe',
    postedLabel: '2026-05-20',
    applicantsCount: 12,
    budgetRangeLabel: 'Rp500,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '2',
    title: 'Develop a Website',
    category: 'Development',
    description: 'Build a responsive website for an e-commerce platform.',
    initialBudget: 2000000,
    deadlineLabel: '2026-06-10',
    assistanceType: AssistanceType.remote,
    clientName: 'Jane Smith',
    postedLabel: '2026-05-18',
    applicantsCount: 8,
    budgetRangeLabel: 'Rp2,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '3',
    title: 'Write Blog Articles',
    category: 'Content',
    description: 'Write blog articles for a website.',
    initialBudget: 300000,
    deadlineLabel: '2026-05-25',
    assistanceType: AssistanceType.remote,
    clientName: 'Bob Johnson',
    postedLabel: '2026-05-20',
    applicantsCount: 15,
    budgetRangeLabel: 'Rp300,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '4',
    title: 'Create a Marketing Plan',
    category: 'Marketing',
    description: 'Create a marketing plan for a product.',
    initialBudget: 1000000,
    deadlineLabel: '2026-06-05',
    assistanceType: AssistanceType.remote,
    clientName: 'Alice Brown',
    postedLabel: '2026-05-20',
    applicantsCount: 5,
    budgetRangeLabel: 'Rp1,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '5',
    title: 'Mobile App Development',
    category: 'Development',
    description: 'Develop a mobile app.',
    initialBudget: 4000000,
    deadlineLabel: '2026-06-20',
    assistanceType: AssistanceType.remote,
    clientName: 'Charlie Wilson',
    postedLabel: '2026-05-20',
    applicantsCount: 10,
    budgetRangeLabel: 'Rp4,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '6',
    title: 'SEO Optimization',
    category: 'Marketing',
    description: 'Optimize SEO.',
    initialBudget: 800000,
    deadlineLabel: '2026-05-30',
    assistanceType: AssistanceType.remote,
    clientName: 'Diana Garcia',
    postedLabel: '2026-05-20',
    applicantsCount: 7,
    budgetRangeLabel: 'Rp800,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '7',
    title: 'Social Media Management',
    category: 'Marketing',
    description: 'Manage social media.',
    initialBudget: 600000,
    deadlineLabel: '2026-06-15',
    assistanceType: AssistanceType.remote,
    clientName: 'Ethan Lee',
    postedLabel: '2026-05-20',
    applicantsCount: 9,
    budgetRangeLabel: 'Rp600,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '8',
    title: 'Create an Animation',
    category: 'Animation',
    description: 'Create an animation.',
    initialBudget: 1500000,
    deadlineLabel: '2026-06-12',
    assistanceType: AssistanceType.remote,
    clientName: 'Fiona Martinez',
    postedLabel: '2026-05-20',
    applicantsCount: 6,
    budgetRangeLabel: 'Rp1,500,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '9',
    title: 'Data Analysis',
    category: 'Data',
    description: 'Analyze data.',
    initialBudget: 2500000,
    deadlineLabel: '2026-06-18',
    assistanceType: AssistanceType.remote,
    clientName: 'George Taylor',
    postedLabel: '2026-05-20',
    applicantsCount: 4,
    budgetRangeLabel: 'Rp2,500,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '10',
    title: 'Translate a Document',
    category: 'Translation',
    description: 'Translate a document.',
    initialBudget: 300000,
    deadlineLabel: '2026-05-28',
    assistanceType: AssistanceType.remote,
    clientName: 'Hannah Clark',
    postedLabel: '2026-05-20',
    applicantsCount: 11,
    budgetRangeLabel: 'Rp300,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '11',
    title: 'Illustrate a Book',
    category: 'Illustration',
    description: 'Illustrate a book.',
    initialBudget: 1200000,
    deadlineLabel: '2026-06-08',
    assistanceType: AssistanceType.remote,
    clientName: 'Ian Smith',
    postedLabel: '2026-05-20',
    applicantsCount: 3,
    budgetRangeLabel: 'Rp1,200,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '12',
    title: 'Develop a Game',
    category: 'Game',
    description: 'Develop a game.',
    initialBudget: 5000000,
    deadlineLabel: '2026-06-25',
    assistanceType: AssistanceType.remote,
    clientName: 'Jack Wilson',
    postedLabel: '2026-05-20',
    applicantsCount: 2,
    budgetRangeLabel: 'Rp5,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '13',
    title: 'Create a Video Ad',
    category: 'Video',
    description: 'Create a video ad.',
    initialBudget: 2000000,
    deadlineLabel: '2026-06-22',
    assistanceType: AssistanceType.remote,
    clientName: 'Katie Johnson',
    postedLabel: '2026-05-20',
    applicantsCount: 8,
    budgetRangeLabel: 'Rp2,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '14',
    title: 'Write a Technical Manual',
    category: 'Documentation',
    description: 'Write a technical manual.',
    initialBudget: 1000000,
    deadlineLabel: '2026-06-03',
    assistanceType: AssistanceType.remote,
    clientName: 'Liam Brown',
    postedLabel: '2026-05-20',
    applicantsCount: 5,
    budgetRangeLabel: 'Rp1,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '15',
    title: 'Design a Brochure',
    category: 'Design',
    description: 'Design a brochure.',
    initialBudget: 700000,
    deadlineLabel: '2026-06-07',
    assistanceType: AssistanceType.remote,
    clientName: 'Mia Garcia',
    postedLabel: '2026-05-20',
    applicantsCount: 6,
    budgetRangeLabel: 'Rp700,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '16',
    title: 'Develop an API',
    category: 'Development',
    description: 'Develop an API.',
    initialBudget: 3000000,
    deadlineLabel: '2026-06-14',
    assistanceType: AssistanceType.remote,
    clientName: 'Nathan Lee',
    postedLabel: '2026-05-20',
    applicantsCount: 4,
    budgetRangeLabel: 'Rp3,000,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '17',
    title: 'Create a Chatbot',
    category: 'Development',
    description: 'Create a chatbot.',
    initialBudget: 2500000,
    deadlineLabel: '2026-06-19',
    assistanceType: AssistanceType.remote,
    clientName: 'Olivia Martinez',
    postedLabel: '2026-05-20',
    applicantsCount: 7,
    budgetRangeLabel: 'Rp2,500,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '18',
    title: 'Edit a Video',
    category: 'Video',
    description: 'Edit a video.',
    initialBudget: 900000,
    deadlineLabel: '2026-06-11',
    assistanceType: AssistanceType.remote,
    clientName: 'Parker Wilson',
    postedLabel: '2026-05-20',
    applicantsCount: 10,
    budgetRangeLabel: 'Rp900,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '19',
    title: 'Conduct Market Research',
    category: 'Research',
    description: 'Conduct market research.',
    initialBudget: 1500000,
    deadlineLabel: '2026-06-16',
    assistanceType: AssistanceType.remote,
    clientName: 'Quinn Clark',
    postedLabel: '2026-05-20',
    applicantsCount: 3,
    budgetRangeLabel: 'Rp1,500,000',
    location: 'Remote',
  ),
  const AvailableTask(
    id: '20',
    title: 'Build a Dashboard',
    category: 'Development',
    description: 'Build a dashboard.',
    initialBudget: 3500000,
    deadlineLabel: '2026-06-24',
    assistanceType: AssistanceType.remote,
    clientName: 'Riley Martinez',
    postedLabel: '2026-05-20',
    applicantsCount: 5,
    budgetRangeLabel: 'Rp3,500,000',
    location: 'Remote',
  ),
];