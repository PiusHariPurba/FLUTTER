// ─────────────────────────────────────────────────────────────────────────────
// Algoritma Genetika — Optimasi Penawaran Budget & Deadline
//
// Menggunakan Genetic Algorithm (GA) untuk menemukan kombinasi optimal
// antara budget yang ditawarkan dan tenggat waktu yang diusulkan,
// sehingga memaksimalkan kemungkinan penawaran diterima client.
//
// Representasi:
//   Chromosome = [budget_factor, deadline_days]
//   budget_factor : faktor pengali dari budget client (0.5–1.2)
//   deadline_days : jumlah hari tenggat waktu (3–90)
//
// Siklus GA:
//   1. Inisialisasi populasi acak
//   2. Evaluasi fitness setiap individu
//   3. Seleksi (Tournament Selection)
//   4. Crossover (Uniform Crossover)
//   5. Mutasi (Gaussian Mutation)
//   6. Elitisme (pertahankan individu terbaik)
//   7. Ulangi hingga konvergensi
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as dartMath;

class GeneticOptimizer {
  // ─── Hyperparameter ────────────────────────────────────────────────────────
  static const int _populationSize = 60;
  static const int _generations = 80;
  static const double _crossoverRate = 0.8;
  static const double _mutationRate = 0.15;
  static const int _tournamentSize = 5;
  static const int _eliteCount = 3;

  // ─── Gen Batas ─────────────────────────────────────────────────────────────
  static const double _minBudgetFactor = 0.50; // 50% dari budget client
  static const double _maxBudgetFactor = 1.20; // 120% dari budget client
  static const int _minDeadlineDays = 3;
  static const int _maxDeadlineDays = 90;

  final dartMath.Random _rng;
  final int _clientBudget;
  final int _clientDeadlineDays;
  final double _freelancerRating;
  final int _completedTasks;

  GeneticOptimizer({
    required int clientBudget,
    required int clientDeadlineDays,
    required double freelancerRating,
    required int completedTasks,
    int? seed,
  })  : _clientBudget = clientBudget,
        _clientDeadlineDays = clientDeadlineDays,
        _freelancerRating = freelancerRating,
        _completedTasks = completedTasks,
        _rng = dartMath.Random(seed);

  // ─── Public: Jalankan Optimasi ─────────────────────────────────────────────

  GAResult optimize() {
    // Inisialisasi populasi
    var population = _initPopulation();
    Individual? globalBest;
    final List<double> fitnessHistory = [];

    for (int gen = 0; gen < _generations; gen++) {
      // Evaluasi fitness
      final evaluated = population
          .map((ind) => _EvaluatedIndividual(ind, _fitness(ind)))
          .toList();
      evaluated.sort((a, b) => b.fitness.compareTo(a.fitness));

      // Catat best fitness generasi ini
      fitnessHistory.add(evaluated.first.fitness);

      // Update global best
      if (globalBest == null || _fitness(evaluated.first.ind) > _fitness(globalBest!)) {
        globalBest = evaluated.first.ind;
      }

      // Elitisme: elite langsung masuk generasi berikutnya
      final nextGen = evaluated
          .take(_eliteCount)
          .map((e) => e.ind)
          .toList();

      // Isi sisa populasi lewat seleksi + crossover + mutasi
      while (nextGen.length < _populationSize) {
        final p1 = _tournamentSelect(evaluated);
        final p2 = _tournamentSelect(evaluated);

        Individual child;
        if (_rng.nextDouble() < _crossoverRate) {
          child = _uniformCrossover(p1, p2);
        } else {
          child = _rng.nextBool() ? p1 : p2;
        }

        child = _mutate(child);
        nextGen.add(child);
      }

      population = nextGen;
    }

    // Evaluasi akhir dan ambil yang terbaik
    final finalEval = population
        .map((ind) => _EvaluatedIndividual(ind, _fitness(ind)))
        .toList();
    finalEval.sort((a, b) => b.fitness.compareTo(a.fitness));

    final best = finalEval.first.ind;
    final bestFitness = finalEval.first.fitness;

    return GAResult(
      recommendedBudget: _decodeBudget(best),
      recommendedDeadlineDays: _decodeDeadline(best),
      fitnessScore: bestFitness,
      chromosome: best,
      fitnessHistory: fitnessHistory,
      explanation: _explain(best, bestFitness),
    );
  }

  // ─── Fitness Function ──────────────────────────────────────────────────────
  //
  // Fitness mengukur seberapa menarik penawaran bagi client, dengan
  // mempertimbangkan:
  //   1. Budget competitiveness (40%) — semakin di bawah budget client, semakin baik
  //   2. Deadline feasibility (30%)   — sesuai dengan deadline client
  //   3. Freelancer credibility (30%) — rating & pengalaman meningkatkan kepercayaan
  double _fitness(Individual ind) {
    final budget = _decodeBudget(ind);
    final deadlineDays = _decodeDeadline(ind);

    // 1. Budget score (0–1): reward budget di bawah client, penalize yang melebihi
    final budgetRatio = budget / _clientBudget;
    double budgetScore;
    if (budgetRatio <= 0.85) {
      budgetScore = 1.0; // penawaran sangat kompetitif
    } else if (budgetRatio <= 1.0) {
      budgetScore = 1.0 - (budgetRatio - 0.85) / 0.15 * 0.3; // linear penalty
    } else {
      budgetScore = (0.7 - (budgetRatio - 1.0) * 2).clamp(0.0, 0.7);
    }

    // 2. Deadline score (0–1): penalti jika melebihi deadline client
    final deadlineRatio = deadlineDays / _clientDeadlineDays;
    double deadlineScore;
    if (deadlineRatio <= 0.9) {
      deadlineScore = 1.0; // bisa selesai lebih cepat
    } else if (deadlineRatio <= 1.0) {
      deadlineScore = 0.9;
    } else if (deadlineRatio <= 1.2) {
      deadlineScore = 0.5 - (deadlineRatio - 1.0) * 1.5;
    } else {
      deadlineScore = 0.0;
    }
    deadlineScore = deadlineScore.clamp(0.0, 1.0);

    // 3. Credibility score (0–1): rating & pengalaman
    final ratingScore = (_freelancerRating / 5.0).clamp(0.0, 1.0);
    final expScore = (_completedTasks / 30.0).clamp(0.0, 1.0);
    final credibilityScore = (ratingScore * 0.6 + expScore * 0.4);

    // Weighted sum
    return budgetScore * 0.40 + deadlineScore * 0.30 + credibilityScore * 0.30;
  }

  // ─── Inisialisasi Populasi ─────────────────────────────────────────────────

  List<Individual> _initPopulation() {
    return List.generate(_populationSize, (_) => _randomIndividual());
  }

  Individual _randomIndividual() {
    return Individual(
      budgetFactor: _minBudgetFactor +
          _rng.nextDouble() * (_maxBudgetFactor - _minBudgetFactor),
      deadlineDays: _minDeadlineDays +
          _rng.nextInt(_maxDeadlineDays - _minDeadlineDays + 1),
    );
  }

  // ─── Seleksi Tournament ────────────────────────────────────────────────────

  Individual _tournamentSelect(List<_EvaluatedIndividual> pool) {
    _EvaluatedIndividual? best;
    for (int i = 0; i < _tournamentSize; i++) {
      final candidate = pool[_rng.nextInt(pool.length)];
      if (best == null || candidate.fitness > best.fitness) {
        best = candidate;
      }
    }
    return best!.ind;
  }

  // ─── Uniform Crossover ────────────────────────────────────────────────────

  Individual _uniformCrossover(Individual p1, Individual p2) {
    return Individual(
      budgetFactor: _rng.nextBool() ? p1.budgetFactor : p2.budgetFactor,
      deadlineDays: _rng.nextBool() ? p1.deadlineDays : p2.deadlineDays,
    );
  }

  // ─── Gaussian Mutation ────────────────────────────────────────────────────

  Individual _mutate(Individual ind) {
    double bf = ind.budgetFactor;
    int dd = ind.deadlineDays;

    if (_rng.nextDouble() < _mutationRate) {
      // Gaussian noise untuk budget factor
      bf += _gaussianNoise(0.0, 0.08);
      bf = bf.clamp(_minBudgetFactor, _maxBudgetFactor);
    }

    if (_rng.nextDouble() < _mutationRate) {
      // Gaussian noise untuk deadline (bilangan bulat)
      dd += (_gaussianNoise(0.0, 5.0)).round();
      dd = dd.clamp(_minDeadlineDays, _maxDeadlineDays);
    }

    return Individual(budgetFactor: bf, deadlineDays: dd);
  }

  // Box-Muller transform untuk Gaussian random
  double _gaussianNoise(double mean, double std) {
    final u1 = _rng.nextDouble();
    final u2 = _rng.nextDouble();
    final z0 = dartMath.sqrt(-2.0 * dartMath.log(u1 + 1e-10)) *
        dartMath.cos(2 * dartMath.pi * u2);
    return mean + std * z0;
  }

  // ─── Decode Chromosome ────────────────────────────────────────────────────

  int _decodeBudget(Individual ind) {
    return (_clientBudget * ind.budgetFactor).round();
  }

  int _decodeDeadline(Individual ind) => ind.deadlineDays;

  // ─── Penjelasan Hasil ─────────────────────────────────────────────────────

  String _explain(Individual best, double fitness) {
    final budget = _decodeBudget(best);
    final deadline = _decodeDeadline(best);
    final pct = ((budget / _clientBudget) * 100).round();

    String budgetNote;
    if (pct <= 85) {
      budgetNote = 'Budget kompetitif ($pct% dari anggaran client)';
    } else if (pct <= 100) {
      budgetNote = 'Budget dalam anggaran client ($pct%)';
    } else {
      budgetNote = 'Budget melebihi anggaran client ($pct%), kurang ideal';
    }

    final fitLabel = fitness >= 0.8
        ? 'Sangat Baik'
        : fitness >= 0.6
            ? 'Baik'
            : fitness >= 0.4
                ? 'Cukup'
                : 'Perlu Penyesuaian';

    return '$budgetNote. Tenggat $deadline hari. Skor keberhasilan: $fitLabel '
        '(${(fitness * 100).round()}%).';
  }
}

// ─── Data Classes ──────────────────────────────────────────────────────────

class Individual {
  final double budgetFactor;
  final int deadlineDays;

  const Individual({required this.budgetFactor, required this.deadlineDays});
}

class _EvaluatedIndividual {
  final Individual ind;
  final double fitness;
  _EvaluatedIndividual(this.ind, this.fitness);
}

class GAResult {
  final int recommendedBudget;
  final int recommendedDeadlineDays;
  final double fitnessScore; // 0.0–1.0
  final Individual chromosome;
  final List<double> fitnessHistory;
  final String explanation;

  const GAResult({
    required this.recommendedBudget,
    required this.recommendedDeadlineDays,
    required this.fitnessScore,
    required this.chromosome,
    required this.fitnessHistory,
    required this.explanation,
  });

  int get fitnessPercent => (fitnessScore * 100).round();

  String get deadlineLabel {
    if (recommendedDeadlineDays <= 7) return '$recommendedDeadlineDays hari';
    if (recommendedDeadlineDays <= 30) {
      final weeks = (recommendedDeadlineDays / 7).round();
      return '$weeks minggu';
    }
    final months = (recommendedDeadlineDays / 30).round();
    return '$months bulan';
  }
}
