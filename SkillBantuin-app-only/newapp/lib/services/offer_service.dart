import 'api_client.dart';

/// Service offer/lamaran — menghubungkan ke Laravel /offers endpoints.
/// Freelancer: kirim lamaran, lihat my-offers, update progress.
/// Client: lihat offers per task, accept/reject, review.
class OfferService {
  final _api = ApiClient();

  // ── CLIENT ────────────────────────────────────────────────────────────────

  /// List offers untuk task tertentu — GET /tasks/{id}/offers
  /// Hanya bisa diakses oleh pemilik task (client).
  Future<ApiResponse> getOffers(int taskId) async {
    return _api.get('/tasks/$taskId/offers');
  }

  /// Client terima offer — PUT /tasks/{taskId}/offers/{offerId}/accept
  Future<ApiResponse> acceptOffer(int taskId, int offerId) async {
    return _api.put('/tasks/$taskId/offers/$offerId/accept');
  }

  /// Client tolak offer — PUT /tasks/{taskId}/offers/{offerId}/reject
  Future<ApiResponse> rejectOffer(int taskId, int offerId) async {
    return _api.put('/tasks/$taskId/offers/$offerId/reject');
  }

  // ── FREELANCER ────────────────────────────────────────────────────────────

  /// Freelancer kirim lamaran — POST /tasks/{id}/offers
  ///
  /// FIXED: field names disesuaikan dengan validasi Laravel:
  ///   cover_letter  (bukan message)
  ///   price         (bukan proposed_budget)
  ///   duration_days (bukan estimated_days)
  Future<ApiResponse> submitOffer(
    int taskId, {
    required String coverLetter,
    required double price,
    required int durationDays,
  }) async {
    return _api.post('/tasks/$taskId/offers', body: {
      'cover_letter':  coverLetter,
      'price':         price,
      'duration_days': durationDays,
    });
  }

  /// List semua penawaran milik freelancer — GET /freelancer/offers
  ///
  /// FIXED: endpoint ini sebelumnya tidak ada di routes, sekarang sudah
  /// ditambahkan bersama dengan ProgressController routes.
  Future<ApiResponse> getMyOffers({int page = 1, int perPage = 15}) async {
    return _api.get('/freelancer/offers', queryParams: {
      'page':     page.toString(),
      'per_page': perPage.toString(),
    });
  }

  // ── PROGRESS ──────────────────────────────────────────────────────────────

  /// Dashboard progress freelancer — GET /freelancer/progress
  ///
  /// FIXED: route ini sebelumnya tidak terdaftar di api.php.
  /// Returns: active_jobs, nearest_deadlines, running_projects, recent_activities.
  Future<ApiResponse> getProgressDashboard() async {
    return _api.get('/freelancer/progress');
  }

  /// Update progres pengerjaan — PUT /offers/{offerId}/progress
  ///
  /// FIXED: route ini sebelumnya tidak terdaftar di api.php.
  /// [workStatus]: 'on_track' | 'in_progress' | 'revision' | 'completed'
  Future<ApiResponse> updateProgress(
    int offerId, {
    required int progressPercent,
    required String workStatus,
    String? progressNotes,
  }) async {
    return _api.put('/offers/$offerId/progress', body: {
      'progress_percent': progressPercent,
      'work_status':      workStatus,
      if (progressNotes != null) 'progress_notes': progressNotes,
    });
  }

  // ── REVIEW ────────────────────────────────────────────────────────────────

  /// Beri review setelah offer selesai — POST /offers/{offerId}/review
  Future<ApiResponse> submitReview(
    int offerId, {
    required int rating,
    required String comment,
  }) async {
    return _api.post('/offers/$offerId/review', body: {
      'rating':  rating,
      'comment': comment,
    });
  }
}
