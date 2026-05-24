// ─────────────────────────────────────────────────────────────────────────────
// Algoritma Pencarian — BM25 (Best Match 25)
//
// Implementasi algoritma ranking BM25 untuk pencarian task dan freelancer
// di platform SkillBantuin. BM25 adalah generalisasi dari TF-IDF yang
// memperhitungkan saturasi frekuensi term dan normalisasi panjang dokumen.
//
// Formula BM25:
//   Score(D, Q) = Σ IDF(qi) × [tf(qi,D) × (k1+1)] / [tf(qi,D) + k1×(1 - b + b×|D|/avgdl)]
//
// Parameters:
//   k1 = 1.5  (mengontrol saturasi frekuensi term; range 1.2–2.0)
//   b  = 0.75 (mengontrol normalisasi panjang dokumen; range 0–1)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import '../models/task_models.dart';

class BM25SearchEngine {
  static const double _k1 = 1.5;
  static const double _b = 0.75;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Mencari dan meranking [AvailableTask] berdasarkan query BM25.
  /// Mengembalikan list terurut dari skor tertinggi ke terendah.
  static List<TaskSearchResult> searchTasks(
    List<AvailableTask> tasks,
    String query, {
    double minScore = 0.01,
  }) {
    if (query.trim().isEmpty) {
      return tasks
          .map((t) => TaskSearchResult(task: t, score: 1.0, highlights: []))
          .toList();
    }

    final terms = _tokenize(query);
    if (terms.isEmpty) {
      return tasks
          .map((t) => TaskSearchResult(task: t, score: 1.0, highlights: []))
          .toList();
    }

    // Bangun corpus dari tasks
    final corpus = tasks
        .map((t) => _buildTaskDocument(t))
        .toList();

    final scores = _bm25Score(corpus, terms);
    final results = <TaskSearchResult>[];

    for (int i = 0; i < tasks.length; i++) {
      if (scores[i] >= minScore) {
        results.add(TaskSearchResult(
          task: tasks[i],
          score: scores[i],
          highlights: _findHighlights(corpus[i], terms),
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Mencari freelancer dari [RecommendedFreelancer] list.
  static List<FreelancerSearchResult> searchFreelancers(
    List<RecommendedFreelancer> freelancers,
    String query,
  ) {
    if (query.trim().isEmpty) {
      return freelancers
          .map((f) => FreelancerSearchResult(freelancer: f, score: 1.0))
          .toList();
    }

    final terms = _tokenize(query);
    if (terms.isEmpty) {
      return freelancers
          .map((f) => FreelancerSearchResult(freelancer: f, score: 1.0))
          .toList();
    }

    final corpus = freelancers
        .map((f) => '${f.name} ${f.skill}'.toLowerCase())
        .toList();

    final scores = _bm25Score(corpus, terms);
    final results = <FreelancerSearchResult>[];

    for (int i = 0; i < freelancers.length; i++) {
      if (scores[i] > 0) {
        results.add(FreelancerSearchResult(
          freelancer: freelancers[i],
          score: scores[i],
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // ─── Core BM25 ─────────────────────────────────────────────────────────────

  static List<double> _bm25Score(List<String> corpus, List<String> queryTerms) {
    final N = corpus.length;
    if (N == 0) return [];

    // Tokenisasi semua dokumen
    final tokenizedDocs = corpus.map(_tokenize).toList();

    // Hitung panjang rata-rata dokumen
    final totalLen = tokenizedDocs.fold<int>(0, (sum, d) => sum + d.length);
    final avgdl = N > 0 ? totalLen / N : 1.0;

    final scores = List<double>.filled(N, 0.0);

    for (final term in queryTerms) {
      // Hitung Document Frequency (DF) — berapa dokumen mengandung term ini
      int df = 0;
      final termFreqs = <int>[];

      for (final tokens in tokenizedDocs) {
        final tf = tokens.where((t) => t == term).length;
        termFreqs.add(tf);
        if (tf > 0) df++;
      }

      // IDF dengan smoothing (Robertson-Spärck Jones variant)
      // IDF = log((N - df + 0.5) / (df + 0.5) + 1)
      final idf = math.log((N - df + 0.5) / (df + 0.5) + 1);

      for (int i = 0; i < N; i++) {
        final tf = termFreqs[i].toDouble();
        if (tf == 0) continue;

        final docLen = tokenizedDocs[i].length.toDouble();
        final normalizedTf =
            (tf * (_k1 + 1)) / (tf + _k1 * (1 - _b + _b * docLen / avgdl));
        scores[i] += idf * normalizedTf;
      }
    }

    // Normalisasi ke [0, 1]
    final maxScore = scores.reduce(math.max);
    if (maxScore > 0) {
      for (int i = 0; i < scores.length; i++) {
        scores[i] /= maxScore;
      }
    }

    return scores;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _buildTaskDocument(AvailableTask t) {
    // Gabungkan semua field yang relevan, dengan bobot berulang pada title & category
    return '${t.title} ${t.title} ${t.category} ${t.category} '
        '${t.description} ${t.location} ${t.clientName}'
        .toLowerCase();
  }

  /// Tokenisasi: lowercase, hapus tanda baca, split whitespace
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }

  /// Temukan kata mana dari query yang muncul dalam dokumen
  static List<String> _findHighlights(String document, List<String> terms) {
    final docTerms = _tokenize(document);
    return terms.where((t) => docTerms.contains(t)).toList();
  }
}

// ─── Result Models ─────────────────────────────────────────────────────────

class TaskSearchResult {
  final AvailableTask task;
  final double score;
  final List<String> highlights;

  const TaskSearchResult({
    required this.task,
    required this.score,
    required this.highlights,
  });
}

class FreelancerSearchResult {
  final RecommendedFreelancer freelancer;
  final double score;

  const FreelancerSearchResult({
    required this.freelancer,
    required this.score,
  });
}
