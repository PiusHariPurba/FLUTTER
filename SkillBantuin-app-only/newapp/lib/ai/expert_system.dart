// ─────────────────────────────────────────────────────────────────────────────
// Sistem Pakar — Rekomendasi Freelancer (Forward Chaining)
//
// Sistem pakar berbasis aturan (rule-based) menggunakan mekanisme
// Forward Chaining untuk merekomendasikan freelancer terbaik bagi
// sebuah task.
//
// Knowledge Base terdiri dari:
//   - Facts: data freelancer (rating, pengalaman, budget, kategori)
//   - Rules: aturan IF-THEN yang dieksekusi secara berurutan
//   - Inference Engine: evaluasi aturan terhadap facts
//
// Rekomendasi dihasilkan sebagai skor total tertimbang dari semua
// aturan yang terpicu (fired rules).
// ─────────────────────────────────────────────────────────────────────────────

import '../models/task_models.dart';

/// Represents a single rule in the knowledge base.
class ExpertRule {
  final String id;
  final String description;
  final double weight; // bobot kontribusi skor jika rule terpicu
  final bool Function(FreelancerFacts, TaskFacts) condition;

  const ExpertRule({
    required this.id,
    required this.description,
    required this.weight,
    required this.condition,
  });
}

/// Facts tentang seorang freelancer
class FreelancerFacts {
  final String name;
  final String skill;
  final double rating;
  final int completedTasks;
  final int offeredBudget;
  final String proposedDeadline;
  final String message;
  final OfferStatus status;

  const FreelancerFacts({
    required this.name,
    required this.skill,
    required this.rating,
    required this.completedTasks,
    required this.offeredBudget,
    required this.proposedDeadline,
    required this.message,
    required this.status,
  });

  factory FreelancerFacts.fromOffer(VolunteerOffer offer) {
    return FreelancerFacts(
      name: offer.freelancerName,
      skill: offer.freelancerSkill,
      rating: offer.rating,
      completedTasks: offer.completedTasks,
      offeredBudget: offer.offeredBudget,
      proposedDeadline: offer.proposedDeadline,
      message: offer.message,
      status: offer.status,
    );
  }
}

/// Facts tentang sebuah task yang perlu diisi
class TaskFacts {
  final String category;
  final int budgetCap;
  final AssistanceType assistanceType;
  final bool isUrgent;

  const TaskFacts({
    required this.category,
    required this.budgetCap,
    required this.assistanceType,
    this.isUrgent = false,
  });

  factory TaskFacts.fromTask(ClientTask task) {
    return TaskFacts(
      category: task.category,
      budgetCap: task.initialBudget,
      assistanceType: task.assistanceType,
      isUrgent: task.deadlineLabel.toLowerCase().contains('hari ini') ||
          task.deadlineLabel.toLowerCase().contains('today') ||
          task.deadlineLabel.toLowerCase().contains('besok') ||
          task.deadlineLabel.toLowerCase().contains('tomorrow'),
    );
  }
}

/// Inference Engine — menjalankan forward chaining
class ExpertSystem {
  // ─── Knowledge Base: Aturan Pakar ─────────────────────────────────────────

  static final List<ExpertRule> _rules = [
    // R1: Rating premium (≥ 4.5)
    ExpertRule(
      id: 'R1',
      description: 'Freelancer memiliki rating premium (≥ 4.5 bintang)',
      weight: 0.25,
      condition: (f, t) => f.rating >= 4.5,
    ),

    // R2: Rating baik (≥ 4.0)
    ExpertRule(
      id: 'R2',
      description: 'Freelancer memiliki rating baik (≥ 4.0 bintang)',
      weight: 0.15,
      condition: (f, t) => f.rating >= 4.0 && f.rating < 4.5,
    ),

    // R3: Pengalaman tinggi (≥ 20 tugas selesai)
    ExpertRule(
      id: 'R3',
      description: 'Freelancer berpengalaman (≥ 20 tugas selesai)',
      weight: 0.20,
      condition: (f, t) => f.completedTasks >= 20,
    ),

    // R4: Pengalaman sedang (≥ 5 tugas selesai)
    ExpertRule(
      id: 'R4',
      description: 'Freelancer cukup berpengalaman (≥ 5 tugas)',
      weight: 0.10,
      condition: (f, t) => f.completedTasks >= 5 && f.completedTasks < 20,
    ),

    // R5: Budget sesuai (≤ 90% budget client)
    ExpertRule(
      id: 'R5',
      description: 'Tawaran budget sangat kompetitif (≤ 90% budget)',
      weight: 0.20,
      condition: (f, t) => f.offeredBudget <= (t.budgetCap * 0.9).round(),
    ),

    // R6: Budget dalam range (≤ budget client)
    ExpertRule(
      id: 'R6',
      description: 'Tawaran budget dalam batas anggaran client',
      weight: 0.10,
      condition: (f, t) =>
          f.offeredBudget <= t.budgetCap &&
          f.offeredBudget > (t.budgetCap * 0.9).round(),
    ),

    // R7: Kategori skill relevan
    ExpertRule(
      id: 'R7',
      description: 'Keahlian freelancer relevan dengan kategori task',
      weight: 0.20,
      condition: (f, t) {
        final skillLower = f.skill.toLowerCase();
        final catLower = t.category.toLowerCase();
        // Cek apakah ada overlap kata kunci
        final skillWords = skillLower.split(RegExp(r'[\s,/&]+'));
        final catWords = catLower.split(RegExp(r'[\s,/&]+'));
        return skillWords.any((sw) =>
            sw.length > 2 && catWords.any((cw) => cw.contains(sw) || sw.contains(cw)));
      },
    ),

    // R8: Penawaran disertai pesan detail (≥ 30 karakter)
    ExpertRule(
      id: 'R8',
      description: 'Freelancer memberikan proposal yang detail',
      weight: 0.05,
      condition: (f, t) => f.message.length >= 30,
    ),

    // R9: Bonus untuk task urgent — freelancer berpengalaman tinggi
    ExpertRule(
      id: 'R9',
      description: 'Freelancer berpengalaman cocok untuk task mendesak',
      weight: 0.15,
      condition: (f, t) => t.isUrgent && f.completedTasks >= 10,
    ),

    // R10: Kombinasi rating tinggi + berpengalaman = pilihan utama
    ExpertRule(
      id: 'R10',
      description: 'Kombinasi sempurna: rating tinggi + berpengalaman',
      weight: 0.30,
      condition: (f, t) => f.rating >= 4.5 && f.completedTasks >= 15,
    ),
  ];

  // ─── Inference Engine ──────────────────────────────────────────────────────

  /// Menjalankan forward chaining dan mengembalikan rekomendasi terurut
  static List<ExpertRecommendation> recommend(
    List<VolunteerOffer> offers,
    ClientTask task,
  ) {
    final taskFacts = TaskFacts.fromTask(task);
    final results = <ExpertRecommendation>[];

    for (final offer in offers) {
      if (offer.status == OfferStatus.rejected) continue;

      final facts = FreelancerFacts.fromOffer(offer);
      final firedRules = <ExpertRule>[];
      double totalScore = 0.0;

      // Forward Chaining: evaluasi setiap rule
      for (final rule in _rules) {
        if (rule.condition(facts, taskFacts)) {
          firedRules.add(rule);
          totalScore += rule.weight;
        }
      }

      // Normalisasi: maksimum teoritis = jumlah semua weight
      final maxPossible = _rules.fold<double>(0, (s, r) => s + r.weight);
      final normalizedScore = (totalScore / maxPossible).clamp(0.0, 1.0);

      results.add(ExpertRecommendation(
        offer: offer,
        score: normalizedScore,
        firedRules: firedRules,
        verdict: _verdict(normalizedScore),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Menghasilkan rekomendasi teks berdasarkan skor
  static String _verdict(double score) {
    if (score >= 0.75) return 'Sangat Direkomendasikan';
    if (score >= 0.55) return 'Direkomendasikan';
    if (score >= 0.35) return 'Cukup Sesuai';
    return 'Perlu Pertimbangan';
  }

  /// Shorthand: ambil satu freelancer terbaik untuk sebuah task
  static VolunteerOffer? bestMatch(
    List<VolunteerOffer> offers,
    ClientTask task,
  ) {
    final recs = recommend(offers, task);
    return recs.isEmpty ? null : recs.first.offer;
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────

class ExpertRecommendation {
  final VolunteerOffer offer;
  final double score; // 0.0 – 1.0
  final List<ExpertRule> firedRules;
  final String verdict;

  const ExpertRecommendation({
    required this.offer,
    required this.score,
    required this.firedRules,
    required this.verdict,
  });

  /// Penjelasan singkat mengapa freelancer direkomendasikan
  String get explanation {
    if (firedRules.isEmpty) return 'Tidak ada aturan yang terpicu.';
    final topRules = firedRules.take(3).map((r) => '• ${r.description}').join('\n');
    return topRules;
  }
}
