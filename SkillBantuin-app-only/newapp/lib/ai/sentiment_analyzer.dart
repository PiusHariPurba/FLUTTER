import 'dart:math' as dartMath;
// ─────────────────────────────────────────────────────────────────────────────
// Natural Language Processing — Analisis Sentimen Ulasan
//
// Implementasi NLP berbasis lexicon untuk menganalisis sentimen teks ulasan
// client terhadap freelancer di platform SkillBantuin.
//
// Pendekatan: VADER-inspired Lexicon & Rule-Based Sentiment Analysis
//
// Pipeline NLP:
//   1. Pre-processing: lowercase, normalisasi, tokenisasi
//   2. Negation Detection: deteksi kata negasi yang membalik sentimen
//   3. Intensifier Detection: kata penguat/pelemah sentimen
//   4. Lexicon Lookup: cari skor tiap token di kamus sentimen
//   5. Agregasi: hitung compound score
//   6. Klasifikasi: Positif / Netral / Negatif
// ─────────────────────────────────────────────────────────────────────────────

class SentimentAnalyzer {
  // ─── Lexicon: Kata Sentimen ────────────────────────────────────────────────
  // Skor: -1.0 (sangat negatif) hingga +1.0 (sangat positif)

  static const Map<String, double> _lexiconId = {
    // Sangat Positif
    'luar biasa': 0.9, 'sempurna': 0.9, 'terbaik': 0.85, 'sangat bagus': 0.85,
    'memuaskan': 0.75, 'profesional': 0.7, 'cepat': 0.6, 'tepat waktu': 0.7,
    'berkualitas': 0.75, 'handal': 0.7, 'berpengalaman': 0.65, 'ramah': 0.6,
    'responsif': 0.65, 'detail': 0.55, 'teliti': 0.6, 'rekomendasi': 0.7,
    'puas': 0.7, 'bagus': 0.65, 'baik': 0.5, 'oke': 0.4, 'mantap': 0.75,
    'keren': 0.7, 'top': 0.65, 'jago': 0.7, 'canggih': 0.6, 'rapih': 0.55,
    'rapi': 0.55, 'bersih': 0.45, 'hebat': 0.8, 'kreatif': 0.6, 'inovatif': 0.65,
    'terpercaya': 0.75, 'amanah': 0.8, 'komunikatif': 0.65,
    // Negatif
    'mengecewakan': -0.75, 'buruk': -0.7, 'lambat': -0.55, 'terlambat': -0.65,
    'tidak tepat': -0.6, 'tidak rapi': -0.55, 'asal': -0.6, 'kecewa': -0.7,
    'komplain': -0.6, 'jelek': -0.7, 'payah': -0.75, 'banyak revisi': -0.55,
    'kurang': -0.4, 'tidak sesuai': -0.65, 'mahal': -0.3, 'susah': -0.35,
    'sulit dihubungi': -0.6, 'tidak responsif': -0.7, 'kabur': -0.8,
    'tidak jujur': -0.85, 'menipu': -0.95, 'bohong': -0.9, 'penipuan': -0.95,
    'gagal': -0.7, 'tidak selesai': -0.75, 'amatir': -0.6,
  };

  static const Map<String, double> _lexiconEn = {
    // Very Positive
    'excellent': 0.9, 'perfect': 0.9, 'outstanding': 0.85, 'professional': 0.75,
    'reliable': 0.7, 'fast': 0.6, 'on time': 0.7, 'quality': 0.65, 'great': 0.75,
    'good': 0.5, 'skilled': 0.65, 'expert': 0.8, 'recommend': 0.75, 'satisfied': 0.7,
    'happy': 0.65, 'amazing': 0.85, 'fantastic': 0.85, 'superb': 0.9,
    'efficient': 0.65, 'detailed': 0.6, 'responsive': 0.65, 'creative': 0.6,
    'trustworthy': 0.75, 'communicative': 0.65, 'thorough': 0.6,
    // Negative
    'disappointing': -0.7, 'bad': -0.7, 'slow': -0.55, 'late': -0.6,
    'messy': -0.55, 'unprofessional': -0.8, 'poor': -0.65, 'terrible': -0.85,
    'awful': -0.85, 'waste': -0.7, 'fraud': -0.95, 'scam': -0.95, 'dishonest': -0.85,
    'failed': -0.7, 'incomplete': -0.6, 'expensive': -0.3, 'unresponsive': -0.7,
    'difficult': -0.4, 'amateur': -0.6, 'careless': -0.6, 'overpriced': -0.5,
  };

  // Kata negasi (membalik polaritas token berikutnya)
  static const _negationId = {'tidak', 'bukan', 'kurang', 'belum', 'jangan', 'tanpa'};
  static const _negationEn = {'not', "n't", 'never', 'no', 'without', 'lack'};

  // Kata penguat (amplifier: skor × 1.5)
  static const _amplifierSet = {
    'sangat', 'banget', 'sekali', 'amat', 'benar-benar', 'sungguh',
    'really', 'very', 'extremely', 'incredibly', 'truly', 'absolutely'
  };

  // Kata pelemah (dampener: skor × 0.6)
  static const _dampenerSet = {
    'sedikit', 'agak', 'cukup', 'lumayan',
    'somewhat', 'fairly', 'rather', 'slightly', 'kind of'
  };

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Menganalisis sentimen teks ulasan. Deteksi bahasa otomatis.
  static SentimentResult analyze(String text) {
    if (text.trim().isEmpty) {
      return const SentimentResult(
        label: SentimentLabel.neutral,
        compoundScore: 0.0,
        positiveScore: 0.0,
        negativeScore: 0.0,
        tokenScores: [],
      );
    }

    final isIndonesian = _detectIndonesian(text);
    final lexicon = isIndonesian ? _lexiconId : _lexiconEn;
    final negations = isIndonesian ? _negationId : _negationEn;

    final processed = _preprocess(text);
    final tokens = _tokenize(processed);

    final tokenScores = <TokenScore>[];
    double positiveSum = 0.0;
    double negativeSum = 0.0;
    bool negated = false;
    double amplifier = 1.0;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Cek negasi
      if (negations.contains(token)) {
        negated = true;
        continue;
      }

      // Cek amplifier/dampener
      if (_amplifierSet.contains(token)) {
        amplifier = 1.5;
        continue;
      }
      if (_dampenerSet.contains(token)) {
        amplifier = 0.6;
        continue;
      }

      // Cek frasa bigram (2 kata berurutan)
      double? score;
      if (i + 1 < tokens.length) {
        final bigram = '$token ${tokens[i + 1]}';
        score = lexicon[bigram];
      }
      score ??= lexicon[token];

      if (score != null) {
        double adjustedScore = score * amplifier;
        if (negated) adjustedScore = -adjustedScore;

        tokenScores.add(TokenScore(
          token: token,
          rawScore: score,
          adjustedScore: adjustedScore,
          wasNegated: negated,
        ));

        if (adjustedScore > 0) {
          positiveSum += adjustedScore;
        } else {
          negativeSum += adjustedScore.abs();
        }

        // Reset state setelah dipakai
        negated = false;
        amplifier = 1.0;
      }
    }

    // Hitung compound score menggunakan normalisasi VADER
    final raw = positiveSum - negativeSum;
    final alpha = 15.0; // konstanta normalisasi
    final compound = raw / dartMath.sqrt(raw * raw + alpha);

    final label = compound >= 0.05
        ? SentimentLabel.positive
        : compound <= -0.05
            ? SentimentLabel.negative
            : SentimentLabel.neutral;

    return SentimentResult(
      label: label,
      compoundScore: compound.clamp(-1.0, 1.0),
      positiveScore: positiveSum,
      negativeScore: negativeSum,
      tokenScores: tokenScores,
    );
  }

  /// Analisis batch: hitung skor rata-rata dari banyak ulasan
  static BatchSentimentResult analyzeBatch(List<String> reviews) {
    if (reviews.isEmpty) {
      return const BatchSentimentResult(
        averageScore: 0.0,
        positiveCount: 0,
        negativeCount: 0,
        neutralCount: 0,
        results: [],
        overallLabel: SentimentLabel.neutral,
      );
    }

    final results = reviews.map(analyze).toList();
    int pos = 0, neg = 0, neu = 0;
    double totalScore = 0.0;

    for (final r in results) {
      totalScore += r.compoundScore;
      if (r.label == SentimentLabel.positive) pos++;
      else if (r.label == SentimentLabel.negative) neg++;
      else neu++;
    }

    final avg = totalScore / results.length;
    final overall = avg >= 0.05
        ? SentimentLabel.positive
        : avg <= -0.05
            ? SentimentLabel.negative
            : SentimentLabel.neutral;

    return BatchSentimentResult(
      averageScore: avg,
      positiveCount: pos,
      negativeCount: neg,
      neutralCount: neu,
      results: results,
      overallLabel: overall,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static bool _detectIndonesian(String text) {
    final lower = text.toLowerCase();
    const idMarkers = ['yang', 'dan', 'dengan', 'untuk', 'tidak', 'sudah', 'saya', 'kami', 'ini', 'itu'];
    return idMarkers.any((m) => lower.contains(m));
  }

  static String _preprocess(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokenize(String text) {
    return text.split(' ').where((t) => t.isNotEmpty).toList();
  }
}



// ─── Result Models ─────────────────────────────────────────────────────────

enum SentimentLabel { positive, negative, neutral }

extension SentimentLabelExt on SentimentLabel {
  String get display {
    switch (this) {
      case SentimentLabel.positive:
        return 'Positif';
      case SentimentLabel.negative:
        return 'Negatif';
      case SentimentLabel.neutral:
        return 'Netral';
    }
  }

  String get emoji {
    switch (this) {
      case SentimentLabel.positive:
        return '😊';
      case SentimentLabel.negative:
        return '😞';
      case SentimentLabel.neutral:
        return '😐';
    }
  }
}

class TokenScore {
  final String token;
  final double rawScore;
  final double adjustedScore;
  final bool wasNegated;

  const TokenScore({
    required this.token,
    required this.rawScore,
    required this.adjustedScore,
    required this.wasNegated,
  });
}

class SentimentResult {
  final SentimentLabel label;
  final double compoundScore; // -1.0 hingga 1.0
  final double positiveScore;
  final double negativeScore;
  final List<TokenScore> tokenScores;

  const SentimentResult({
    required this.label,
    required this.compoundScore,
    required this.positiveScore,
    required this.negativeScore,
    required this.tokenScores,
  });

  /// Persentase keyakinan (0–100%)
  int get confidencePercent => ((compoundScore.abs() * 100).clamp(0, 100)).round();
}

class BatchSentimentResult {
  final double averageScore;
  final int positiveCount;
  final int negativeCount;
  final int neutralCount;
  final List<SentimentResult> results;
  final SentimentLabel overallLabel;

  const BatchSentimentResult({
    required this.averageScore,
    required this.positiveCount,
    required this.negativeCount,
    required this.neutralCount,
    required this.results,
    required this.overallLabel,
  });

  int get total => positiveCount + negativeCount + neutralCount;
  double get positiveRate => total == 0 ? 0 : positiveCount / total;
  double get negativeRate => total == 0 ? 0 : negativeCount / total;
}
