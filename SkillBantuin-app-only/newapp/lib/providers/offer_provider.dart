import 'package:flutter/material.dart';

import '../ai/expert_system.dart';
import '../models/task_models.dart';
import '../services/offer_service.dart';

/// Provider untuk manajemen offer/lamaran.
///
/// FIXED:
///   - fetchMyOffers() kini memanggil GET /freelancer/offers (bukan return kosong)
///   - fetchAndRankOffersForTask() mengintegrasikan ExpertSystem AI untuk
///     mengurutkan penawaran masuk berdasarkan kesesuaian dengan task.
class OfferProvider extends ChangeNotifier {
  final _service = OfferService();

  // ── My Offers (freelancer) ────────────────────────────────────────────────

  List<dynamic> _myOffers = [];
  List<dynamic> get myOffers => _myOffers;

  /// Backward-compat getter: screens lama yang pakai acceptedOffers
  List<dynamic> get acceptedOffers =>
      _myOffers.where((o) => o['status'] == 'accepted').toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Fetch semua offer milik freelancer yang login.
  ///
  /// FIXED: sebelumnya hard-return [] dengan komentar "nanti ditambah".
  /// Sekarang memanggil GET /freelancer/offers yang sudah ada di backend.
  Future<void> fetchMyOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.getMyOffers();
      if (res.success) {
        final raw = res['data'];
        // Laravel paginate → data ada di raw['data'], plain list → langsung
        if (raw is Map && raw['data'] is List) {
          _myOffers = List<dynamic>.from(raw['data'] as List);
        } else if (raw is List) {
          _myOffers = List<dynamic>.from(raw);
        } else {
          _myOffers = [];
        }
      } else {
        _error = res.message ?? 'Gagal memuat lamaran';
      }
    } catch (e) {
      _error = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Offers per Task (client) dengan AI ranking ────────────────────────────

  /// Map taskId → ranked offers (sudah diurutkan ExpertSystem)
  final Map<int, List<ExpertRecommendation>> _rankedOffers = {};
  Map<int, List<ExpertRecommendation>> get rankedOffers => _rankedOffers;

  bool _isRanking = false;
  bool get isRanking => _isRanking;

  /// Fetch offers untuk task tertentu, lalu rank dengan ExpertSystem AI.
  ///
  /// AI INTEGRATION: ExpertSystem.recommend() mengevaluasi setiap offer
  /// berdasarkan 6 dimensi (rating, harga, kecepatan, pengalaman, kecocokan
  /// skill, dan relevansi pesan) dan mengembalikan rekomendasi terurut.
  ///
  /// Hasilnya di-cache per taskId sehingga tidak re-fetch setiap rebuild.
  Future<List<ExpertRecommendation>> fetchAndRankOffersForTask(
    int taskId,
    ClientTask task,
  ) async {
    _isRanking = true;
    notifyListeners();

    try {
      final res = await _service.getOffers(taskId);
      if (!res.success) {
        _isRanking = false;
        notifyListeners();
        return [];
      }

      final rawList = res['data'] is List
          ? res['data'] as List
          : (res['data']?['data'] as List? ?? []);

      final offers = rawList
          .map((o) => VolunteerOffer.fromApiJson(o as Map<String, dynamic>))
          .toList();

      // ── ExpertSystem ranking ─────────────────────────────────────────────
      // Jika tidak ada offer, return kosong langsung (skip AI call)
      final ranked = offers.isEmpty
          ? <ExpertRecommendation>[]
          : ExpertSystem.recommend(offers, task);

      _rankedOffers[taskId] = ranked;
      _isRanking = false;
      notifyListeners();
      return ranked;
    } catch (e) {
      _isRanking = false;
      notifyListeners();
      return [];
    }
  }
}
