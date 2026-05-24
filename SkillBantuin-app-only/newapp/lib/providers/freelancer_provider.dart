import 'package:flutter/foundation.dart';
import '../services/freelancer_service.dart';
import '../services/offer_service.dart';

/// Provider freelancer — browse freelancer, submit offers, manage profil.
class FreelancerProvider extends ChangeNotifier {
  final FreelancerService _flSvc = FreelancerService();
  final OfferService _offerSvc = OfferService();

  List<Map<String, dynamic>> _freelancers = [];
  Map<String, dynamic>? _currentFreelancer;
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get freelancers => _freelancers;
  Map<String, dynamic>? get currentFreelancer => _currentFreelancer;
  List<Map<String, dynamic>> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load daftar freelancer (client browsing)
  Future<void> loadFreelancers({String? search, String? category, double? minRating}) async {
    _isLoading = true;
    notifyListeners();

    final res = await _flSvc.getFreelancers(search: search, category: category, minRating: minRating);
    if (res.success) {
      _freelancers = List<Map<String, dynamic>>.from(res['data']?['data'] ?? []);
    } else {
      _error = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load detail freelancer
  Future<void> loadFreelancer(int id) async {
    _isLoading = true;
    notifyListeners();

    final res = await _flSvc.getFreelancer(id);
    if (res.success) {
      _currentFreelancer = Map<String, dynamic>.from(res['data'] ?? {});
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Submit offer/lamaran ke task (freelancer)
  Future<bool> submitOffer(int taskId, {required String message, required double budget, int? days}) async {
    final res = await _offerSvc.submitOffer(taskId, coverLetter: message, price: budget, durationDays: days ?? 7);
    if (res.success) return true;
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Load offers untuk task tertentu (client)
  Future<void> loadOffers(int taskId) async {
    _isLoading = true;
    notifyListeners();

    final res = await _offerSvc.getOffers(taskId);
    if (res.success) {
      _offers = List<Map<String, dynamic>>.from(res['data'] ?? []);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Accept offer (client)
  Future<bool> acceptOffer(int taskId, int offerId) async {
    final res = await _offerSvc.acceptOffer(taskId, offerId);
    if (res.success) {
      await loadOffers(taskId);
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Reject offer (client)
  Future<bool> rejectOffer(int taskId, int offerId) async {
    final res = await _offerSvc.rejectOffer(taskId, offerId);
    if (res.success) {
      await loadOffers(taskId);
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Submit review (setelah task selesai)
  Future<bool> submitReview(int offerId, {required int rating, required String comment}) async {
    final res = await _offerSvc.submitReview(offerId, rating: rating, comment: comment);
    if (res.success) return true;
    _error = res.message;
    notifyListeners();
    return false;
  }
}
