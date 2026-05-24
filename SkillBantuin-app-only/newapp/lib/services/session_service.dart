import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Session service — wrapper untuk cek/clear session dan onboarding state.
/// Backward compatible dengan screen yang sudah ada (splash, onboarding).
class SessionService {
  final AuthService _auth = AuthService();

  /// Cek apakah ada session tersimpan
  Future<bool> hasSession() async => _auth.hasSession();

  /// Clear session (logout)
  Future<void> clearSession() async {
    await _auth.logout();
  }

  /// Tandai onboarding sudah dilihat
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  /// Cek apakah onboarding sudah pernah dilihat
  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }
}
