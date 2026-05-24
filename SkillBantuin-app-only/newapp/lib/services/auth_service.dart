import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Service autentikasi — menghubungkan Flutter ke Laravel Sanctum auth.
/// Handle register, login, logout, cek session, update profile.
class AuthService {
  final _api = ApiClient();

  // Key untuk menyimpan data user di local storage
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';
  static const _userAvatarKey = 'user_avatar';

  /// Register user baru — POST /register
  /// [role] harus 'client' atau 'freelancer'
  Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? username,
    String? phoneNumber,
  }) async {
    final res = await _api.post('/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role,
      'username': username,
      'phone_number': phoneNumber,
      'terms': true,
    });

    // Jika sukses, simpan token + data user ke local
    if (res.success && res['token'] != null) {
      await _api.saveToken(res['token']);
      await _saveUserLocally(res['user']);
    }
    return res;
  }

  /// Login — POST /login
  /// [identity] bisa email atau username
  Future<ApiResponse> login({
    required String identity,
    required String password,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'identity': identity,
      'password': password,
    };
    if (role != null) body['role'] = role;

    final res = await _api.post('/login', body: body);

    if (res.success && res['token'] != null) {
      await _api.saveToken(res['token']);
      await _saveUserLocally(res['user']);
    }
    return res;
  }

  /// Logout — POST /logout
  /// Hapus token dari server dan local storage
  Future<ApiResponse> logout() async {
    final res = await _api.post('/logout');
    // Selalu clear local data, bahkan jika API gagal (misal offline)
    await _api.clearToken();
    await _clearUserLocally();
    return res;
  }

  /// Ambil data user yang sedang login — GET /user
  /// Berguna untuk refresh data setelah update profile
  Future<ApiResponse> getCurrentUser() async {
    final res = await _api.get('/user');
    if (res.success && res['user'] != null) {
      await _saveUserLocally(res['user']);
    }
    return res;
  }

  /// Update profile — PUT /user
  Future<ApiResponse> updateProfile({
    String? name,
    String? username,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (username != null) body['username'] = username;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;

    final res = await _api.put('/user', body: body);
    if (res.success && res['user'] != null) {
      await _saveUserLocally(res['user']);
    }
    return res;
  }

  /// Update password — PUT /user/password
  Future<ApiResponse> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _api.put('/user/password', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmPassword,
    });
  }

  /// Forgot password — POST /forgot-password
  Future<ApiResponse> forgotPassword(String email) async {
    return _api.post('/forgot-password', body: {'email': email});
  }

  /// Upload avatar — POST /upload
  Future<ApiResponse> uploadAvatar(String filePath) async {
    return _api.uploadFile('/upload', filePath, field: 'file');
  }

  /// Cek apakah ada session tersimpan (untuk auto-login di splash)
  Future<bool> hasSession() async {
    return await _api.isAuthenticated;
  }

  /// Ambil data user dari local storage (tanpa API call)
  Future<Map<String, String?>> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'role': prefs.getString(_userRoleKey),
      'avatar': prefs.getString(_userAvatarKey),
    };
  }

  // ─── Private Helpers ──────────────────────────────────────

  /// Simpan data user ke SharedPreferences untuk akses cepat
  Future<void> _saveUserLocally(Map<String, dynamic>? user) async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user['id'].toString());
    await prefs.setString(_userNameKey, user['name'] ?? '');
    await prefs.setString(_userEmailKey, user['email'] ?? '');
    await prefs.setString(_userRoleKey, user['role'] ?? 'client');
    if (user['avatar'] != null) {
      await prefs.setString(_userAvatarKey, user['avatar']);
    }
  }

  /// Hapus data user dari local storage
  Future<void> _clearUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userAvatarKey);
  }
}

/// Exception untuk auth errors — dilempar saat login/register gagal
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
