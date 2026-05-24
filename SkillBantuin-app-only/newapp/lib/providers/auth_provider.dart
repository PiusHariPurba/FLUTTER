import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';

/// Status autentikasi
enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Provider autentikasi — mengelola state login/logout.
/// Menghubungkan UI ke AuthService (Laravel Sanctum API).
/// Saat login berhasil, otomatis start realtime polling.
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final RealtimeService _realtime = RealtimeService();

  AppUser? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _error;

  // Getters
  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  UserRole? get role => _user?.role;

  /// Init — coba restore session dari token yang tersimpan
  /// Dipanggil di splash screen
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Cek apakah ada token tersimpan
      final hasSession = await _auth.hasSession();
      if (hasSession) {
        // Validasi token dengan fetch user dari server
        final res = await _auth.getCurrentUser();
        if (res.success && res['user'] != null) {
          _user = AppUser.fromJson(res['user']);
          _status = AuthStatus.authenticated;
          _realtime.startPolling(); // Mulai polling saat authenticated
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('[AuthProvider] Init error: $e');
    }
    notifyListeners();
  }

  /// Login — kirim credentials ke server, simpan token
  Future<bool> login({
    required String identity,
    required String password,
    String? role,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final res = await _auth.login(
      identity: identity,
      password: password,
      role: role,
    );

    if (res.success && res['user'] != null) {
      _user = AppUser.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _realtime.startPolling(); // Start polling setelah login
      notifyListeners();
      return true;
    } else {
      _error = res.message ?? 'Login gagal.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Register — buat akun baru di server
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? username,
    String? phoneNumber,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final res = await _auth.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
      username: username,
      phoneNumber: phoneNumber,
    );

    if (res.success && res['user'] != null) {
      _user = AppUser.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _realtime.startPolling();
      notifyListeners();
      return true;
    } else {
      _error = res.message ?? 'Registrasi gagal.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logout — hapus token dari server dan local
  Future<void> logout() async {
    _realtime.stopPolling(); // Stop polling sebelum logout
    await _auth.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  /// Update profile
  Future<bool> updateProfile({String? name, String? username, String? phone}) async {
    final res = await _auth.updateProfile(
      name: name, username: username, phoneNumber: phone);
    if (res.success && res['user'] != null) {
      _user = AppUser.fromJson(res['user']);
      notifyListeners();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Refresh user data dari server (dipakai setelah avatar upload).
  Future<void> refreshUser() async {
    try {
      final res = await _auth.getCurrentUser();
      if (res.success && res['user'] != null) {
        _user = AppUser.fromJson(res['user']);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
