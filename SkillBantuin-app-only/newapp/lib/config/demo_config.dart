/// Konfigurasi akun demo untuk testing chat antar role.
///
/// Buat akun ini di server dengan:
///   php artisan db:seed --class=DemoUsersSeeder
///
/// Atau register manual dengan kredensial berikut.
class DemoConfig {
  // ── Akun Demo Client ─────────────────────────────────────────────
  static const String clientEmail    = 'client@demo.com';
  static const String clientPassword = 'demo12345';
  static const String clientName     = 'Demo Client';

  // ── Akun Demo Freelancer ─────────────────────────────────────────
  static const String freelancerEmail    = 'freelancer@demo.com';
  static const String freelancerPassword = 'demo12345';
  static const String freelancerName     = 'Demo Freelancer';

  // ── ID freelancer demo (setelah seeder, biasanya ID kecil) ───────
  // Update nilai ini sesuai ID dari hasil `php artisan db:seed`
  static const int demoFreelancerUserId = 2;
  static const int demoClientUserId     = 1;
}
