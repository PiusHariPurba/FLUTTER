// ─────────────────────────────────────────────────────────────────────────────
// Logika Fuzzy — Penilaian Kesesuaian Task untuk Freelancer
//
// Implementasi Fuzzy Inference System (FIS) model Mamdani untuk menilai
// seberapa cocok sebuah task dengan profil seorang freelancer.
//
// Pipeline Fuzzy:
//   1. Fuzzifikasi    — konversi nilai crisp ke derajat keanggotaan fuzzy
//   2. Evaluasi Aturan — aplikasi aturan IF-THEN dengan operator AND/OR
//   3. Agregasi       — gabungkan output semua aturan (max method)
//   4. Defuzzifikasi  — konversi output fuzzy ke nilai crisp (centroid)
//
// Variabel Input:
//   - budget_gap   : selisih antara budget task dan budget freelancer (%)
//   - rating_score : rating freelancer (0–5)
//   - experience   : jumlah tugas selesai (0–100+)
//
// Variabel Output:
//   - suitability  : tingkat kesesuaian (0–100)
// ─────────────────────────────────────────────────────────────────────────────

/// Fungsi keanggotaan dasar untuk sistem fuzzy
class MembershipFunction {
  /// Trapezoid: naik dari [a→b], flat dari [b→c], turun dari [c→d]
  static double trapezoid(double x, double a, double b, double c, double d) {
    if (x <= a || x >= d) return 0.0;
    if (x >= b && x <= c) return 1.0;
    if (x < b) return (x - a) / (b - a);
    return (d - x) / (d - c);
  }

  /// Segitiga: naik dari [a→b], turun dari [b→c]
  static double triangle(double x, double a, double b, double c) {
    if (x <= a || x >= c) return 0.0;
    if (x == b) return 1.0;
    if (x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }

  /// Shoulder kiri: nilai 1 untuk x ≤ a, turun ke 0 di [a→b]
  static double shoulderLeft(double x, double a, double b) {
    if (x <= a) return 1.0;
    if (x >= b) return 0.0;
    return (b - x) / (b - a);
  }

  /// Shoulder kanan: nilai 0 untuk x ≤ a, naik ke 1 di [a→b]
  static double shoulderRight(double x, double a, double b) {
    if (x <= a) return 0.0;
    if (x >= b) return 1.0;
    return (x - a) / (b - a);
  }
}

// ─── Fuzzifikasi Input ──────────────────────────────────────────────────────

/// Budget Gap (0–100%) — perbedaan antara anggaran task dan tawaran freelancer
class BudgetGapFS {
  /// Tawaran jauh di bawah anggaran (sangat menguntungkan)
  static double veryLow(double pct) => MembershipFunction.shoulderLeft(pct, 10, 25);

  /// Tawaran sedikit di bawah anggaran
  static double low(double pct) => MembershipFunction.triangle(pct, 10, 25, 45);

  /// Tawaran sekitar anggaran
  static double medium(double pct) => MembershipFunction.triangle(pct, 35, 50, 65);

  /// Tawaran sedikit di atas anggaran
  static double high(double pct) => MembershipFunction.triangle(pct, 55, 70, 90);

  /// Tawaran jauh di atas anggaran
  static double veryHigh(double pct) => MembershipFunction.shoulderRight(pct, 75, 100);
}

/// Rating Freelancer (0.0–5.0)
class RatingFS {
  static double poor(double r) => MembershipFunction.shoulderLeft(r, 2.0, 3.0);
  static double average(double r) => MembershipFunction.triangle(r, 2.5, 3.5, 4.0);
  static double good(double r) => MembershipFunction.triangle(r, 3.5, 4.0, 4.5);
  static double excellent(double r) => MembershipFunction.shoulderRight(r, 4.3, 5.0);
}

/// Pengalaman (jumlah tugas selesai, 0–100+)
class ExperienceFS {
  static double novice(double e) => MembershipFunction.shoulderLeft(e, 3, 8);
  static double intermediate(double e) => MembershipFunction.triangle(e, 5, 15, 25);
  static double experienced(double e) => MembershipFunction.triangle(e, 18, 30, 50);
  static double expert(double e) => MembershipFunction.shoulderRight(e, 40, 80);
}

// ─── Output Fuzzy Sets (Suitability 0–100) ──────────────────────────────────

class SuitabilityFS {
  static const double veryLowCenter = 10.0;
  static const double lowCenter = 30.0;
  static const double mediumCenter = 50.0;
  static const double highCenter = 70.0;
  static const double veryHighCenter = 90.0;
}

// ─── Fuzzy Inference System ─────────────────────────────────────────────────

class FuzzyTaskMatcher {
  /// Menilai kesesuaian task-freelancer menggunakan FIS Mamdani.
  ///
  /// [budgetGapPct]  : (offeredBudget - taskBudget) / taskBudget × 100
  ///                   Negatif = tawaran di bawah budget (baik untuk client)
  /// [rating]        : rating freelancer (0.0–5.0)
  /// [completedTasks]: jumlah tugas selesai
  ///
  /// Return: [FuzzyResult] dengan skor kesesuaian 0–100 dan label linguistik
  static FuzzyResult evaluate({
    required int taskBudget,
    required int offeredBudget,
    required double rating,
    required int completedTasks,
  }) {
    // ── 1. Fuzzifikasi ──────────────────────────────────────────────────────
    // Hitung budget gap sebagai persentase dari task budget
    final double rawGap = taskBudget > 0
        ? ((offeredBudget - taskBudget) / taskBudget * 100)
        : 50.0;
    // Ubah ke 0–100 skala: gap negatif (hemat) → nilai rendah; positif → tinggi
    final double budgetGap = (rawGap + 50).clamp(0.0, 100.0);
    final double exp = completedTasks.toDouble().clamp(0.0, 100.0);

    // Budget Gap memberships
    final bgVL = BudgetGapFS.veryLow(budgetGap);
    final bgL = BudgetGapFS.low(budgetGap);
    final bgM = BudgetGapFS.medium(budgetGap);
    final bgH = BudgetGapFS.high(budgetGap);
    final bgVH = BudgetGapFS.veryHigh(budgetGap);

    // Rating memberships
    final rP = RatingFS.poor(rating);
    final rA = RatingFS.average(rating);
    final rG = RatingFS.good(rating);
    final rE = RatingFS.excellent(rating);

    // Experience memberships
    final eN = ExperienceFS.novice(exp);
    final eI = ExperienceFS.intermediate(exp);
    final eEx = ExperienceFS.experienced(exp);
    final eXP = ExperienceFS.expert(exp);

    // ── 2. Evaluasi Aturan Fuzzy (IF-THEN) ─────────────────────────────────
    // Operator AND = min(), OR = max()
    final Map<double, double> activated = {}; // center → activation strength

    void fire(double center, double strength) {
      if (strength > 0) {
        activated[center] = _max(activated[center] ?? 0.0, strength);
      }
    }

    // === HIGH SUITABILITY RULES ===
    // R1: IF budget VeryLow AND rating Excellent → VeryHigh
    fire(SuitabilityFS.veryHighCenter, _min(bgVL, rE));
    // R2: IF budget VeryLow AND rating Good AND exp Expert → VeryHigh
    fire(SuitabilityFS.veryHighCenter, _min3(bgVL, rG, eXP));
    // R3: IF budget Low AND rating Excellent AND exp Experienced → High
    fire(SuitabilityFS.highCenter, _min3(bgL, rE, eEx));
    // R4: IF budget Low AND rating Excellent AND exp Expert → VeryHigh
    fire(SuitabilityFS.veryHighCenter, _min3(bgL, rE, eXP));
    // R5: IF rating Excellent AND exp Expert → High
    fire(SuitabilityFS.highCenter, _min(rE, eXP));

    // === MEDIUM-HIGH SUITABILITY RULES ===
    // R6: IF budget Medium AND rating Good AND exp Experienced → High
    fire(SuitabilityFS.highCenter, _min3(bgM, rG, eEx));
    // R7: IF budget Low AND rating Good AND exp Intermediate → High
    fire(SuitabilityFS.highCenter, _min3(bgL, rG, eI));
    // R8: IF budget VeryLow AND rating Average AND exp Expert → High
    fire(SuitabilityFS.highCenter, _min3(bgVL, rA, eXP));
    // R9: IF rating Good AND exp Expert → High
    fire(SuitabilityFS.highCenter, _min(rG, eXP));

    // === MEDIUM SUITABILITY RULES ===
    // R10: IF budget Medium AND rating Average AND exp Intermediate → Medium
    fire(SuitabilityFS.mediumCenter, _min3(bgM, rA, eI));
    // R11: IF budget Medium AND rating Good AND exp Novice → Medium
    fire(SuitabilityFS.mediumCenter, _min3(bgM, rG, eN));
    // R12: IF budget Low AND rating Average AND exp Intermediate → Medium
    fire(SuitabilityFS.mediumCenter, _min3(bgL, rA, eI));
    // R13: IF rating Average AND exp Experienced → Medium
    fire(SuitabilityFS.mediumCenter, _min(rA, eEx));

    // === LOW SUITABILITY RULES ===
    // R14: IF budget High AND rating Average → Low
    fire(SuitabilityFS.lowCenter, _min(bgH, rA));
    // R15: IF budget Medium AND rating Poor → Low
    fire(SuitabilityFS.lowCenter, _min(bgM, rP));
    // R16: IF exp Novice AND rating Average → Low
    fire(SuitabilityFS.lowCenter, _min(eN, rA));
    // R17: IF budget High AND rating Good AND exp Novice → Low
    fire(SuitabilityFS.lowCenter, _min3(bgH, rG, eN));

    // === VERY LOW SUITABILITY RULES ===
    // R18: IF budget VeryHigh → VeryLow
    fire(SuitabilityFS.veryLowCenter, bgVH);
    // R19: IF rating Poor → VeryLow
    fire(SuitabilityFS.veryLowCenter, rP);
    // R20: IF budget High AND rating Poor → VeryLow
    fire(SuitabilityFS.veryLowCenter, _min(bgH, rP));

    // ── 3. Defuzzifikasi (Centroid / Center of Gravity) ─────────────────────
    if (activated.isEmpty) {
      return const FuzzyResult(
        score: 0.0,
        label: 'Tidak Dinilai',
        membershipBreakdown: {},
      );
    }

    double numerator = 0.0;
    double denominator = 0.0;

    activated.forEach((center, strength) {
      numerator += center * strength;
      denominator += strength;
    });

    final crisp = denominator > 0 ? numerator / denominator : 0.0;
    final clamped = crisp.clamp(0.0, 100.0);

    return FuzzyResult(
      score: clamped,
      label: _linguisticLabel(clamped),
      membershipBreakdown: {
        'budget_gap': budgetGap,
        'bg_verylow': bgVL,
        'bg_low': bgL,
        'bg_medium': bgM,
        'bg_high': bgH,
        'bg_veryhigh': bgVH,
        'rating_poor': rP,
        'rating_average': rA,
        'rating_good': rG,
        'rating_excellent': rE,
        'exp_novice': eN,
        'exp_intermediate': eI,
        'exp_experienced': eEx,
        'exp_expert': eXP,
      },
    );
  }

  static String _linguisticLabel(double score) {
    if (score >= 80) return 'Sangat Sesuai';
    if (score >= 60) return 'Sesuai';
    if (score >= 40) return 'Cukup Sesuai';
    if (score >= 20) return 'Kurang Sesuai';
    return 'Tidak Sesuai';
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
  static double _min3(double a, double b, double c) => _min(a, _min(b, c));
}

// ─── Result Model ─────────────────────────────────────────────────────────

class FuzzyResult {
  final double score; // 0–100
  final String label; // label linguistik
  final Map<String, double> membershipBreakdown;

  const FuzzyResult({
    required this.score,
    required this.label,
    required this.membershipBreakdown,
  });

  int get scoreInt => score.round();

  /// Warna indikator (untuk UI)
  String get colorHex {
    if (score >= 80) return '#2ECC71'; // hijau
    if (score >= 60) return '#27AE60'; // hijau tua
    if (score >= 40) return '#F39C12'; // oranye
    if (score >= 20) return '#E67E22'; // oranye tua
    return '#E74C3C'; // merah
  }
}
