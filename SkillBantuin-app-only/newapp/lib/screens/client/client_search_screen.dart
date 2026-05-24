// ─────────────────────────────────────────────────────────────────────────────
//  client_search_screen.dart  —  L99 Edition
//  Search Freelancer · Algoritma Genetika · 10 filter · Radar Chart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../ai/genetic_search.dart';
import '../../models/task_models.dart';
import '../../providers/providers.dart';
import '../../widgets/app_theme.dart';

class ClientSearchScreen extends StatefulWidget {
  const ClientSearchScreen({super.key});
  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen>
    with SingleTickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  late final AnimationController _pulseCtrl;

  // ── Filter state ─────────────────────────────────────────────────────────
  SearchFilter _filter = const SearchFilter();

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _showFilter      = false;
  bool _showGAPanel     = false;
  bool _isRunning       = false;
  SortMode _sortMode    = SortMode.gaOptimal;

  // ── GA state ─────────────────────────────────────────────────────────────
  int              _currentGen    = 0;
  int              _totalGen      = 60;
  GenerationStat?  _latestStat;
  List<GenerationStat> _allStats  = [];
  GARunResult<RecommendedFreelancer>? _gaResult;

  // ── History & suggestions ─────────────────────────────────────────────────
  final List<String> _recentSearches = [];
  final List<String> _compareList    = [];
  bool _compareMode = false;

  static const _suggestions = [
    'UI/UX Designer', 'Flutter Developer', 'Copywriter', 'React.js',
    'Logo Design', 'SEO Writer', 'Motion Graphics', 'Node.js',
    'WordPress', 'Video Editing', 'Social Media', 'Illustrator',
  ];

  static const _quickFilters = [
    ('⭐ Rating 4.5+', 'rating'),
    ('🚀 Respons Cepat', 'fast'),
    ('💼 Senior', 'senior'),
    ('💰 Budget Pas', 'budget'),
    ('📍 Remote', 'remote'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _searchCtrl.addListener(_onQueryChange);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Debounced search ─────────────────────────────────────────────────────
  DateTime? _lastTyped;
  void _onQueryChange() {
    final now = _lastTyped = DateTime.now();
    if (_searchCtrl.text.trim().isEmpty) return;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (_lastTyped == now && mounted) _runGA();
    });
  }

  // ── Quick filter helper ───────────────────────────────────────────────────
  void _applyQuick(String key) {
    setState(() {
      _filter = switch (key) {
        'rating'  => _filter.copyWith(minRating: 4.5),
        'fast'    => _filter.copyWith(responseTimePref: '<1j'),
        'senior'  => _filter.copyWith(experienceLevel: 2),
        'budget'  => _filter.copyWith(maxPrice: 500000),
        'remote'  => _filter.copyWith(locationPref: LocationPref.remote),
        _         => _filter,
      };
    });
    _runGA();
  }

  // ── GA run ────────────────────────────────────────────────────────────────
  Future<void> _runGA() async {
    final raw  = context.read<FreelancerProvider>().freelancers;
    final data = raw.isNotEmpty
        ? raw.map((m) => RecommendedFreelancer.fromApiJson(m)).toList()
        : _dummyFreelancers;

    final currentFilter = _filter.copyWith(query: _searchCtrl.text.trim());

    setState(() {
      _isRunning = true; _currentGen = 0;
      _allStats  = []; _latestStat = null; _gaResult = null;
    });
    HapticFeedback.selectionClick();

    final result = await GeneticSearchEngine.searchFreelancers(
      freelancers: data,
      filter:      currentFilter,
      onProgress:  (gen, total, stat) {
        if (!mounted) return;
        setState(() {
          _currentGen = gen; _totalGen = total;
          _latestStat = stat; _allStats.add(stat);
        });
      },
    );

    if (!mounted) return;
    // Simpan recent search
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty && !_recentSearches.contains(q)) {
      _recentSearches.insert(0, q);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    }

    setState(() { _isRunning = false; _gaResult = result; });
    HapticFeedback.mediumImpact();
  }

  // ── Sorted results ────────────────────────────────────────────────────────
  List<GASearchResult<RecommendedFreelancer>> get _sortedResults {
    final r = List<GASearchResult<RecommendedFreelancer>>.from(
        _gaResult?.results ?? []);
    switch (_sortMode) {
      case SortMode.gaOptimal:  break; // sudah terurut
      case SortMode.rating:
        r.sort((a, b) => b.item.rating.compareTo(a.item.rating)); break;
      case SortMode.price:
        r.sort((a, b) => a.item.baseRate.compareTo(b.item.baseRate)); break;
      case SortMode.recency:
        r.sort((a, b) => b.rawScores.responseSpeed
            .compareTo(a.rawScores.responseSpeed)); break;
      case SortMode.competition:
        r.sort((a, b) => b.matchPercent.compareTo(a.matchPercent)); break;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              ctrl:         _searchCtrl,
              filter:       _filter,
              showFilter:   _showFilter,
              compareMode:  _compareMode,
              compareCount: _compareList.length,
              onFilterTap:  () => setState(() => _showFilter = !_showFilter),
              onCompareTap: () => setState(() => _compareMode = !_compareMode),
              onClear:      () { _searchCtrl.clear(); setState(() => _gaResult = null); },
            ),

            // Quick filter pills
            if (!_showFilter && !_isRunning && _gaResult == null)
              _QuickFilterRow(
                filters:  _quickFilters,
                onSelect: _applyQuick,
              ),

            // GA Panel toggle
            if (_gaResult != null && !_isRunning)
              _GAToggleBar(
                result:     _gaResult!,
                showPanel:  _showGAPanel,
                onToggle:   () => setState(() => _showGAPanel = !_showGAPanel),
              ),

            // GA Visualisasi live
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: _showGAPanel || _isRunning
                  ? _GAVisualizationPanel(
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

            // Sort tabs (hanya jika ada hasil)
            if (_gaResult != null && !_isRunning && !_showFilter)
              _SortTabBar(
                current:    _sortMode,
                resultCount: _gaResult!.results.length,
                filterCount: _filter.activeFilterCount,
                onChange:   (m) => setState(() => _sortMode = m),
              ),

            // Content
            Expanded(
              child: _showFilter
                  ? _FilterPanel(
                      filter:   _filter,
                      onChange: (f) => setState(() => _filter = f),
                      onApply:  () {
                        setState(() => _showFilter = false);
                        _runGA();
                      },
                      onReset:  () => setState(() {
                        _filter = const SearchFilter();
                        _showFilter = false;
                        _gaResult = null;
                      }),
                    )
                  : _gaResult == null && !_isRunning
                      ? _EmptySearchView(
                          recent:      _recentSearches,
                          suggestions: _suggestions,
                          onSuggest:   (s) {
                            _searchCtrl.text = s;
                            _runGA();
                          },
                        )
                      : _isRunning
                          ? const _RunningPlaceholder()
                          : _ResultList(
                              results:     _sortedResults,
                              compareMode: _compareMode,
                              compareList: _compareList,
                              onCompare:   (id) => setState(() {
                                if (_compareList.contains(id))
                                  _compareList.remove(id);
                                else if (_compareList.length < 3)
                                  _compareList.add(id);
                              }),
                              onContact:   (_) {},
                            ),
            ),

            // Floating compare button
            if (_compareMode && _compareList.length >= 2)
              _CompareBar(
                count:   _compareList.length,
                onClear: () => setState(() => _compareList.clear()),
                onCompare: () => _showCompareSheet(),
              ),
          ],
        ),
      ),
    );
  }

  void _showCompareSheet() {
    final items = _gaResult!.results
        .where((r) => _compareList.contains(r.item.id))
        .toList();
    showModalBottomSheet(
      context:        context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompareSheet(items: items),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SEARCH HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchHeader extends StatelessWidget {
  final TextEditingController ctrl;
  final SearchFilter filter;
  final bool showFilter, compareMode;
  final int compareCount;
  final VoidCallback onFilterTap, onCompareTap, onClear;
  const _SearchHeader({
    required this.ctrl, required this.filter, required this.showFilter,
    required this.compareMode, required this.compareCount,
    required this.onFilterTap, required this.onCompareTap, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fc = filter.activeFilterCount;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
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
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Freelancer, keahlian, tools...',
                    hintStyle: TextStyle(color: FPal.inkMuted, fontSize: 14),
                    border: InputBorder.none, isDense: true,
                    contentPadding: EdgeInsets.zero),
                  style: const TextStyle(fontSize: 14, color: FPal.ink),
                )),
                if (ctrl.text.isNotEmpty)
                  GestureDetector(onTap: onClear,
                    child: const Padding(padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, color: FPal.inkMuted, size: 18))),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          // Filter btn
          _HeaderBtn(
            icon: Icons.tune_rounded,
            active: showFilter || fc > 0,
            badge: fc > 0 ? '$fc' : null,
            onTap: onFilterTap,
          ),
          const SizedBox(width: 4),
          // Compare btn
          _HeaderBtn(
            icon: Icons.compare_arrows_rounded,
            active: compareMode,
            badge: compareCount > 0 ? '$compareCount' : null,
            onTap: onCompareTap,
          ),
        ]),
        // GA badge
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: FPal.primaryLight, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hub_rounded, color: FPal.primary, size: 13),
            SizedBox(width: 5),
            Text('GA · BLX-α · NDCG · 60 generasi · fitness sharing',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                color: FPal.primary)),
          ]),
        ),
      ]),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String? badge;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.active,
    this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? FPal.primary : FPal.bgMuted),
      child: Stack(children: [
        Center(child: Icon(icon,
          color: active ? Colors.white : FPal.inkMuted, size: 20)),
        if (badge != null) Positioned(right: 4, top: 4,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444), shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5)),
            child: Center(child: Text(badge!,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
                color: Colors.white))))),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  QUICK FILTER ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickFilterRow extends StatelessWidget {
  final List<(String, String)> filters;
  final ValueChanged<String> onSelect;
  const _QuickFilterRow({required this.filters, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDE2EE)),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 4)]),
            child: Center(child: Text(filters[i].$1,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: FPal.inkSoft))),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GA TOGGLE BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _GAToggleBar extends StatelessWidget {
  final GARunResult<RecommendedFreelancer> result;
  final bool showPanel;
  final VoidCallback onToggle;
  const _GAToggleBar({required this.result, required this.showPanel, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3D2A), Color(0xFF1A6B55)]),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.results.length} freelancer · ${r.convergenceLabel}',
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 12.5)),
            Text(r.convergenceDescription,
              style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
          ])),
          Icon(showPanel ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
            color: Colors.white70, size: 20),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GA VISUALIZATION PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _GAVisualizationPanel extends StatelessWidget {
  final bool isRunning;
  final int currentGen, totalGen;
  final List<GenerationStat> stats;
  final GenerationStat? latestStat;
  final GARunResult? result;
  final AnimationController pulseCtrl;

  const _GAVisualizationPanel({
    required this.isRunning, required this.currentGen, required this.totalGen,
    required this.stats, required this.latestStat, required this.result,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2B1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          if (isRunning) AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(const Color(0xFF6EE7B7),
                    Colors.white, pulseCtrl.value)),
            ),
          ) else const Icon(Icons.check_circle_rounded,
            color: Color(0xFF6EE7B7), size: 14),
          const SizedBox(width: 8),
          Text(
            isRunning
              ? 'Evolusi Gen $currentGen/$totalGen'
              : 'Selesai — ${result?.generationsRun ?? totalGen} Generasi',
            style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 12.5)),
          const Spacer(),
          if (latestStat != null)
            Text('fit=${latestStat!.best.toStringAsFixed(3)}',
              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11)),
        ]),

        if (isRunning && latestStat != null) ...[
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalGen > 0 ? currentGen / totalGen : 0,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6EE7B7)),
              minHeight: 5)),
          const SizedBox(height: 8),
          // Stats
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _StatPill('best', latestStat!.best, const Color(0xFF6EE7B7)),
            _StatPill('avg',  latestStat!.avg,  const Color(0xFFFBBF24)),
            _StatPill('worst', latestStat!.worst, const Color(0xFFF87171)),
            _StatPill('σ',    latestStat!.diversity, const Color(0xFFA78BFA)),
          ]),
        ],

        if (stats.length > 3) ...[
          const SizedBox(height: 10),
          // Dual sparkline: best + avg
          SizedBox(
            height: 50,
            child: CustomPaint(
              painter: _DualSparklinePainter(
                best: stats.map((s) => s.best).toList(),
                avg:  stats.map((s) => s.avg).toList(),
              ),
              size: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 4),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot(color: Color(0xFF6EE7B7), label: 'Best'),
            SizedBox(width: 12),
            _LegendDot(color: Color(0xFFFBBF24), label: 'Avg'),
          ]),
        ],

        // Bobot optimal (setelah selesai)
        if (!isRunning && result != null) ...[
          const SizedBox(height: 10),
          const Text('Bobot Optimal GA:',
            style: TextStyle(color: Colors.white60, fontSize: 10.5)),
          const SizedBox(height: 6),
          _WeightBar(chromosome: result!.bestChromosome),
        ],
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toStringAsFixed(3),
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
  ]);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);
}

class _WeightBar extends StatelessWidget {
  final GAChromosome chromosome;
  const _WeightBar({required this.chromosome});

  static const _colors = [
    Color(0xFF6EE7B7), Color(0xFFFBBF24), Color(0xFF60A5FA),
    Color(0xFFA78BFA), Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF34D399),
  ];

  @override
  Widget build(BuildContext context) {
    final w = chromosome.weights;
    return Column(children: [
      Row(children: List.generate(GAChromosome.dim, (i) => Expanded(
        flex: (w[i] * 100).round().clamp(1, 100),
        child: Container(
          height: 8, margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _colors[i % _colors.length],
            borderRadius: BorderRadius.circular(4)),
        ),
      ))),
      const SizedBox(height: 4),
      Row(children: List.generate(GAChromosome.dim, (i) => Expanded(
        flex: (w[i] * 100).round().clamp(1, 100),
        child: Center(child: Text(
          '${GAChromosome.labelsShort[i]}\n${(w[i]*100).round()}%',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8, color: _colors[i % _colors.length],
            fontWeight: FontWeight.w700))),
      ))),
    ]);
  }
}

// ── Dual Sparkline Painter ────────────────────────────────────────────────────
class _DualSparklinePainter extends CustomPainter {
  final List<double> best, avg;
  const _DualSparklinePainter({required this.best, required this.avg});

  @override
  void paint(Canvas canvas, Size size) {
    if (best.length < 2) return;
    _drawLine(canvas, size, best, const Color(0xFF6EE7B7), 2.0);
    _drawLine(canvas, size, avg,  const Color(0xFFFBBF24), 1.5);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color, double width) {
    final paint = Paint()
      ..color = color ..strokeWidth = width
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    final path = Path();
    final maxV = data.reduce(math.max).clamp(0.01, 1.0);
    final step = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxV) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    // Fill
    final fill = Path.from(path)
      ..lineTo(size.width, size.height) ..lineTo(0, size.height) ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.08)..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DualSparklinePainter old) => old.best.length != best.length;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SORT TAB BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _SortTabBar extends StatelessWidget {
  final SortMode current;
  final int resultCount, filterCount;
  final ValueChanged<SortMode> onChange;
  const _SortTabBar({required this.current, required this.resultCount,
    required this.filterCount, required this.onChange});

  static const _modes = [
    (SortMode.gaOptimal, '🧬 GA', 'GA Optimal'),
    (SortMode.rating,    '⭐ Rating', 'Rating'),
    (SortMode.price,     '💰 Harga', 'Harga'),
    (SortMode.recency,   '🕐 Aktif', 'Terbaru'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(children: [
        Text('$resultCount freelancer',
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: FPal.ink)),
        if (filterCount > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: FPal.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Text('$filterCount filter',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                color: FPal.primary))),
        ],
        const Spacer(),
        Row(children: _modes.map((m) {
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
              child: Text(m.$2,
                style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : FPal.inkSoft)),
            ),
          );
        }).toList()),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EMPTY SEARCH VIEW  —  Recent + Suggestions
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptySearchView extends StatelessWidget {
  final List<String> recent, suggestions;
  final ValueChanged<String> onSuggest;
  const _EmptySearchView({required this.recent, required this.suggestions,
    required this.onSuggest});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (recent.isNotEmpty) ...[
          _SectionLabel('Pencarian Terbaru', Icons.history_rounded),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: recent.map((s) =>
            GestureDetector(
              onTap: () => onSuggest(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDE2EE))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.history_rounded, size: 13, color: FPal.inkMuted),
                  const SizedBox(width: 5),
                  Text(s, style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: FPal.inkSoft)),
                ]),
              ),
            )).toList()),
          const SizedBox(height: 20),
        ],

        _SectionLabel('Pencarian Populer', Icons.trending_up_rounded),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: suggestions.map((s) =>
          GestureDetector(
            onTap: () => onSuggest(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: FPal.primaryLight, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FPal.primary.withOpacity(0.2))),
              child: Text(s, style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: FPal.primary)),
            ),
          )).toList()),

        const SizedBox(height: 24),
        // GA explanation card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEECE8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.hub_rounded, color: FPal.primary, size: 18),
              SizedBox(width: 8),
              Text('Cara Kerja GA Search',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink)),
            ]),
            const SizedBox(height: 12),
            ...[
              ('🧬', 'BLX-α Crossover', 'Anak mewarisi gen dari dua parent + eksplorasi ruang baru'),
              ('🌡️', 'Adaptive Mutation', 'σ turun dari 0.30→0.04 seiring konvergensi'),
              ('🎯', 'NDCG Fitness', 'Mengukur kualitas ranking, bukan hanya urutan'),
              ('🌈', 'Fitness Sharing', 'Menjaga keragaman populasi, hindari lokal optima'),
              ('⚡', 'Early Stopping', 'Berhenti otomatis jika sudah konvergen'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$1, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$2, style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: FPal.ink)),
                  Text(e.$3, style: const TextStyle(
                    fontSize: 11, color: FPal.inkMuted, height: 1.3)),
                ])),
              ]),
            )).toList(),
          ]),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: FPal.inkMuted),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800, color: FPal.inkSoft)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RUNNING PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════════

class _RunningPlaceholder extends StatelessWidget {
  const _RunningPlaceholder();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RESULT LIST
// ═══════════════════════════════════════════════════════════════════════════════

class _ResultList extends StatelessWidget {
  final List<GASearchResult<RecommendedFreelancer>> results;
  final bool compareMode;
  final List<String> compareList;
  final ValueChanged<String> onCompare;
  final ValueChanged<String> onContact;
  const _ResultList({
    required this.results, required this.compareMode, required this.compareList,
    required this.onCompare, required this.onContact,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
    itemCount: results.length,
    itemBuilder: (ctx, i) {
      final r = results[i];
      return _FreelancerCard(
        result:      r,
        rank:        i + 1,
        compareMode: compareMode,
        selected:    compareList.contains(r.item.id),
        onCompare:   () => onCompare(r.item.id),
        onContact:   () => onContact(r.item.id),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FREELANCER CARD  —  Radar chart + breakdown
// ═══════════════════════════════════════════════════════════════════════════════

class _FreelancerCard extends StatefulWidget {
  final GASearchResult<RecommendedFreelancer> result;
  final int rank;
  final bool compareMode, selected;
  final VoidCallback onCompare, onContact;
  const _FreelancerCard({
    required this.result, required this.rank,
    required this.compareMode, required this.selected,
    required this.onCompare, required this.onContact,
  });
  @override
  State<_FreelancerCard> createState() => _FreelancerCardState();
}

class _FreelancerCardState extends State<_FreelancerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r    = widget.result;
    final f    = r.item;
    final pct  = r.matchPercent;
    final color = pct >= 80 ? FPal.primary
        : pct >= 60 ? const Color(0xFFD97706) : FPal.inkMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.selected
            ? Border.all(color: FPal.primary, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [BoxShadow(
          color: r.isPareto
              ? FPal.primary.withOpacity(0.12)
              : const Color(0x08000000),
          blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        // ── Top Row ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Rank + Pareto badge
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: widget.rank <= 3
                      ? FPal.primary.withOpacity(0.12) : FPal.bgMuted,
                  shape: BoxShape.circle),
                child: Center(child: Text('#${widget.rank}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: widget.rank <= 3 ? FPal.primary : FPal.inkMuted)))),
              if (r.isPareto) ...[
                const SizedBox(height: 3),
                Container(
                  width: 28, height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(7)),
                  child: const Center(child: Text('⭐',
                    style: TextStyle(fontSize: 8)))),
              ],
            ]),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: FPal.primaryLight,
                border: Border.all(color: FPal.primary.withOpacity(0.25))),
              child: Center(child: Text(
                f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                style: const TextStyle(color: FPal.primary,
                  fontWeight: FontWeight.w900, fontSize: 20)))),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: FPal.ink)),
              Text(f.skill, style: const TextStyle(
                fontSize: 12.5, color: FPal.inkSoft)),
              const SizedBox(height: 4),
              Row(children: [
                _MiniTag('⭐ ${f.rating}', const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                _MiniTag('Rp ${(f.baseRate/1000).round()}k/j', FPal.primary),
                const SizedBox(width: 6),
                _MiniTag('⚡ ${f.responseTime}', FPal.inkMuted),
              ]),
            ])),
            // Match %
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$pct%', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text('cocok', style: TextStyle(fontSize: 10, color: color)),
            ]),
          ]),
        ),

        // ── Radar Chart + Breakdown ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            // Radar chart
            SizedBox(
              width: 80, height: 80,
              child: CustomPaint(
                painter: _RadarChartPainter(
                  scores: r.rawScores.asList,
                  weights: r.bestChromosome.weights),
              ),
            ),
            const SizedBox(width: 12),
            // Dimension bars
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(GAChromosome.dim, (i) {
                final score = r.rawScores[i];
                final weight = r.bestChromosome.weights[i];
                return _DimBar(
                  label:  GAChromosome.labelsShort[i],
                  score:  score,
                  weight: weight,
                );
              }),
            )),
          ]),
        ),

        // ── Match reason ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: FPal.inkMuted),
            const SizedBox(width: 5),
            Expanded(child: Text(r.matchReason,
              style: const TextStyle(fontSize: 11.5, color: FPal.inkMuted,
                fontStyle: FontStyle.italic))),
          ]),
        ),

        // ── Expanded detail ────────────────────────────────────
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FPal.bgMuted, borderRadius: BorderRadius.circular(10)),
            child: Text(r.detailReason,
              style: const TextStyle(fontSize: 11, color: FPal.inkSoft, height: 1.5)),
          ),
        ),

        // ── Action Row ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            // Expand
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
                ]),
              ),
            ),
            const Spacer(),
            if (widget.compareMode)
              GestureDetector(
                onTap: widget.onCompare,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.selected ? FPal.primary : FPal.bgMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.selected
                        ? FPal.primary : const Color(0xFFDDE2EE))),
                  child: Text(widget.selected ? '✓ Dipilih' : '+ Bandingkan',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                      color: widget.selected ? Colors.white : FPal.inkSoft)),
                ),
              ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onContact,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: FPal.primary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Hubungi',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Radar Chart ───────────────────────────────────────────────────────────────

class _RadarChartPainter extends CustomPainter {
  final List<double> scores;
  final List<double> weights;
  const _RadarChartPainter({required this.scores, required this.weights});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 4;
    final n  = scores.length;

    // Draw grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE8F4F0) ..style = PaintingStyle.stroke ..strokeWidth = 0.8;
    for (double frac in [0.33, 0.67, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = 2 * math.pi * i / n - math.pi / 2;
        final x = cx + r * frac * math.cos(angle);
        final y = cy + r * frac * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFFD4EDE6) ..strokeWidth = 0.6;
    for (int i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2;
      canvas.drawLine(Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)), spokePaint);
    }

    // Score polygon
    final scorePath = Path();
    for (int i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2;
      final rv = r * scores[i];
      final x = cx + rv * math.cos(angle);
      final y = cy + rv * math.sin(angle);
      i == 0 ? scorePath.moveTo(x, y) : scorePath.lineTo(x, y);
    }
    scorePath.close();
    canvas.drawPath(scorePath, Paint()
      ..color = FPal.primary.withOpacity(0.18) ..style = PaintingStyle.fill);
    canvas.drawPath(scorePath, Paint()
      ..color = FPal.primary ..style = PaintingStyle.stroke ..strokeWidth = 1.8);

    // Dots
    for (int i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2;
      final rv = r * scores[i];
      canvas.drawCircle(
        Offset(cx + rv * math.cos(angle), cy + rv * math.sin(angle)),
        2.5, Paint()..color = FPal.primary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Dimension Bar ─────────────────────────────────────────────────────────────

class _DimBar extends StatelessWidget {
  final String label;
  final double score, weight;
  const _DimBar({required this.label, required this.score, required this.weight});

  static const _colors = [
    Color(0xFF1A6B55), Color(0xFFF59E0B), Color(0xFF0369A1),
    Color(0xFF7C3AED), Color(0xFFD97706), Color(0xFFEC4899), Color(0xFF34D399),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[GAChromosome.labelsShort.indexOf(label) % _colors.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(width: 20, child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))),
        Expanded(child: Stack(children: [
          Container(height: 6, decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(
            widthFactor: score.clamp(0.0, 1.0),
            child: Container(height: 6, decoration: BoxDecoration(
              color: color.withOpacity(0.7), borderRadius: BorderRadius.circular(3)))),
        ])),
        const SizedBox(width: 4),
        Text('${(weight * 100).round()}%',
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(
      fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FILTER PANEL  —  10 filter types
// ═══════════════════════════════════════════════════════════════════════════════

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
  static const _cats = ['UI/UX', 'Web Dev', 'Mobile', 'Copywriting',
    'Grafis', 'Marketing', 'Finance', 'Data', 'Video', 'Audio'];
  static const _skillTags = ['Flutter', 'React', 'Figma', 'Photoshop',
    'SEO', 'Python', 'Node.js', 'Laravel', 'WordPress', 'After Effects'];

  @override
  void initState() {
    super.initState();
    _local = widget.filter;
  }

  void _update(SearchFilter f) {
    setState(() => _local = f);
    widget.onChange(f);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          children: [

            // ── Kategori ──────────────────────────────────────────
            _FSection(title: 'Kategori', child: Wrap(
              spacing: 7, runSpacing: 7,
              children: _cats.map((c) {
                final on = _local.categories.contains(c);
                return _FilterChip(label: c, active: on,
                  onTap: () {
                    final s = Set<String>.from(_local.categories);
                    on ? s.remove(c) : s.add(c);
                    _update(_local.copyWith(categories: s));
                  });
              }).toList(),
            )),

            // ── Skill Tags ─────────────────────────────────────────
            _FSection(title: 'Skill Spesifik', child: Wrap(
              spacing: 7, runSpacing: 7,
              children: _skillTags.map((s) {
                final on = _local.skills.contains(s);
                return _FilterChip(label: '#$s', active: on,
                  activeColor: const Color(0xFF7C3AED),
                  activeBg: const Color(0xFFEDE9FE),
                  onTap: () {
                    final sk = Set<String>.from(_local.skills);
                    on ? sk.remove(s) : sk.add(s);
                    _update(_local.copyWith(skills: sk));
                  });
              }).toList(),
            )),

            // ── Rentang Harga ──────────────────────────────────────
            _FSection(
              title: 'Rentang Tarif / Jam',
              subtitle: 'Rp ${_fmt(_local.minPrice.toInt())} – '
                '${_local.maxPrice >= 50000000 ? "Tak terbatas" : "Rp ${_fmt(_local.maxPrice.toInt())}"}',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: FPal.primary,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                  thumbColor: FPal.primary, trackHeight: 5,
                  overlayColor: FPal.primary.withOpacity(0.12),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11)),
                child: RangeSlider(
                  values: RangeValues(_local.minPrice, _local.maxPrice),
                  min: 0, max: 50000000, divisions: 200,
                  onChanged: (v) => _update(
                    _local.copyWith(minPrice: v.start, maxPrice: v.end))),
              ),
            ),

            // ── Rating ─────────────────────────────────────────────
            _FSection(title: 'Rating Minimum', child: Row(children: [
              _FilterChip(label: 'Semua', active: _local.minRating == 0,
                onTap: () => _update(_local.copyWith(minRating: 0))),
              const SizedBox(width: 7),
              _FilterChip(label: '⭐ 4.0+', active: _local.minRating == 4.0,
                onTap: () => _update(_local.copyWith(minRating: 4.0))),
              const SizedBox(width: 7),
              _FilterChip(label: '⭐ 4.5+', active: _local.minRating == 4.5,
                onTap: () => _update(_local.copyWith(minRating: 4.5))),
              const SizedBox(width: 7),
              _FilterChip(label: '⭐ 4.8+', active: _local.minRating == 4.8,
                onTap: () => _update(_local.copyWith(minRating: 4.8))),
            ])),

            // ── Pengalaman ─────────────────────────────────────────
            _FSection(title: 'Tingkat Pengalaman', child: Column(children: [
              _ExpRow('Semua Level', '',
                _local.experienceLevel == -1, () => _update(_local.copyWith(experienceLevel: -1))),
              const SizedBox(height: 7),
              _ExpRow('Junior', '0–2 tahun · Tarif hemat',
                _local.experienceLevel == 0, () => _update(_local.copyWith(experienceLevel: 0))),
              const SizedBox(height: 7),
              _ExpRow('Intermediate', '2–5 tahun · Keseimbangan kualitas & harga',
                _local.experienceLevel == 1, () => _update(_local.copyWith(experienceLevel: 1))),
              const SizedBox(height: 7),
              _ExpRow('Senior', '5+ tahun · Proyek kompleks',
                _local.experienceLevel == 2, () => _update(_local.copyWith(experienceLevel: 2))),
            ])),

            // ── Kecepatan Respons ──────────────────────────────────
            _FSection(title: 'Waktu Respons', child: Row(children: [
              _FilterChip(label: 'Semua', active: _local.responseTimePref == 'any',
                onTap: () => _update(_local.copyWith(responseTimePref: 'any'))),
              const SizedBox(width: 7),
              _FilterChip(label: '⚡ < 1 Jam', active: _local.responseTimePref == '<1j',
                activeColor: const Color(0xFFD97706),
                activeBg: const Color(0xFFFEF3C7),
                onTap: () => _update(_local.copyWith(responseTimePref: '<1j'))),
              const SizedBox(width: 7),
              _FilterChip(label: '🕐 < 1 Hari', active: _local.responseTimePref == '<1h',
                onTap: () => _update(_local.copyWith(responseTimePref: '<1h'))),
            ])),

            // ── Lokasi ─────────────────────────────────────────────
            _FSection(title: 'Tipe Kerja', child: Row(children: [
              _FilterChip(label: 'Semua', active: _local.locationPref == LocationPref.any,
                onTap: () => _update(_local.copyWith(locationPref: LocationPref.any))),
              const SizedBox(width: 7),
              _FilterChip(label: '🌐 Remote', active: _local.locationPref == LocationPref.remote,
                onTap: () => _update(_local.copyWith(locationPref: LocationPref.remote))),
              const SizedBox(width: 7),
              _FilterChip(label: '🏢 Onsite', active: _local.locationPref == LocationPref.onsite,
                onTap: () => _update(_local.copyWith(locationPref: LocationPref.onsite))),
              const SizedBox(width: 7),
              _FilterChip(label: '↔ Hybrid', active: _local.locationPref == LocationPref.hybrid,
                onTap: () => _update(_local.copyWith(locationPref: LocationPref.hybrid))),
            ])),

            // ── Hanya Terverifikasi ────────────────────────────────
            _FSection(title: 'Preferensi Lain', child: _ToggleRow(
              label: '✅ Hanya freelancer terverifikasi',
              desc: 'Sudah diverifikasi identitas dan portofolio',
              value: _local.verifiedOnly,
              onChanged: (v) => _update(_local.copyWith(verifiedOnly: v)),
            )),

            // Info GA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35))),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFFD97706), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Setiap filter aktif mempengaruhi bobot GA. '
                  'Semakin spesifik filter, semakin presisi evolusi.\n'
                  '${_local.activeFilterCount} filter aktif → '
                  '${_local.activeFilterCount} dimensi bobot diprioritaskan.',
                  style: const TextStyle(
                    fontSize: 11, color: Color(0xFF92400E), height: 1.4))),
              ]),
            ),
          ],
        ),
      ),

      // ── Sticky bottom ─────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(
            color: Color(0x10000000), blurRadius: 8, offset: Offset(0, -2))]),
        child: Row(children: [
          OutlinedButton(
            onPressed: widget.onReset,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: FPal.primary),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            child: const Text('Reset', style: TextStyle(
              color: FPal.primary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: widget.onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: FPal.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              elevation: 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.hub_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text('Jalankan GA'
                '${_local.activeFilterCount > 0 ? " (${_local.activeFilterCount} filter)" : ""}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
            ]),
          )),
        ]),
      ),
    ]);
  }

  String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Filter sub-widgets ────────────────────────────────────────────────────────

class _FSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _FSection({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
          fontSize: 14.5, fontWeight: FontWeight.w800, color: FPal.ink)),
        if (subtitle != null)
          Text(subtitle!, style: const TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: FPal.primary)),
      ]),
      const SizedBox(height: 10),
      child,
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? activeColor, activeBg;
  const _FilterChip({required this.label, required this.active,
    required this.onTap, this.activeColor, this.activeBg});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? (activeBg ?? FPal.primary) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? (activeBg ?? FPal.primary) : const Color(0xFFDDE2EE))),
      child: Text(label, style: TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w700,
        color: active
            ? (activeBg != null ? (activeColor ?? FPal.primary) : Colors.white)
            : FPal.inkSoft)),
    ),
  );
}

class _ExpRow extends StatelessWidget {
  final String label, desc;
  final bool active;
  final VoidCallback onTap;
  const _ExpRow(this.label, this.desc, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? FPal.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? FPal.primary : const Color(0xFFDDE2EE),
          width: active ? 1.5 : 1)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w700,
            color: active ? FPal.primary : FPal.ink)),
          if (desc.isNotEmpty)
            Text(desc, style: TextStyle(
              fontSize: 11, color: active ? FPal.primary.withOpacity(0.7) : FPal.inkMuted)),
        ])),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? FPal.primary : const Color(0xFFCCC8C3),
              width: active ? 6.5 : 2),
            color: Colors.white)),
      ]),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label, desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.desc,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? FPal.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? FPal.primary : const Color(0xFFDDE2EE),
          width: value ? 1.5 : 1)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: value ? FPal.primary : FPal.ink)),
          Text(desc, style: TextStyle(
            fontSize: 11, color: value ? FPal.primary.withOpacity(0.7) : FPal.inkMuted)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42, height: 24,
          decoration: BoxDecoration(
            color: value ? FPal.primary : const Color(0xFFDDD9D4),
            borderRadius: BorderRadius.circular(12)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20, height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle))),
        ),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPARE SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _CompareBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear, onCompare;
  const _CompareBar({required this.count, required this.onClear, required this.onCompare});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
    child: Row(children: [
      Text('$count dipilih untuk dibandingkan',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FPal.ink)),
      const Spacer(),
      TextButton(onPressed: onClear,
        child: const Text('Batal', style: TextStyle(color: FPal.inkMuted))),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: onCompare,
        style: ElevatedButton.styleFrom(
          backgroundColor: FPal.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Bandingkan',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
    ]),
  );
}

class _CompareSheet extends StatelessWidget {
  final List<GASearchResult<RecommendedFreelancer>> items;
  const _CompareSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(
          width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFDDD9D4), borderRadius: BorderRadius.circular(2))),
        const Text('Perbandingan Freelancer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: FPal.ink)),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((r) {
                final f = r.item;
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FPal.bg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE2EE))),
                  child: Column(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: FPal.primaryLight),
                      child: Center(child: Text(
                        f.name[0].toUpperCase(),
                        style: const TextStyle(color: FPal.primary,
                          fontWeight: FontWeight.w900, fontSize: 22)))),
                    const SizedBox(height: 8),
                    Text(f.name, style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13), textAlign: TextAlign.center),
                    Text(f.skill, style: const TextStyle(
                      fontSize: 11, color: FPal.inkMuted), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ..._row('Rating', '⭐ ${f.rating}'),
                    ..._row('Tarif', 'Rp ${(f.baseRate/1000).round()}k/j'),
                    ..._row('Respons', f.responseTime),
                    ..._row('Match', '${r.matchPercent}%'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 80, height: 80,
                      child: CustomPaint(
                        painter: _RadarChartPainter(
                          scores: r.rawScores.asList,
                          weights: r.bestChromosome.weights))),
                  ]),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _row(String label, String val) => [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: FPal.inkMuted)),
      Text(val, style: const TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w700, color: FPal.ink)),
    ]),
    const SizedBox(height: 4),
  ];
}

// ── Dummy data ─────────────────────────────────────────────────────────────────
final _dummyFreelancers = [
  const RecommendedFreelancer(id:'1', name:'Andi Wijaya',    skill:'UI/UX Designer',    rating:4.8, responseTime:'< 30 mnt', baseRate:250000),
  const RecommendedFreelancer(id:'2', name:'Siti Rahma',     skill:'Web Developer',      rating:4.6, responseTime:'< 1 jam',  baseRate:180000),
  const RecommendedFreelancer(id:'3', name:'Budi Santoso',   skill:'Copywriter',         rating:4.9, responseTime:'< 15 mnt', baseRate:120000),
  const RecommendedFreelancer(id:'4', name:'Maya Putri',     skill:'Graphic Designer',   rating:4.5, responseTime:'< 45 mnt', baseRate:200000),
  const RecommendedFreelancer(id:'5', name:'Rizky Fauzan',   skill:'Mobile Developer',   rating:4.7, responseTime:'< 1 jam',  baseRate:350000),
  const RecommendedFreelancer(id:'6', name:'Dewi Lestari',   skill:'Marketing Specialist',rating:4.3,responseTime:'< 2 jam',  baseRate:150000),
  const RecommendedFreelancer(id:'7', name:'Hendra Kurnia',  skill:'React Developer',    rating:4.8, responseTime:'< 1 jam',  baseRate:300000),
  const RecommendedFreelancer(id:'8', name:'Lisa Amelia',    skill:'Motion Designer',    rating:4.6, responseTime:'< 3 jam',  baseRate:220000),
  const RecommendedFreelancer(id:'9', name:'Fajar Nugroho',  skill:'Data Scientist',     rating:4.9, responseTime:'< 2 jam',  baseRate:400000),
  const RecommendedFreelancer(id:'10',name:'Nina Kartika',   skill:'SEO Specialist',     rating:4.4, responseTime:'< 1 jam',  baseRate:170000),
  const RecommendedFreelancer(id:'11',name:'Arif Setiawan',  skill:'Backend Developer',  rating:4.7, responseTime:'< 2 jam',  baseRate:320000),
  const RecommendedFreelancer(id:'12',name:'Citra Dewi',     skill:'Content Creator',    rating:4.5, responseTime:'< 3 jam',  baseRate:140000),
  const RecommendedFreelancer(id:'13',name:'Dimas Pratama',  skill:'DevOps Engineer',    rating:4.8, responseTime:'< 1 jam',  baseRate:360000),
  const RecommendedFreelancer(id:'14',name:'Eka Wulandari',  skill:'Illustrator',        rating:4.6, responseTime:'< 2 jam',  baseRate:210000),
  const RecommendedFreelancer(id:'15',name:'Fikri Hidayat',  skill:'Game Developer',     rating:4.9, responseTime:'< 1 jam',  baseRate:450000),
  const RecommendedFreelancer(id:'16',name:'Gita Anggraini', skill:'Translator',         rating:4.3, responseTime:'< 3 jam',  baseRate:130000),
  const RecommendedFreelancer(id:'17',name:'Hana Salsabila', skill:'Animator',           rating:4.7, responseTime:'< 2 jam',  baseRate:280000),
  const RecommendedFreelancer(id:'18',name:'Ivan Gunawan',   skill:'Full Stack Dev',     rating:4.8, responseTime:'< 1 jam',  baseRate:380000),
  const RecommendedFreelancer(id:'19',name:'Joko Widodo',    skill:'AI Engineer',        rating:4.9, responseTime:'< 1 jam',  baseRate:500000),
  const RecommendedFreelancer(id:'20',name:'Kiki Amalia',    skill:'Social Media Manager',rating:4.4,responseTime:'< 2 jam',  baseRate:160000),
];
