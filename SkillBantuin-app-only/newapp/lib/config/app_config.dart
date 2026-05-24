// ─────────────────────────────────────────────────────────────────────────────
//  app_config.dart — Konfigurasi aplikasi SkillBantuin
//
//  SECURITY: Tidak ada IP/URL yang di-hardcode di sini.
//  Semua URL dikonfigurasi via --dart-define saat build:
//
//  Dev (emulator Android):
//    flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
//
//  Dev (device fisik, sesuaikan IP):
//    flutter run --dart-define=API_URL=http://192.168.1.x:8000/api
//
//  Dev (Chrome / Web):
//    flutter run -d chrome --dart-define=API_URL=http://localhost:8000/api
//
//  Production build:
//    flutter build apk --dart-define=API_URL=https://api.skillbantuin.com/api
//    flutter build web --dart-define=API_URL=https://api.skillbantuin.com/api
//
//  Atau via VS Code launch.json:
//    "args": ["--dart-define=API_URL=http://10.0.2.2:8000/api"]
//
//  CATATAN: Nilai --dart-define di-compile ke binary, tidak sebagai plaintext
//  seperti hardcode, dan tidak bisa diubah tanpa rebuild. Untuk secret yang
//  benar-benar sensitif (API key pihak ketiga), gunakan backend proxy.
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  // ── API Base URL ──────────────────────────────────────────────────────────
  // Dikonfigurasi via --dart-define=API_URL=... saat build/run.
  // Default fallback hanya untuk dev — TIDAK untuk production.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api', // Emulator Android default
  );

  // ── Deteksi environment ───────────────────────────────────────────────────
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction  => _appEnv == 'production';
  static bool get isDevelopment => _appEnv == 'development';
  static bool get isStaging     => _appEnv == 'staging';

  // ── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Polling Interval ─────────────────────────────────────────────────────
  // Di production lebih hemat baterai; dev lebih responsif
  static Duration get chatPollInterval =>
      isProduction ? const Duration(seconds: 8) : const Duration(seconds: 4);

  static Duration get taskPollInterval =>
      isProduction ? const Duration(seconds: 30) : const Duration(seconds: 15);

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPerPage       = 15;
  static const int chatMessagesPerPage  = 30;

  // ── Version ───────────────────────────────────────────────────────────────
  static const String appVersion = '1.0.24';
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER', defaultValue: '1');

  // ── Debug helpers ─────────────────────────────────────────────────────────
  /// Cetak config aktif saat app start (hanya di dev mode)
  static void printConfig() {
    if (isDevelopment) {
      // ignore: avoid_print
      print('''
╔══════════════════════════════════════╗
║  SkillBantuin Config (DEV)           ║
║  API URL  : $baseUrl
║  Env      : $_appEnv                 ║
║  Version  : $appVersion+$buildNumber ║
╚══════════════════════════════════════╝''');
    }
  }
}
