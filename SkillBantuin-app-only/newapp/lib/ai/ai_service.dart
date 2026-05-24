// ─────────────────────────────────────────────────────────────────────────────
// AI Module — Barrel Export & AIService Facade
//
// Semua modul AI di-export dari sini. Gunakan [AIService] sebagai
// single entry point untuk seluruh fitur AI di SkillBantuin.
// ─────────────────────────────────────────────────────────────────────────────

export 'search_engine.dart';
export 'expert_system.dart';
export 'sentiment_analyzer.dart';
export 'fuzzy_matcher.dart';
export 'genetic_optimizer.dart';
export 'concept_learner.dart';

import '../models/task_models.dart';
import 'search_engine.dart';
import 'expert_system.dart';
import 'sentiment_analyzer.dart';
import 'fuzzy_matcher.dart';
import 'genetic_optimizer.dart';
import 'concept_learner.dart';

/// Facade tunggal untuk mengakses semua fitur AI SkillBantuin.
///
/// Setiap method di sini adalah shorthand yang menghubungkan data domain
/// dengan algoritma yang sesuai.
class AIService {
  AIService._();
  static final AIService instance = AIService._();

  // Singleton concept learner (state-ful)
  final ConceptLearningEngine _conceptEngine = ConceptLearningEngine();

  // ─── 1. Algoritma Pencarian (BM25) ────────────────────────────────────────

  /// Cari dan ranking [AvailableTask] berdasarkan query BM25.
  List<TaskSearchResult> searchTasks(
    List<AvailableTask> tasks,
    String query, {
    double minScore = 0.01,
  }) {
    return BM25SearchEngine.searchTasks(tasks, query, minScore: minScore);
  }

  /// Cari freelancer dari daftar RecommendedFreelancer.
  List<FreelancerSearchResult> searchFreelancers(
    List<RecommendedFreelancer> freelancers,
    String query,
  ) {
    return BM25SearchEngine.searchFreelancers(freelancers, query);
  }

  // ─── 2. Sistem Pakar (Rekomendasi Freelancer) ─────────────────────────────

  /// Ranking penawaran (VolunteerOffer) berdasarkan sistem pakar.
  List<ExpertRecommendation> rankOffers(
    List<VolunteerOffer> offers,
    ClientTask task,
  ) {
    return ExpertSystem.recommend(offers, task);
  }

  /// Ambil satu penawaran terbaik untuk sebuah task.
  VolunteerOffer? bestOffer(List<VolunteerOffer> offers, ClientTask task) {
    return ExpertSystem.bestMatch(offers, task);
  }

  // ─── 3. NLP — Analisis Sentimen ───────────────────────────────────────────

  /// Analisis sentimen satu ulasan.
  SentimentResult analyzeSentiment(String review) {
    return SentimentAnalyzer.analyze(review);
  }

  /// Analisis sentimen batch (banyak ulasan sekaligus).
  BatchSentimentResult analyzeReviews(List<String> reviews) {
    return SentimentAnalyzer.analyzeBatch(reviews);
  }

  // ─── 4. Logika Fuzzy — Kesesuaian Task ───────────────────────────────────

  /// Hitung skor kesesuaian task-freelancer menggunakan FIS Mamdani.
  FuzzyResult evaluateSuitability({
    required int taskBudget,
    required int offeredBudget,
    required double rating,
    required int completedTasks,
  }) {
    return FuzzyTaskMatcher.evaluate(
      taskBudget: taskBudget,
      offeredBudget: offeredBudget,
      rating: rating,
      completedTasks: completedTasks,
    );
  }

  // ─── 5. Algoritma Genetika — Optimasi Penawaran ───────────────────────────

  /// Rekomendasikan budget & deadline optimal menggunakan GA.
  GAResult optimizeOffer({
    required int clientBudget,
    required int clientDeadlineDays,
    required double freelancerRating,
    required int completedTasks,
    int? seed,
  }) {
    return GeneticOptimizer(
      clientBudget: clientBudget,
      clientDeadlineDays: clientDeadlineDays,
      freelancerRating: freelancerRating,
      completedTasks: completedTasks,
      seed: seed,
    ).optimize();
  }

  // ─── 6. Concept Learning — Klasifikasi Relevansi Skill ──────────────────

  /// Klasifikasikan apakah skill freelancer relevan untuk task tertentu.
  ConceptClassification classifySkillRelevance({
    required String taskCategory,
    required String freelancerSkill,
    required int taskBudget,
    required int offeredBudget,
    required int completedTasks,
    required double rating,
    required bool isRemote,
  }) {
    return _conceptEngine.classify(
      taskCategory: taskCategory,
      freelancerSkill: freelancerSkill,
      taskBudget: taskBudget,
      offeredBudget: offeredBudget,
      completedTasks: completedTasks,
      rating: rating,
      isRemote: isRemote,
    );
  }

  /// Tambahkan training example baru ke Concept Learner (online learning).
  void learnFromExample(SkillInstance example) {
    _conceptEngine.addTrainingExample(example);
  }

  // ─── Combined: Full AI Score untuk satu penawaran ────────────────────────

  /// Menggabungkan semua modul AI menjadi satu skor komprehensif (0–100).
  ///
  /// Bobot:
  ///   - Sistem Pakar  : 30%
  ///   - Logika Fuzzy  : 25%
  ///   - Concept Learn : 20%
  ///   - GA Fitness    : 25%
  AIComprehensiveScore comprehensiveScore({
    required VolunteerOffer offer,
    required ClientTask task,
    int clientDeadlineDays = 30,
  }) {
    // Expert System
    final expertRecs = ExpertSystem.recommend([offer], task);
    final expertScore = expertRecs.isNotEmpty ? expertRecs.first.score : 0.0;

    // Fuzzy
    final fuzzy = FuzzyTaskMatcher.evaluate(
      taskBudget: task.initialBudget,
      offeredBudget: offer.offeredBudget,
      rating: offer.rating,
      completedTasks: offer.completedTasks,
    );
    final fuzzyScore = fuzzy.score / 100.0;

    // Concept Learning
    final concept = _conceptEngine.classify(
      taskCategory: task.category,
      freelancerSkill: offer.freelancerSkill,
      taskBudget: task.initialBudget,
      offeredBudget: offer.offeredBudget,
      completedTasks: offer.completedTasks,
      rating: offer.rating,
      isRemote: task.assistanceType == AssistanceType.remote,
    );
    final conceptScore = concept.isRelevant ? concept.confidence : concept.confidence * 0.3;

    // GA Fitness
    final ga = GeneticOptimizer(
      clientBudget: task.initialBudget,
      clientDeadlineDays: clientDeadlineDays,
      freelancerRating: offer.rating,
      completedTasks: offer.completedTasks,
      seed: 42,
    ).optimize();
    final gaScore = ga.fitnessScore;

    // Weighted aggregate
    final combined =
        expertScore * 0.30 +
        fuzzyScore * 0.25 +
        conceptScore * 0.20 +
        gaScore * 0.25;

    return AIComprehensiveScore(
      total: (combined * 100).clamp(0, 100).round(),
      expertScore: (expertScore * 100).round(),
      fuzzyScore: fuzzy.scoreInt,
      conceptScore: (conceptScore * 100).round(),
      gaScore: ga.fitnessPercent,
      verdict: expertRecs.isNotEmpty ? expertRecs.first.verdict : 'Perlu Pertimbangan',
    );
  }
}

// ─── Comprehensive Score Result ────────────────────────────────────────────

class AIComprehensiveScore {
  final int total;        // 0–100
  final int expertScore;  // 0–100
  final int fuzzyScore;   // 0–100
  final int conceptScore; // 0–100
  final int gaScore;      // 0–100
  final String verdict;

  const AIComprehensiveScore({
    required this.total,
    required this.expertScore,
    required this.fuzzyScore,
    required this.conceptScore,
    required this.gaScore,
    required this.verdict,
  });

  String get label {
    if (total >= 80) return 'Sangat Direkomendasikan';
    if (total >= 65) return 'Direkomendasikan';
    if (total >= 45) return 'Cukup Sesuai';
    return 'Perlu Pertimbangan';
  }
}