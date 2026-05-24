// ─────────────────────────────────────────────────────────────────────────────
// Concept Learning — Kategorisasi & Klasifikasi Skill Freelancer
//
// Implementasi algoritma Concept Learning (Find-S + Candidate Elimination)
// untuk mempelajari konsep "skill yang relevan" dari contoh positif/negatif,
// dan mengklasifikasikan apakah skill seorang freelancer relevan
// untuk sebuah task berdasarkan konsep yang dipelajari.
//
// Representasi Hipotesis (Attribute Space):
//   [categoryMatch, budgetRange, experienceLevel, ratingTier, locationType]
//   '?' = any value (most general)
//   '∅' = no value (most specific, concept empty)
//   'val' = specific value
//
// Algoritma:
//   - Find-S     : mencari hipotesis paling spesifik yang konsisten
//   - Version Space : boundary S (specific) dan G (general)
// ─────────────────────────────────────────────────────────────────────────────

/// Atribut instance skill-task
class SkillInstance {
  final String categoryMatch; // 'exact', 'related', 'unrelated'
  final String budgetRange;   // 'low', 'medium', 'high'
  final String experienceLevel; // 'novice', 'intermediate', 'expert'
  final String ratingTier;    // 'poor', 'average', 'good', 'excellent'
  final String locationType;  // 'remote', 'onsite', 'hybrid'
  final bool isPositive;      // label: true = relevan, false = tidak

  const SkillInstance({
    required this.categoryMatch,
    required this.budgetRange,
    required this.experienceLevel,
    required this.ratingTier,
    required this.locationType,
    required this.isPositive,
  });

  List<String> get attributes => [
    categoryMatch, budgetRange, experienceLevel, ratingTier, locationType
  ];
}

/// Hipotesis: sebuah konjungsi dari nilai atribut / wildcard
class Hypothesis {
  // Setiap elemen: '?' (any), '∅' (empty), atau nilai spesifik
  final List<String> conditions;

  Hypothesis(this.conditions);

  factory Hypothesis.mostSpecific() =>
      Hypothesis(['∅', '∅', '∅', '∅', '∅']);

  factory Hypothesis.mostGeneral() =>
      Hypothesis(['?', '?', '?', '?', '?']);

  factory Hypothesis.copy(Hypothesis h) =>
      Hypothesis(List.from(h.conditions));

  /// Apakah hipotesis ini mencakup instance [inst]?
  bool covers(SkillInstance inst) {
    final attrs = inst.attributes;
    for (int i = 0; i < conditions.length; i++) {
      if (conditions[i] == '∅') return false;
      if (conditions[i] == '?') continue;
      if (conditions[i] != attrs[i]) return false;
    }
    return true;
  }

  /// Apakah ini hipotesis kosong (tidak meng-cover apapun)?
  bool get isEmpty => conditions.every((c) => c == '∅');

  /// Apakah ini hipotesis paling umum?
  bool get isGeneral => conditions.every((c) => c == '?');

  @override
  String toString() => '[${conditions.join(', ')}]';
}

// ─── Find-S Algorithm ─────────────────────────────────────────────────────

class FindSLearner {
  Hypothesis _h = Hypothesis.mostSpecific();
  bool _initialized = false;

  /// Memperbarui hipotesis dengan contoh baru (hanya positive examples)
  void learn(SkillInstance instance) {
    if (!instance.isPositive) return; // Find-S hanya gunakan positif

    final attrs = instance.attributes;

    if (!_initialized || _h.isEmpty) {
      // Hipotesis pertama: langsung dari contoh positif pertama
      _h = Hypothesis(List.from(attrs));
      _initialized = true;
      return;
    }

    // Generalisasi: setiap atribut yang tidak cocok → '?'
    for (int i = 0; i < _h.conditions.length; i++) {
      if (_h.conditions[i] != attrs[i]) {
        _h.conditions[i] = '?';
      }
    }
  }

  /// Klasifikasi instance baru
  bool classify(SkillInstance instance) => _h.covers(instance);

  Hypothesis get currentHypothesis => _h;

  void reset() {
    _h = Hypothesis.mostSpecific();
    _initialized = false;
  }
}

// ─── Concept Learning Engine ───────────────────────────────────────────────

class ConceptLearningEngine {
  final FindSLearner _learner = FindSLearner();

  // Training data bawaan — contoh skill-task yang relevan/tidak
  static final List<SkillInstance> _trainingData = [
    // Positif: kombinasi yang seharusnya relevan
    const SkillInstance(categoryMatch: 'exact', budgetRange: 'medium', experienceLevel: 'expert', ratingTier: 'excellent', locationType: 'remote', isPositive: true),
    const SkillInstance(categoryMatch: 'exact', budgetRange: 'low', experienceLevel: 'experienced', ratingTier: 'good', locationType: 'remote', isPositive: true),
    const SkillInstance(categoryMatch: 'related', budgetRange: 'medium', experienceLevel: 'expert', ratingTier: 'excellent', locationType: 'onsite', isPositive: true),
    const SkillInstance(categoryMatch: 'exact', budgetRange: 'high', experienceLevel: 'expert', ratingTier: 'good', locationType: 'hybrid', isPositive: true),
    const SkillInstance(categoryMatch: 'exact', budgetRange: 'low', experienceLevel: 'intermediate', ratingTier: 'good', locationType: 'remote', isPositive: true),
    const SkillInstance(categoryMatch: 'related', budgetRange: 'low', experienceLevel: 'expert', ratingTier: 'excellent', locationType: 'remote', isPositive: true),
    // Negatif: kombinasi yang tidak relevan
    const SkillInstance(categoryMatch: 'unrelated', budgetRange: 'high', experienceLevel: 'novice', ratingTier: 'poor', locationType: 'onsite', isPositive: false),
    const SkillInstance(categoryMatch: 'unrelated', budgetRange: 'medium', experienceLevel: 'novice', ratingTier: 'average', locationType: 'remote', isPositive: false),
    const SkillInstance(categoryMatch: 'exact', budgetRange: 'high', experienceLevel: 'novice', ratingTier: 'poor', locationType: 'onsite', isPositive: false),
  ];

  ConceptLearningEngine() {
    // Train dengan data bawaan
    _trainOnDefaultData();
  }

  void _trainOnDefaultData() {
    _learner.reset();
    for (final inst in _trainingData) {
      _learner.learn(inst);
    }
  }

  /// Tambahkan contoh baru untuk adaptasi online
  void addTrainingExample(SkillInstance instance) {
    _learner.learn(instance);
  }

  /// Klasifikasi: apakah freelancer relevan untuk task?
  ConceptClassification classify({
    required String taskCategory,
    required String freelancerSkill,
    required int taskBudget,
    required int offeredBudget,
    required int completedTasks,
    required double rating,
    required bool isRemote,
  }) {
    final categoryMatch = _categoryMatchLevel(taskCategory, freelancerSkill);
    final budgetRange = _budgetRange(taskBudget, offeredBudget);
    final expLevel = _experienceLevel(completedTasks);
    final ratingTier = _ratingTier(rating);
    final locationType = isRemote ? 'remote' : 'onsite';

    final instance = SkillInstance(
      categoryMatch: categoryMatch,
      budgetRange: budgetRange,
      experienceLevel: expLevel,
      ratingTier: ratingTier,
      locationType: locationType,
      isPositive: true, // label untuk evaluasi
    );

    final isRelevant = _learner.classify(instance);
    final confidence = _computeConfidence(instance);

    return ConceptClassification(
      isRelevant: isRelevant,
      confidence: confidence,
      hypothesis: _learner.currentHypothesis,
      attributeBreakdown: {
        'categoryMatch': categoryMatch,
        'budgetRange': budgetRange,
        'experienceLevel': expLevel,
        'ratingTier': ratingTier,
        'locationType': locationType,
      },
      reasoning: _buildReasoning(categoryMatch, expLevel, ratingTier, budgetRange),
    );
  }

  // ─── Attribute Discretization ──────────────────────────────────────────

  String _categoryMatchLevel(String taskCategory, String freelancerSkill) {
    final tc = taskCategory.toLowerCase();
    final fs = freelancerSkill.toLowerCase();
    // Exact: ada overlap langsung
    final tcWords = tc.split(RegExp(r'[\s/,&]+'));
    final fsWords = fs.split(RegExp(r'[\s/,&]+'));
    if (tcWords.any((w) => w.length > 2 && fsWords.any((fw) => fw.contains(w) || w.contains(fw)))) {
      return 'exact';
    }
    // Related: keduanya dalam domain yang sama
    final relatedGroups = [
      {'konstruksi', 'bangunan', 'sipil', 'struktur', 'arsitektur', 'construction', 'building'},
      {'digital', 'it', 'software', 'programming', 'tech', 'web', 'mobile'},
      {'desain', 'design', 'grafis', 'ui', 'ux', 'creative'},
      {'marketing', 'pemasaran', 'sosial media', 'branding', 'content'},
      {'keuangan', 'finance', 'accounting', 'pajak', 'audit'},
    ];
    for (final group in relatedGroups) {
      final tcInGroup = group.any((g) => tc.contains(g));
      final fsInGroup = group.any((g) => fs.contains(g));
      if (tcInGroup && fsInGroup) return 'related';
    }
    return 'unrelated';
  }

  String _budgetRange(int taskBudget, int offeredBudget) {
    final ratio = taskBudget > 0 ? offeredBudget / taskBudget : 1.0;
    if (ratio <= 0.85) return 'low';    // tawaran jauh di bawah
    if (ratio <= 1.05) return 'medium'; // sesuai anggaran
    return 'high';                       // melebihi anggaran
  }

  String _experienceLevel(int completedTasks) {
    if (completedTasks < 5) return 'novice';
    if (completedTasks < 15) return 'intermediate';
    if (completedTasks < 30) return 'experienced';
    return 'expert';
  }

  String _ratingTier(double rating) {
    if (rating < 3.0) return 'poor';
    if (rating < 4.0) return 'average';
    if (rating < 4.5) return 'good';
    return 'excellent';
  }

  /// Hitung confidence berdasarkan seberapa banyak atribut cocok dengan hipotesis
  double _computeConfidence(SkillInstance inst) {
    final h = _learner.currentHypothesis;
    final attrs = inst.attributes;
    int matched = 0;
    int total = 0;

    for (int i = 0; i < h.conditions.length; i++) {
      if (h.conditions[i] == '∅') continue;
      total++;
      if (h.conditions[i] == '?' || h.conditions[i] == attrs[i]) {
        matched++;
      }
    }

    return total > 0 ? matched / total : 0.5;
  }

  String _buildReasoning(String cat, String exp, String rating, String budget) {
    final parts = <String>[];
    if (cat == 'exact') parts.add('keahlian sangat relevan');
    else if (cat == 'related') parts.add('keahlian cukup relevan');
    else parts.add('keahlian kurang relevan');

    if (exp == 'expert') parts.add('sangat berpengalaman');
    else if (exp == 'experienced') parts.add('berpengalaman');
    else if (exp == 'intermediate') parts.add('cukup berpengalaman');
    else parts.add('masih pemula');

    if (rating == 'excellent') parts.add('rating sangat baik');
    else if (rating == 'good') parts.add('rating baik');
    else if (rating == 'average') parts.add('rating rata-rata');
    else parts.add('rating rendah');

    if (budget == 'low') parts.add('tawaran harga sangat kompetitif');
    else if (budget == 'medium') parts.add('harga sesuai anggaran');
    else parts.add('harga melebihi anggaran');

    return parts.join(', ');
  }
}

// ─── Result Model ──────────────────────────────────────────────────────────

class ConceptClassification {
  final bool isRelevant;
  final double confidence; // 0.0–1.0
  final Hypothesis hypothesis;
  final Map<String, String> attributeBreakdown;
  final String reasoning;

  const ConceptClassification({
    required this.isRelevant,
    required this.confidence,
    required this.hypothesis,
    required this.attributeBreakdown,
    required this.reasoning,
  });

  int get confidencePercent => (confidence * 100).round();

  String get label => isRelevant ? 'Relevan' : 'Kurang Relevan';
}
