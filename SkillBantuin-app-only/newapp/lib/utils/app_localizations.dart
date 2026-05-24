import 'language_notifier.dart';

/// Comprehensive translations for the SkillBantuin app.
/// Covers both Client and Freelancer roles in Indonesian (id) and English (en).
class AppL {
  AppL._();

  /// Shorthand: get translation for [key] using current language.
  static String tr(String key) {
    final lang = LanguageNotifier.instance.value;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'id': {
      // ── App General ──────────────────────────────────────
      'app_name': 'SkillBantuin',
      'logout': 'Keluar',
      'logout_confirm': 'Yakin ingin keluar?',
      'cancel': 'Batal',
      'save': 'Simpan',
      'edit': 'Ubah',
      'back': 'Kembali',
      'search': 'Cari',
      'filter': 'Filter',
      'loading': 'Memuat...',
      'verified': 'Terverifikasi',
      'enabled': 'Aktif',
      'active': 'Aktif',
      'done': 'Selesai',
      'on_time': 'Tepat Waktu',
      'send': 'Kirim',
      'view_all': 'Lihat Semua',
      'manage': 'Kelola',
      'select_language': 'Pilih Bahasa',
      'language': 'Bahasa',
      'language_id': 'Indonesia',
      'language_en': 'Inggris',
      'language_changed': 'Bahasa berhasil diubah',

      // ── Bottom Navigation ─────────────────────────────────
      'nav_labor': 'Kerja',
      'nav_chat': 'Chat',
      'nav_progress': 'Progres',
      'nav_profile': 'Profil',
      'nav_feed': 'Lowongan',
      'nav_history': 'Riwayat',

      // ── Profile (Shared) ──────────────────────────────────
      'profile': 'Profil',
      'share_profile': 'Bagikan Profil',
      'export_cv': 'Ekspor CV',
      'settings': 'Pengaturan',
      'notifications': 'Notifikasi',
      'security': 'Keamanan',
      'email': 'Email',
      'phone': 'Telepon',
      '2fa_active': '2FA Aktif',

      // ── Freelancer Profile ────────────────────────────────
      'active_hours': 'JAM AKTIF',
      'reliability': 'KEANDALAN',
      'core_expertise': 'Keahlian Utama',
      'completed_jobs': 'Pekerjaan Selesai',
      'last_12_months': '12 Bulan Terakhir',
      'reviews': 'ulasan',
      'structural_steel': 'Baja Struktural',
      'bim_coordination': 'Koordinasi BIM',
      'osha_30': 'OSHA 30',
      'team_leadership': 'Kepemimpinan Tim',
      'site_reporting': 'Laporan Lapangan',
      'lead_site_supervisor': 'Pengawas Lapangan Utama',
      'structural_foreman': 'Mandor Struktural',
      'months': 'Bulan',
      'senior_site_supervisor': 'PENGAWAS LAPANGAN SENIOR',

      // ── Client Profile ────────────────────────────────────
      'company_details': 'Detail Perusahaan',
      'payment_methods': 'Metode Pembayaran',
      'industry': 'Industri',
      'location': 'Lokasi',
      'joined': 'Bergabung',
      'total_projects': 'Total Proyek',
      'projects': 'Proyek',
      'card': 'Kartu',
      'bank': 'Bank',

      // ── Home Screens ──────────────────────────────────────
      'labor_management': 'MANAJEMEN TENAGA KERJA',
      'labor_management_title': 'Manajemen Kerja',
      'job_feed': 'Lowongan Kerja',
      'search_placeholder': 'Cari lowongan...',
      'available_tasks': 'Tersedia',
      'my_works': 'Pekerjaan Saya',
      'quick_actions': 'Aksi Cepat',
      'find_work': 'Cari Kerja',
      'my_earnings': 'Pendapatan',
      'todays_summary': 'Ringkasan Hari Ini',
      'active_projects': 'Proyek Aktif',
      'pending_review': 'Menunggu Review',
      'total_earned': 'Total Pendapatan',
      'greeting_morning': 'Selamat Pagi',
      'greeting_afternoon': 'Selamat Siang',
      'greeting_evening': 'Selamat Malam',
      'see_all': 'Lihat Semua',
      'nearby_jobs': 'Pekerjaan Terdekat',
      'recommended': 'Rekomendasi',
      'task_detail': 'Detail Tugas',
      'apply_now': 'Lamar Sekarang',
      'job_posted': 'Dibuka',

      // ── Chat ─────────────────────────────────────────────
      'chat': 'Chat',
      'messages': 'Pesan',
      'type_message': 'Ketik pesan...',
      'no_messages': 'Belum ada pesan',

      // ── Projects / History ────────────────────────────────
      'projects_title': 'Proyek',
      'history': 'Riwayat',
      'in_progress': 'Sedang Berjalan',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
      'pending': 'Menunggu',
      'deadline': 'Tenggat',
      'budget': 'Anggaran',
      'status': 'Status',
      'no_projects': 'Tidak ada proyek',

      // ── Offers ───────────────────────────────────────────
      'offers': 'Penawaran',
      'offer_sent': 'Penawaran Terkirim',
      'offer_received': 'Penawaran Diterima',
      'accept': 'Terima',
      'reject': 'Tolak',
      'negotiate': 'Negosiasi',

      // ── Earnings ─────────────────────────────────────────
      'earnings': 'Pendapatan',
      'total_earnings': 'Total Pendapatan',
      'this_month': 'Bulan Ini',
      'last_month': 'Bulan Lalu',
      'withdraw': 'Tarik Dana',
      'payment_history': 'Riwayat Pembayaran',

      // ── Auth ─────────────────────────────────────────────
      'login': 'Masuk',
      'register': 'Daftar',
      'password': 'Kata Sandi',
      'forgot_password': 'Lupa Kata Sandi?',
      'name': 'Nama',
      'full_name': 'Nama Lengkap',
      'role_selection': 'Pilih Peran',
      'i_am_freelancer': 'Saya Pekerja Lepas',
      'i_am_client': 'Saya Pemberi Kerja',

      // ── Splash / Onboarding ───────────────────────────────
      'onboarding_1_title': 'Temukan Tenaga Ahli',
      'onboarding_1_desc': 'Hubungkan proyek Anda dengan tenaga lapangan berpengalaman.',
      'onboarding_2_title': 'Kerja Lebih Mudah',
      'onboarding_2_desc': 'Kelola tugas, jadwal, dan pembayaran dalam satu aplikasi.',
      'onboarding_3_title': 'Pembayaran Aman',
      'onboarding_3_desc': 'Dana terjamin hingga pekerjaan selesai dan diverifikasi.',
      'get_started': 'Mulai Sekarang',
      'skip': 'Lewati',
      'next': 'Selanjutnya',
    },

    'en': {
      // ── App General ──────────────────────────────────────
      'app_name': 'SkillBantuin',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'back': 'Back',
      'search': 'Search',
      'filter': 'Filter',
      'loading': 'Loading...',
      'verified': 'Verified',
      'enabled': 'Enabled',
      'active': 'Active',
      'done': 'Done',
      'on_time': 'On-Time',
      'send': 'Send',
      'view_all': 'View All',
      'manage': 'Manage',
      'select_language': 'Select Language',
      'language': 'Language',
      'language_id': 'Indonesian',
      'language_en': 'English',
      'language_changed': 'Language updated successfully',

      // ── Bottom Navigation ─────────────────────────────────
      'nav_labor': 'Labor',
      'nav_chat': 'Chat',
      'nav_progress': 'Progress',
      'nav_profile': 'Profile',
      'nav_feed': 'Feed',
      'nav_history': 'History',

      // ── Profile (Shared) ──────────────────────────────────
      'profile': 'Profile',
      'share_profile': 'Share Profile',
      'export_cv': 'Export CV',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'security': 'Security',
      'email': 'Email',
      'phone': 'Phone',
      '2fa_active': '2FA Active',

      // ── Freelancer Profile ────────────────────────────────
      'active_hours': 'ACTIVE HOURS',
      'reliability': 'RELIABILITY',
      'core_expertise': 'Core Expertise',
      'completed_jobs': 'Completed Jobs',
      'last_12_months': 'Last 12 Months',
      'reviews': 'reviews',
      'structural_steel': 'Structural Steel',
      'bim_coordination': 'BIM Coordination',
      'osha_30': 'OSHA 30',
      'team_leadership': 'Team Leadership',
      'site_reporting': 'Site Reporting',
      'lead_site_supervisor': 'Lead Site Supervisor',
      'structural_foreman': 'Structural Foreman',
      'months': 'Months',
      'senior_site_supervisor': 'SENIOR SITE SUPERVISOR',

      // ── Client Profile ────────────────────────────────────
      'company_details': 'Company Details',
      'payment_methods': 'Payment Methods',
      'industry': 'Industry',
      'location': 'Location',
      'joined': 'Joined',
      'total_projects': 'Total Projects',
      'projects': 'Projects',
      'card': 'Card',
      'bank': 'Bank',

      // ── Home Screens ──────────────────────────────────────
      'labor_management': 'LABOR MANAGEMENT',
      'labor_management_title': 'Labor Management',
      'job_feed': 'Job Feed',
      'search_placeholder': 'Search jobs...',
      'available_tasks': 'Available',
      'my_works': 'My Works',
      'quick_actions': 'Quick Actions',
      'find_work': 'Find Work',
      'my_earnings': 'My Earnings',
      'todays_summary': "Today's Summary",
      'active_projects': 'Active Projects',
      'pending_review': 'Pending Review',
      'total_earned': 'Total Earned',
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'see_all': 'See All',
      'nearby_jobs': 'Nearby Jobs',
      'recommended': 'Recommended',
      'task_detail': 'Task Detail',
      'apply_now': 'Apply Now',
      'job_posted': 'Posted',

      // ── Chat ─────────────────────────────────────────────
      'chat': 'Chat',
      'messages': 'Messages',
      'type_message': 'Type a message...',
      'no_messages': 'No messages yet',

      // ── Projects / History ────────────────────────────────
      'projects_title': 'Projects',
      'history': 'History',
      'in_progress': 'In Progress',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'pending': 'Pending',
      'deadline': 'Deadline',
      'budget': 'Budget',
      'status': 'Status',
      'no_projects': 'No projects yet',

      // ── Offers ───────────────────────────────────────────
      'offers': 'Offers',
      'offer_sent': 'Offer Sent',
      'offer_received': 'Offer Received',
      'accept': 'Accept',
      'reject': 'Reject',
      'negotiate': 'Negotiate',

      // ── Earnings ─────────────────────────────────────────
      'earnings': 'Earnings',
      'total_earnings': 'Total Earnings',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'withdraw': 'Withdraw',
      'payment_history': 'Payment History',

      // ── Auth ─────────────────────────────────────────────
      'login': 'Login',
      'register': 'Register',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'name': 'Name',
      'full_name': 'Full Name',
      'role_selection': 'Select Role',
      'i_am_freelancer': "I'm a Freelancer",
      'i_am_client': "I'm a Client",

      // ── Splash / Onboarding ───────────────────────────────
      'onboarding_1_title': 'Find Expert Workforce',
      'onboarding_1_desc': 'Connect your project with experienced field workers.',
      'onboarding_2_title': 'Work Smarter',
      'onboarding_2_desc': 'Manage tasks, schedules, and payments in one app.',
      'onboarding_3_title': 'Secure Payments',
      'onboarding_3_desc': 'Funds are held safely until the work is done and verified.',
      'get_started': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
    },
  };
}
