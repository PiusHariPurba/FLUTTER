// ─────────────────────────────────────────────────────────────────────────────
//  genetic_search.dart  —  L99 Edition
//  Algoritma Genetika Multi-Dimensi untuk SkillBantuin
//
//  UPGRADE dari versi sebelumnya:
//  · 7 gen (dari 5): tambah responseSpeed / recency / competition / urgency
//  · BLX-α Crossover (Blend Crossover) — menjelajah ruang di sekitar parent
//  · Adaptive σ Mutation — σ turun dari 0.30 → 0.04 seiring generasi
//  · Fitness Sharing — menjaga keragaman populasi, hindari premature convergence
//  · NDCG Fitness — lebih presisi dari Spearman (standard IR metric)
//  · Early Stopping — berhenti jika fitness plateau 8 generasi berturut
//  · Populasi 30, 60 generasi, elitisme top-3
//  · GenerationStat — statistik per generasi (best/avg/worst/diversity)
//  · Pareto front tracking — multi-objective awareness
//
//  Formula BLX-α Crossover:
//    lo = min(p1_i, p2_i) - α·|p1_i - p2_i|
//    hi = max(p1_i, p2_i) + α·|p1_i - p2_i|
//    child_i = Uniform(lo, hi)   α = 0.5
//
//  Formula Adaptive Mutation:
//    σ(t) = σ_max · exp(-λ · t/T)   λ=3.5, σ_max=0.30, σ_min=0.04
//
//  Formula Fitness Sharing:
//    shared(i) = fitness(i) / Σ_j sh(d(i,j))
//    sh(d) = 1 - (d/σ_niche)²  jika d < σ_niche, else 0
//
//  Formula NDCG:
//    DCG  = Σ (2^rel_i - 1) / log2(i+2)
//    NDCG = DCG / iDCG
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import '../models/task_models.dart';
import 'search_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ENUMS & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

enum SortMode { gaOptimal, rating, price, recency, competition }
enum LocationPref { any, remote, onsite, hybrid }
enum ResponseTimePref { any, fast, medium, any2 } // fast=<1h, medium=<1d

// ═══════════════════════════════════════════════════════════════════════════════
//  SEARCH FILTER  —  preferensi lengkap user
// ═══════════════════════════════════════════════════════════════════════════════

class SearchFilter {
  final String       query;
  final Set<String>  categories;
  final double       minPrice;
  final double       maxPrice;
  final double       minRating;
  final int          experienceLevel;   // -1=semua, 0=junior, 1=mid, 2=senior
  final String       responseTimePref;  // 'any','<1j','<1h','<3h'
  final LocationPref locationPref;
  final bool         verifiedOnly;
  final SortMode     sortMode;
  final Set<String>  skills;            // tag skills spesifik
  final int          minApplicants;     // filter task: min applicants (0=semua)
  final int          maxApplicants;     // filter task: max applicants (999=semua)
  final bool         urgentOnly;        // hanya task deadline < 7 hari

  const SearchFilter({
    this.query           = '',
    this.categories      = const {},
    this.minPrice        = 0,
    this.maxPrice        = 50000000,
    this.minRating       = 0,
    this.experienceLevel = -1,
    this.responseTimePref = 'any',
    this.locationPref    = LocationPref.any,
    this.verifiedOnly    = false,
    this.sortMode        = SortMode.gaOptimal,
    this.skills          = const {},
    this.minApplicants   = 0,
    this.maxApplicants   = 999,
    this.urgentOnly      = false,
  });

  bool get hasKeyword     => query.trim().isNotEmpty;
  bool get hasCategory    => categories.isNotEmpty;
  bool get hasPrice       => minPrice > 0 || maxPrice < 50000000;
  bool get hasRating      => minRating > 0;
  bool get hasExperience  => experienceLevel >= 0;
  bool get hasResponse    => responseTimePref != 'any';
  bool get hasLocation    => locationPref != LocationPref.any;
  bool get hasSkills      => skills.isNotEmpty;
  bool get hasApplicants  => maxApplicants < 999;

  int get activeFilterCount =>
    (hasCategory ? 1 : 0) + (hasPrice ? 1 : 0) + (hasRating ? 1 : 0) +
    (hasExperience ? 1 : 0) + (hasResponse ? 1 : 0) + (hasLocation ? 1 : 0) +
    (verifiedOnly ? 1 : 0) + (hasSkills ? 1 : 0) +
    (hasApplicants ? 1 : 0) + (urgentOnly ? 1 : 0);

  SearchFilter copyWith({
    String? query, Set<String>? categories, double? minPrice, double? maxPrice,
    double? minRating, int? experienceLevel, String? responseTimePref,
    LocationPref? locationPref, bool? verifiedOnly, SortMode? sortMode,
    Set<String>? skills, int? minApplicants, int? maxApplicants, bool? urgentOnly,
  }) => SearchFilter(
    query:            query            ?? this.query,
    categories:       categories       ?? this.categories,
    minPrice:         minPrice         ?? this.minPrice,
    maxPrice:         maxPrice         ?? this.maxPrice,
    minRating:        minRating        ?? this.minRating,
    experienceLevel:  experienceLevel  ?? this.experienceLevel,
    responseTimePref: responseTimePref ?? this.responseTimePref,
    locationPref:     locationPref     ?? this.locationPref,
    verifiedOnly:     verifiedOnly     ?? this.verifiedOnly,
    sortMode:         sortMode         ?? this.sortMode,
    skills:           skills           ?? this.skills,
    minApplicants:    minApplicants    ?? this.minApplicants,
    maxApplicants:    maxApplicants    ?? this.maxApplicants,
    urgentOnly:       urgentOnly       ?? this.urgentOnly,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ITEM SCORES  —  7 dimensi skor mentah per kandidat
// ═══════════════════════════════════════════════════════════════════════════════

class ItemScores {
  // Freelancer mode
  final double keyword;      // [0] BM25 text relevance
  final double rating;       // [1] star rating normalised
  final double price;        // [2] price fit to budget
  final double experience;   // [3] experience level match
  final double category;     // [4] category/skill match
  final double responseSpeed;// [5] response time (freelancer) / recency (task)
  final double competition;  // [6] applicant density / availability signal

  const ItemScores({
    required this.keyword,
    required this.rating,
    required this.price,
    required this.experience,
    required this.category,
    required this.responseSpeed,
    required this.competition,
  });

  static const int dim = 7;

  double operator [](int i) => switch (i) {
    0 => keyword,
    1 => rating,
    2 => price,
    3 => experience,
    4 => category,
    5 => responseSpeed,
    6 => competition,
    _ => 0.0,
  };

  /// Skor akhir pakai bobot kromosom (dot product ternormalisasi)
  double weightedScore(List<double> w) {
    assert(w.length == dim);
    double num = 0, den = 0;
    for (int i = 0; i < dim; i++) {
      num += w[i] * this[i];
      den += w[i];
    }
    return den > 0 ? num / den : 0;
  }

  /// Semua dimensi sebagai list (untuk radar chart)
  List<double> get asList => [
    keyword, rating, price, experience, category, responseSpeed, competition];
}

// ═══════════════════════════════════════════════════════════════════════════════
//  KROMOSOM  —  vektor bobot 7 gen
// ═══════════════════════════════════════════════════════════════════════════════

class GAChromosome {
  static const int dim = 7;
  static const List<String> labels = [
    'Keyword', 'Rating', 'Harga', 'Pengalaman', 'Kategori', 'Respons', 'Peluang',
  ];
  static const List<String> labelsShort = [
    'KW', 'RT', 'HG', 'PG', 'KT', 'RS', 'PL',
  ];

  List<double> weights;   // panjang = dim, ternormalisasi (sum=1)
  double fitness = 0.0;
  double sharedFitness = 0.0;

  GAChromosome(List<double> w) : weights = List.from(w) {
    _normalize();
  }

  GAChromosome.random(math.Random rng)
      : weights = List.generate(dim, (_) => rng.nextDouble() * 0.9 + 0.05),
        fitness = 0.0, sharedFitness = 0.0 {
    _normalize();
  }

  void _normalize() {
    final s = weights.fold<double>(0, (a, b) => a + b);
    if (s > 1e-9) {
      weights = weights.map((w) => (w / s).clamp(0.01, 1.0)).toList();
      // Re-normalize after clamp
      final s2 = weights.fold<double>(0, (a, b) => a + b);
      if (s2 > 1e-9) weights = weights.map((w) => w / s2).toList();
    }
  }

  /// BLX-α Crossover — jelajahi ruang sekitar interval parent
  GAChromosome blxCrossover(GAChromosome other, math.Random rng, {double alpha = 0.5}) {
    final child = List<double>.generate(dim, (i) {
      final lo  = math.min(weights[i], other.weights[i]);
      final hi  = math.max(weights[i], other.weights[i]);
      final ext = alpha * (hi - lo);
      return (lo - ext + rng.nextDouble() * (hi - lo + 2 * ext)).clamp(0.01, 1.0);
    });
    return GAChromosome(child);
  }

  /// Uniform Crossover — fallback jika BLX menghasilkan distribusi terlalu lebar
  GAChromosome uniformCrossover(GAChromosome other, math.Random rng) {
    final child = List<double>.generate(dim,
        (i) => rng.nextBool() ? weights[i] : other.weights[i]);
    return GAChromosome(child);
  }

  /// Adaptive Gaussian Mutation — σ dikontrol dari luar
  GAChromosome mutate(math.Random rng, double sigma) {
    final mutated = List<double>.from(weights);
    for (int i = 0; i < dim; i++) {
      if (rng.nextDouble() < 0.35) {
        // Gaussian noise: approximate dengan Box-Muller
        final u1 = rng.nextDouble();
        final u2 = rng.nextDouble();
        final gauss = math.sqrt(-2 * math.log(u1 + 1e-10)) *
            math.cos(2 * math.pi * u2);
        mutated[i] = (mutated[i] + sigma * gauss).clamp(0.01, 1.0);
      }
    }
    return GAChromosome(mutated);
  }

  GAChromosome clone() =>
    GAChromosome(List.from(weights))
      ..fitness       = fitness
      ..sharedFitness = sharedFitness;

  /// Jarak Euclidean antar kromosom (untuk fitness sharing)
  double distanceTo(GAChromosome other) {
    double sum = 0;
    for (int i = 0; i < dim; i++) {
      final d = weights[i] - other.weights[i];
      sum += d * d;
    }
    return math.sqrt(sum);
  }

  /// Dua gen dengan bobot terbesar
  List<String> get dominantFactors {
    final sorted = List.generate(dim, (i) => MapEntry(i, weights[i]))
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => labels[e.key]).toList();
  }

  @override
  String toString() {
    final pct = weights.map((w) => '${(w * 100).round()}%').join('|');
    return 'GAChromosome[$pct] fit=${fitness.toStringAsFixed(4)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STATISTIK GENERASI
// ═══════════════════════════════════════════════════════════════════════════════

class GenerationStat {
  final int    generation;
  final double best;
  final double avg;
  final double worst;
  final double diversity;    // std deviation of fitness
  final double sharedBest;  // setelah fitness sharing

  const GenerationStat({
    required this.generation,
    required this.best,
    required this.avg,
    required this.worst,
    required this.diversity,
    required this.sharedBest,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HASIL GA
// ═══════════════════════════════════════════════════════════════════════════════

class GASearchResult<T> {
  final T            item;
  final double       finalScore;
  final int          matchPercent;
  final ItemScores   rawScores;
  final GAChromosome bestChromosome;
  final String       matchReason;
  final String       detailReason;   // penjelasan panjang
  final bool         isPareto;       // apakah item ini di Pareto front

  const GASearchResult({
    required this.item,
    required this.finalScore,
    required this.matchPercent,
    required this.rawScores,
    required this.bestChromosome,
    required this.matchReason,
    required this.detailReason,
    this.isPareto = false,
  });

  /// Contribution tiap dimensi ke skor akhir [0-1]
  List<double> get contributions {
    final w = bestChromosome.weights;
    final total = w.fold<double>(0, (a, b) => a + b);
    if (total == 0) return List.filled(GAChromosome.dim, 0);
    return List.generate(GAChromosome.dim,
        (i) => (w[i] * rawScores[i]) / total);
  }
}

class GARunResult<T> {
  final List<GASearchResult<T>> results;
  final GAChromosome            bestChromosome;
  final List<GenerationStat>    stats;          // statistik per generasi
  final int                     generationsRun;
  final double                  finalFitness;
  final bool                    earlyStop;
  final int                     earlyStopAt;

  const GARunResult({
    required this.results,
    required this.bestChromosome,
    required this.stats,
    required this.generationsRun,
    required this.finalFitness,
    this.earlyStop   = false,
    this.earlyStopAt = 0,
  });

  String get convergenceLabel {
    if (finalFitness >= 0.88) return 'Konvergen Sempurna';
    if (finalFitness >= 0.72) return 'Konvergen Baik';
    if (finalFitness >= 0.55) return 'Konvergen Parsial';
    return 'Eksplorasi Luas';
  }

  String get convergenceDescription => earlyStop
    ? 'Early stop gen $earlyStopAt — konvergen lebih cepat'
    : '$generationsRun generasi selesai';

  List<String> get weightSummary => List.generate(GAChromosome.dim,
    (i) => '${GAChromosome.labels[i]} ${(bestChromosome.weights[i]*100).round()}%');

  /// fitness history untuk sparkline
  List<double> get bestHistory => stats.map((s) => s.best).toList();
  List<double> get avgHistory  => stats.map((s) => s.avg).toList();
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CORE GA ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

class GeneticSearchEngine {
  // ── Hyperparameter ─────────────────────────────────────────────────────────
  static const int    _popSize      = 30;
  static const int    _maxGen       = 60;
  static const double _sigmaMax     = 0.30;  // mutation awal
  static const double _sigmaMin     = 0.04;  // mutation akhir
  static const double _lambda       = 3.5;   // laju pendinginan
  static const double _crossRate    = 0.75;
  static const double _blxAlpha     = 0.5;
  static const int    _eliteCount   = 3;
  static const int    _tourneyK     = 4;
  static const double _nicheSigma   = 0.25;  // sharing radius
  static const int    _plateauLimit = 8;     // early stop jika plateau N gen

  // ── PUBLIC: Search Freelancer (Client view) ────────────────────────────────

  static Future<GARunResult<RecommendedFreelancer>> searchFreelancers({
    required List<RecommendedFreelancer> freelancers,
    required SearchFilter filter,
    void Function(int gen, int total, GenerationStat stat)? onProgress,
  }) async {
    if (freelancers.isEmpty) return _emptyResult<RecommendedFreelancer>();

    final bm25   = BM25SearchEngine.searchFreelancers(freelancers, filter.query);
    final bm25Map = {for (final r in bm25) r.freelancer.id: r.score};

    final scores = freelancers.map((f) => ItemScores(
      keyword:       (bm25Map[f.id] ?? (filter.hasKeyword ? 0.0 : 0.7)).clamp(0.0, 1.0),
      rating:        (f.rating / 5.0).clamp(0.0, 1.0),
      price:         _priceScore(f.baseRate.toDouble(), filter),
      experience:    _expScoreFreelancer(f, filter),
      category:      _catScoreFreelancer(f, filter),
      responseSpeed: _responseScore(f.responseTime),
      competition:   0.65,   // neutral (no applicant data for freelancers)
    )).toList();

    return _runGA<RecommendedFreelancer>(
      items: freelancers, scores: scores, filter: filter,
      onProgress: onProgress,
      seedWeights: _seedWeights(filter, isTask: false),
    );
  }

  // ── PUBLIC: Search Task (Freelancer view) ──────────────────────────────────

  static Future<GARunResult<AvailableTask>> searchTasks({
    required List<AvailableTask> tasks,
    required SearchFilter filter,
    void Function(int gen, int total, GenerationStat stat)? onProgress,
  }) async {
    if (tasks.isEmpty) return _emptyResult<AvailableTask>();

    final bm25    = BM25SearchEngine.searchTasks(tasks, filter.query);
    final bm25Map = {for (final r in bm25) r.task.id: r.score};

    final maxApplicants = tasks.isEmpty ? 1
        : tasks.map((t) => t.applicantsCount).reduce(math.max).clamp(1, 9999);

    final scores = tasks.map((t) => ItemScores(
      keyword:       (bm25Map[t.id] ?? (filter.hasKeyword ? 0.0 : 0.7)).clamp(0.0, 1.0),
      rating:        0.5,   // tasks tidak punya rating → neutral
      price:         _priceScore(t.initialBudget.toDouble(), filter),
      experience:    _expScoreTask(t, filter),
      category:      _catScoreTask(t, filter),
      responseSpeed: _recencyScore(t.postedLabel),
      competition:   (1 - t.applicantsCount / maxApplicants).clamp(0.05, 1.0),
    )).toList();

    return _runGA<AvailableTask>(
      items: tasks, scores: scores, filter: filter,
      onProgress: onProgress,
      seedWeights: _seedWeights(filter, isTask: true),
    );
  }

  // ── CORE LOOP ──────────────────────────────────────────────────────────────

  static Future<GARunResult<T>> _runGA<T>({
    required List<T>         items,
    required List<ItemScores> scores,
    required SearchFilter    filter,
    required List<List<double>> seedWeights,
    void Function(int, int, GenerationStat)? onProgress,
  }) async {
    final rng        = math.Random();
    final statsList  = <GenerationStat>[];
    var   population = _initPopulation(rng, seedWeights);

    // Precompute ideal relevance untuk NDCG
    final idealRelev = _buildIdealRelevance(scores, filter);

    // Generasi 0
    _evaluateAll(population, scores, idealRelev);
    _applyFitnessSharing(population);
    population.sort((a, b) => b.sharedFitness.compareTo(a.sharedFitness));
    statsList.add(_computeStat(0, population));
    onProgress?.call(0, _maxGen, statsList.last);

    double prevBest  = population.first.fitness;
    int    plateauCt = 0;
    bool   earlyStop = false;
    int    stopAt    = _maxGen;

    // Evolusi
    for (int gen = 1; gen <= _maxGen; gen++) {
      // σ adaptif — cooling schedule
      final sigma = _sigmaMax *
          math.exp(-_lambda * gen / _maxGen) + _sigmaMin;

      // Elitisme: top-3 langsung ke generasi berikutnya
      final newPop = <GAChromosome>[
        population[0].clone(),
        population[1].clone(),
        population[2].clone(),
      ];

      // Isi sisa dengan selection → crossover → mutasi
      while (newPop.length < _popSize) {
        final p1 = _tournamentSelect(population, rng);
        GAChromosome child;

        if (rng.nextDouble() < _crossRate) {
          final p2 = _tournamentSelect(population, rng);
          // BLX-α jika jarak > threshold, uniform jika dekat
          child = p1.distanceTo(p2) > 0.1
              ? p1.blxCrossover(p2, rng, alpha: _blxAlpha)
              : p1.uniformCrossover(p2, rng);
        } else {
          child = p1.clone();
        }

        child = child.mutate(rng, sigma);
        newPop.add(child);
      }

      population = newPop;
      _evaluateAll(population, scores, idealRelev);
      _applyFitnessSharing(population);
      population.sort((a, b) => b.sharedFitness.compareTo(a.sharedFitness));

      final stat = _computeStat(gen, population);
      statsList.add(stat);

      // Progress update tiap 5 generasi
      if (gen % 5 == 0 || gen == _maxGen) {
        onProgress?.call(gen, _maxGen, stat);
        await Future.delayed(Duration.zero);
      }

      // Early stopping — plateau detection
      final curBest = population.first.fitness;
      if ((curBest - prevBest).abs() < 1e-5) {
        plateauCt++;
        if (plateauCt >= _plateauLimit) {
          earlyStop = true; stopAt = gen;
          onProgress?.call(gen, _maxGen, stat);
          break;
        }
      } else {
        plateauCt = 0;
        prevBest  = curBest;
      }
    }

    final best    = population.first;
    final results = _buildResults<T>(items, scores, best);

    return GARunResult(
      results:        results,
      bestChromosome: best,
      stats:          statsList,
      generationsRun: earlyStop ? stopAt : _maxGen,
      finalFitness:   best.fitness,
      earlyStop:      earlyStop,
      earlyStopAt:    stopAt,
    );
  }

  // ── Inisialisasi Populasi (seeded + random) ────────────────────────────────

  static List<GAChromosome> _initPopulation(
      math.Random rng, List<List<double>> seeds) {
    final pop = <GAChromosome>[];
    for (final s in seeds) pop.add(GAChromosome(s));
    while (pop.length < _popSize) pop.add(GAChromosome.random(rng));
    return pop;
  }

  /// Buat seed weights berdasarkan filter yang aktif
  static List<List<double>> _seedWeights(SearchFilter f, {required bool isTask}) {
    // dim: [keyword, rating, price, experience, category, responseSpeed, competition]
    final seeds = <List<double>>[];
    // Seed seimbang
    seeds.add([1,1,1,1,1,1,1]);
    // Seed keyword-dominan
    if (f.hasKeyword)   seeds.add([4.0, 0.8, 0.8, 0.8, 1.2, 0.6, 0.8]);
    // Seed rating-dominan
    if (f.hasRating)    seeds.add([0.8, 4.5, 0.8, 0.8, 0.8, 0.7, 0.6]);
    // Seed price-dominan
    if (f.hasPrice)     seeds.add([0.8, 0.8, 4.0, 0.8, 0.8, 0.6, 0.8]);
    // Seed experience-dominan
    if (f.hasExperience) seeds.add([0.8, 0.8, 0.8, 4.0, 0.8, 0.6, 0.8]);
    // Seed category-dominan
    if (f.hasCategory)  seeds.add([0.8, 0.8, 0.8, 0.8, 4.5, 0.6, 0.8]);
    // Seed respons-dominan
    if (f.hasResponse)  seeds.add([0.8, 0.8, 0.8, 0.8, 0.8, 4.0, 0.8]);
    // Seed competition-dominan (untuk task: cari yang sedikit pelamar)
    if (isTask) seeds.add([0.8, 0.5, 1.0, 0.8, 1.0, 1.0, 3.5]);
    // Multi-filter kombinasi
    if (f.hasKeyword && f.hasRating) seeds.add([3.0, 3.0, 0.8, 0.8, 0.8, 0.6, 0.8]);
    if (f.hasPrice && f.hasCategory) seeds.add([0.8, 0.8, 3.0, 0.8, 3.0, 0.6, 0.8]);
    return seeds;
  }

  // ── NDCG Fitness ───────────────────────────────────────────────────────────

  static List<double> _buildIdealRelevance(
      List<ItemScores> scores, SearchFilter f) {
    // Bobot ideal berdasarkan filter aktif — ini adalah "oracle" GA
    final double wKw = f.hasKeyword    ? 2.5 : 0.5;
    final double wRt = f.hasRating     ? 2.5 : 0.5;
    final double wPr = f.hasPrice      ? 2.5 : 0.5;
    final double wEx = f.hasExperience ? 2.0 : 0.5;
    final double wCt = f.hasCategory   ? 2.5 : 0.5;
    final double wRs = f.hasResponse   ? 2.0 : 0.5;
    final double wCo = 0.8;
    final total = wKw+wRt+wPr+wEx+wCt+wRs+wCo;
    return scores.map((s) =>
      (s.keyword*wKw + s.rating*wRt + s.price*wPr + s.experience*wEx +
       s.category*wCt + s.responseSpeed*wRs + s.competition*wCo) / total
    ).toList();
  }

  static void _evaluateAll(
      List<GAChromosome> pop, List<ItemScores> scores, List<double> idealRel) {
    for (final c in pop) {
      c.fitness = _ndcg(c, scores, idealRel);
    }
  }

  static double _ndcg(GAChromosome c, List<ItemScores> scores, List<double> ideal) {
    if (scores.isEmpty) return 0.0;
    final n = scores.length;

    // Ranking dari kromosom ini
    final ranked = List.generate(n, (i) => i)
      ..sort((a, b) => scores[b].weightedScore(c.weights)
          .compareTo(scores[a].weightedScore(c.weights)));

    // DCG dari ranking kromosom
    double dcg = 0;
    for (int pos = 0; pos < n; pos++) {
      final rel = ideal[ranked[pos]];
      dcg += (math.pow(2, rel) - 1) / math.log(pos + 2) * math.ln2;
    }

    // iDCG — ranking ideal
    final sortedIdeal = List.from(ideal)..sort((a, b) => b.compareTo(a));
    double idcg = 0;
    for (int pos = 0; pos < n; pos++) {
      idcg += (math.pow(2, sortedIdeal[pos]) - 1) / math.log(pos + 2) * math.ln2;
    }

    return idcg > 0 ? (dcg / idcg).clamp(0.0, 1.0) : 0.0;
  }

  // ── Fitness Sharing ────────────────────────────────────────────────────────

  static void _applyFitnessSharing(List<GAChromosome> pop) {
    for (int i = 0; i < pop.length; i++) {
      double niching = 0;
      for (int j = 0; j < pop.length; j++) {
        final d = pop[i].distanceTo(pop[j]);
        if (d < _nicheSigma) {
          niching += 1 - math.pow(d / _nicheSigma, 2);
        }
      }
      pop[i].sharedFitness = niching > 0
          ? pop[i].fitness / niching
          : pop[i].fitness;
    }
  }

  // ── Tournament Selection ───────────────────────────────────────────────────

  static GAChromosome _tournamentSelect(
      List<GAChromosome> pop, math.Random rng) {
    GAChromosome? best;
    for (int i = 0; i < _tourneyK; i++) {
      final c = pop[rng.nextInt(pop.length)];
      if (best == null || c.sharedFitness > best.sharedFitness) best = c;
    }
    return best!;
  }

  // ── Statistik Generasi ─────────────────────────────────────────────────────

  static GenerationStat _computeStat(int gen, List<GAChromosome> pop) {
    final fits = pop.map((c) => c.fitness).toList();
    final best  = fits.reduce(math.max);
    final worst = fits.reduce(math.min);
    final avg   = fits.fold<double>(0, (a, b) => a + b) / fits.length;
    final variance = fits
        .map((f) => (f - avg) * (f - avg))
        .fold<double>(0, (a, b) => a + b) / fits.length;
    final diversity = math.sqrt(variance);
    final sharedBest = pop.map((c) => c.sharedFitness).reduce(math.max);
    return GenerationStat(
      generation: gen, best: best, avg: avg,
      worst: worst, diversity: diversity, sharedBest: sharedBest);
  }

  // ── Build Final Results ────────────────────────────────────────────────────

  static List<GASearchResult<T>> _buildResults<T>(
      List<T> items, List<ItemScores> scores, GAChromosome best) {
    // Deteksi Pareto front (rating vs price tradeoff)
    final paretoSet = _paretoFront(scores);

    final results = <GASearchResult<T>>[];
    for (int i = 0; i < items.length; i++) {
      final s       = scores[i];
      final score   = s.weightedScore(best.weights);
      final pct     = (score * 100).round().clamp(1, 100);
      final (brief, detail) = _buildReason(s, best);

      results.add(GASearchResult<T>(
        item:           items[i],
        finalScore:     score,
        matchPercent:   pct,
        rawScores:      s,
        bestChromosome: best,
        matchReason:    brief,
        detailReason:   detail,
        isPareto:       paretoSet.contains(i),
      ));
    }

    results.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return results;
  }

  /// Pareto front: item tidak didominasi oleh item lain
  /// (rating vs price) — dua objective
  static Set<int> _paretoFront(List<ItemScores> scores) {
    final pareto = <int>{};
    for (int i = 0; i < scores.length; i++) {
      bool dominated = false;
      for (int j = 0; j < scores.length; j++) {
        if (i == j) continue;
        // j mendominasi i jika j lebih baik di semua dimensi
        if (scores[j].rating  >= scores[i].rating  &&
            scores[j].price   >= scores[i].price   &&
            scores[j].keyword >= scores[i].keyword &&
            (scores[j].rating  > scores[i].rating  ||
             scores[j].price   > scores[i].price   ||
             scores[j].keyword > scores[i].keyword)) {
          dominated = true; break;
        }
      }
      if (!dominated) pareto.add(i);
    }
    return pareto;
  }

  // ── Reason Builder ─────────────────────────────────────────────────────────

  static (String brief, String detail) _buildReason(
      ItemScores s, GAChromosome c) {
    final contribs = List.generate(GAChromosome.dim, (i) => (
      label: GAChromosome.labels[i],
      value: c.weights[i] * s[i],
      score: s[i],
      weight: c.weights[i],
    ))..sort((a, b) => b.value.compareTo(a.value));

    final top2 = contribs.where((e) => e.value > 0.04).take(2).toList();
    final brief = top2.isEmpty
        ? 'Relevan secara umum'
        : 'Unggul: ${top2.map((e) => e.label).join(' & ')}';

    // Teks detail
    final sb = StringBuffer();
    for (final e in contribs.take(4)) {
      final pct = (e.score * 100).round();
      final w   = (e.weight * 100).round();
      sb.write('${e.label} $pct% (bobot $w%) · ');
    }
    final detail = sb.toString().trimRight().replaceAll(RegExp(r' · $'), '');

    return (brief, detail);
  }

  // ── Score Helpers ──────────────────────────────────────────────────────────

  static double _priceScore(double price, SearchFilter f) {
    if (price <= 0) return 0.5;
    if (!f.hasPrice) return 0.65;
    if (price >= f.minPrice && price <= f.maxPrice) {
      final mid  = (f.minPrice + f.maxPrice) / 2;
      final span = (f.maxPrice - f.minPrice) / 2;
      if (span < 1) return 1.0;
      return (1 - (price - mid).abs() / span).clamp(0.0, 1.0) * 0.45 + 0.55;
    }
    final over  = price < f.minPrice ? f.minPrice - price : price - f.maxPrice;
    final range = (f.maxPrice - f.minPrice).abs().clamp(1.0, double.infinity);
    return (1 - over / range).clamp(0.0, 0.35);
  }

  static double _expScoreFreelancer(RecommendedFreelancer f, SearchFilter sf) {
    if (!sf.hasExperience) return 0.6;
    final level = f.baseRate < 150000 ? 0 : f.baseRate < 400000 ? 1 : 2;
    final diff  = (level - sf.experienceLevel).abs();
    return diff == 0 ? 1.0 : diff == 1 ? 0.5 : 0.15;
  }

  static double _catScoreFreelancer(RecommendedFreelancer f, SearchFilter sf) {
    if (!sf.hasCategory && !sf.hasSkills) return 0.6;
    final skill = f.skill.toLowerCase();
    for (final c in [...sf.categories, ...sf.skills]) {
      final lc = c.toLowerCase();
      if (skill.contains(lc) || lc.split(' ').any((w) => skill.contains(w))) {
        return 1.0;
      }
    }
    return 0.1;
  }

  static double _expScoreTask(AvailableTask t, SearchFilter sf) {
    if (!sf.hasExperience) return 0.6;
    final b = t.initialBudget;
    final level = b < 500000 ? 0 : b < 3000000 ? 1 : 2;
    final diff  = (level - sf.experienceLevel).abs();
    return diff == 0 ? 1.0 : diff == 1 ? 0.5 : 0.15;
  }

  static double _catScoreTask(AvailableTask t, SearchFilter sf) {
    if (!sf.hasCategory && !sf.hasSkills) return 0.6;
    final cat = t.category.toLowerCase();
    final desc = t.description.toLowerCase();
    for (final c in [...sf.categories, ...sf.skills]) {
      final lc = c.toLowerCase();
      if (cat.contains(lc) || lc.split(' ').any((w) => cat.contains(w) || desc.contains(w))) {
        return 1.0;
      }
    }
    return 0.1;
  }

  static double _responseScore(String responseTime) {
    final rt = responseTime.toLowerCase();
    if (rt.contains('15') || rt.contains('mnt') && rt.contains('30')) return 0.95;
    if (rt.contains('jam') && rt.contains('1')) return 0.80;
    if (rt.contains('jam') && (rt.contains('2') || rt.contains('3'))) return 0.65;
    if (rt.contains('hari') && rt.contains('1')) return 0.45;
    if (rt.contains('hari')) return 0.25;
    return 0.55;
  }

  static double _recencyScore(String postedLabel) {
    final lbl = postedLabel.toLowerCase();
    if (lbl.contains('menit') || (lbl.contains('jam') &&
        RegExp(r'(\d+)\s*jam').firstMatch(lbl)?.group(1) != null &&
        int.tryParse(RegExp(r'(\d+)\s*jam').firstMatch(lbl)!.group(1)!)! <= 3)) {
      return 1.0;
    }
    if (lbl.contains('jam')) return 0.85;
    final dayMatch = RegExp(r'(\d+)\s*hari').firstMatch(lbl);
    if (dayMatch != null) {
      final days = int.tryParse(dayMatch.group(1)!) ?? 7;
      return (1 - days / 30.0).clamp(0.1, 0.75);
    }
    return 0.5;
  }

  static GARunResult<T> _emptyResult<T>() => GARunResult<T>(
    results: [],
    bestChromosome: GAChromosome(List.filled(GAChromosome.dim, 1.0 / GAChromosome.dim)),
    stats: [], generationsRun: 0, finalFitness: 0,
  );
}
