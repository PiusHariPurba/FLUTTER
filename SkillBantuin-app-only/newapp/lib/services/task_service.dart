import 'api_client.dart';
import '../config/app_config.dart';

/// Service untuk task/proyek — menghubungkan ke Laravel /tasks endpoints.
/// Client: buat task, lihat offers, update status.
/// Freelancer: browse task, apply via offer.
class TaskService {
  final _api = ApiClient();

  /// List semua task (public) — GET /tasks
  /// Bisa filter by [status], [category], [search], [budgetMax]
  Future<ApiResponse> getTasks({
    String? status,
    String? category,
    String? search,
    double? budgetMax,
    int page = 1,
    int perPage = AppConfig.defaultPerPage,
  }) async {
    // Bangun query params — hanya kirim yang tidak null
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null) params['status'] = status;
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    if (budgetMax != null) params['budget_max'] = budgetMax.toStringAsFixed(0);

    return _api.get('/tasks', queryParams: params);
  }

  /// Detail satu task — GET /tasks/{id}
  /// Termasuk client info, offers, dan freelancer profiles
  Future<ApiResponse> getTask(int id) async {
    return _api.get('/tasks/$id');
  }

  /// Buat task baru (client only) — POST /tasks
  Future<ApiResponse> createTask({
    required String title,
    required String description,
    String? category,
    double? budgetMin,
    double? budgetMax,
    String? deadline,
    List<String>? requiredSkills,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (category != null) body['category'] = category;
    if (budgetMin != null) body['budget_min'] = budgetMin;
    if (budgetMax != null) body['budget_max'] = budgetMax;
    if (deadline != null) body['deadline'] = deadline;
    if (requiredSkills != null) body['required_skills'] = requiredSkills;

    return _api.post('/tasks', body: body);
  }

  /// Update task (client only, pemilik) — PUT /tasks/{id}
  Future<ApiResponse> updateTask(int id, {
    String? title,
    String? description,
    String? category,
    double? budgetMin,
    double? budgetMax,
    String? deadline,
    String? status,
    List<String>? requiredSkills,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (category != null) body['category'] = category;
    if (budgetMin != null) body['budget_min'] = budgetMin;
    if (budgetMax != null) body['budget_max'] = budgetMax;
    if (deadline != null) body['deadline'] = deadline;
    if (status != null) body['status'] = status;
    if (requiredSkills != null) body['required_skills'] = requiredSkills;

    return _api.put('/tasks/$id', body: body);
  }

  /// Hapus task (client only, status harus open) — DELETE /tasks/{id}
  Future<ApiResponse> deleteTask(int id) async {
    return _api.delete('/tasks/$id');
  }

  /// Ambil semua task milik client yang sedang login
  /// Filter by status untuk dapat "active tasks" atau "completed"
  /// GET /api/my-tasks  — Hanya task milik client yang login.
  /// Response termasuk accepted_offer + freelancer info.
  Future<ApiResponse> getMyTasks({String? status, String? search}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    return _api.get('/my-tasks', queryParams: params);
  }

  /// GET /api/freelancer/progress
  /// Ambil dashboard progres freelancer: stats + proyek berjalan + aktivitas
  Future<ApiResponse> getFreelancerProgress() async {
    return _api.get('/freelancer/progress');
  }

  /// PUT /api/offers/{offerId}/progress
  /// Update progres, status kerja, dan catatan untuk satu proyek
  Future<ApiResponse> updateOfferProgress({
    required String offerId,
    required int progressPercent,
    required String workStatus,
    String? progressNotes,
  }) async {
    return _api.put(
      '/offers/$offerId/progress',
      body: {
        'progress_percent': progressPercent,
        'work_status': workStatus,
        if (progressNotes != null && progressNotes.isNotEmpty)
          'progress_notes': progressNotes,
      },
    );
  }
}