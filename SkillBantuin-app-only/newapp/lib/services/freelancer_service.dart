import 'api_client.dart';
import '../config/app_config.dart';

/// Service freelancer — browse/cari freelancer, lihat profil, update profil.
/// Dipakai oleh Client untuk cari freelancer, dan Freelancer untuk manage profil sendiri.
class FreelancerService {
  final _api = ApiClient();

  /// List freelancer (public) — GET /freelancers
  /// Bisa search by nama/skill, filter by category
  Future<ApiResponse> getFreelancers({
    String? search,
    String? category,
    double? minRating,
    int page = 1,
    int perPage = AppConfig.defaultPerPage,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null) params['search'] = search;
    if (category != null) params['category'] = category;
    if (minRating != null) params['min_rating'] = minRating.toString();
    return _api.get('/freelancers', queryParams: params);
  }

  /// Detail satu freelancer — GET /freelancers/{id}
  /// Termasuk profil, skill, rating, portfolio
  Future<ApiResponse> getFreelancer(int id) async {
    return _api.get('/freelancers/$id');
  }

  /// Reviews untuk freelancer — GET /freelancers/{id}/reviews
  Future<ApiResponse> getReviews(int freelancerId, {int page = 1}) async {
    return _api.get('/freelancers/$freelancerId/reviews', queryParams: {
      'page': page.toString(),
    });
  }

  /// Update profil freelancer sendiri — PUT /freelancers/profile
  /// Hanya bisa diakses oleh user dengan role 'freelancer'
  Future<ApiResponse> updateProfile({
    String? bio,
    List<String>? skills,
    double? hourlyRate,
    String? portfolio,
    String? experience,
  }) async {
    final body = <String, dynamic>{};
    if (bio != null) body['bio'] = bio;
    if (skills != null) body['skills'] = skills;
    if (hourlyRate != null) body['hourly_rate'] = hourlyRate;
    if (portfolio != null) body['portfolio'] = portfolio;
    if (experience != null) body['experience'] = experience;
    return _api.put('/freelancers/profile', body: body);
  }
}
