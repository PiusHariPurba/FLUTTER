import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/notification_screen.dart';
import '../shared/help_screen.dart';
import '../shared/about_screen.dart';
import '../login_screen.dart';
import '../../models/user_role.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});
  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    LanguageNotifier.instance.addListener(_r);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_r);
    super.dispose();
  }

  void _r() => setState(() {});

  // ── Logout ─────────────────────────────────────────────────────────
  void _confirmLogout() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutSheet(onConfirm: _doLogout),
    );
  }

  Future<void> _doLogout() async {
    Navigator.pop(context); // close sheet
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(selectedRole: UserRole.client)),
      (route) => false,
    );
  }

  void _goEdit() async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (result == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isId = LanguageNotifier.instance.isIndonesian;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: FPal.bg,
      body: SafeArea(
        child: AnimatedPage(
          child: Column(children: [
            // ── App Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                const Icon(Icons.menu_rounded, color: FPal.ink, size: 24),
                const SizedBox(width: 14),
                const Text('SkillBantuin', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: FPal.ink, letterSpacing: -0.3)),
                const Spacer(),
                _TopAvatar(name: user?.fullName ?? 'U', url: user?.avatar),
              ]),
            ),
            const SizedBox(height: 12),
            Container(height: 2, color: FPal.primaryLight),

            // ── Content ─────────────────────────────────────────────
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                // Profile card
                BounceIn(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      // Avatar ring
                      Stack(alignment: Alignment.center, children: [
                        // ✅ FIXED: padding dipindah ke Container, bukan di BoxDecoration
                        Container(
                          width: 96, height: 96,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1A6B55), Color(0xFF6EE7B7)]),
                          ),
                        ),
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: FPal.primaryLight,
                            border: Border.all(color: Colors.white, width: 3)),
                          child: Center(
                            child: Text(
                              (user?.fullName.isNotEmpty == true)
                                  ? user!.fullName[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                fontSize: 34, fontWeight: FontWeight.w900,
                                color: FPal.primary))),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: FPal.primary, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5)),
                            child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 15))),
                      ]),
                      const SizedBox(height: 14),
                      // Name
                      Text(user?.fullName ?? 'Client', style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: FPal.ink)),
                      const SizedBox(height: 3),
                      // Username + email
                      if (user?.username.isNotEmpty == true)
                        Text('@${user!.username}', style: const TextStyle(
                          fontSize: 13, color: FPal.inkMuted)),
                      Text(user?.email ?? '', style: const TextStyle(
                        fontSize: 12, color: FPal.inkMuted)),
                      const SizedBox(height: 4),
                      // Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: FPal.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Premium Client', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: FPal.primary))),
                      const SizedBox(height: 18),
                      // Edit Profile btn
                      GestureDetector(
                        onTap: _goEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                          decoration: BoxDecoration(
                            color: FPal.primary, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(
                              color: FPal.primary.withOpacity(0.3),
                              blurRadius: 8, offset: const Offset(0, 3))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(isId ? 'Edit Profil' : 'Edit Profile',
                              style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),

                // Stats
                FadeScaleIn(
                  delay: const Duration(milliseconds: 150),
                  child: Builder(builder: (ctx) {
                    final tasks = ctx.watch<TaskProvider>().tasks;
                    final total    = tasks.length.toString();
                    final ongoing  = tasks.where((t) => t['status'] == 'in_progress').length.toString();
                    return Row(children: [
                      _StatCard(total.isEmpty || total == '0' ? '0' : total,
                        isId ? 'Total\nProyek' : 'Total\nProjects'),
                      const SizedBox(width: 10),
                      _StatCard(ongoing, isId ? 'Sedang\nBerjalan' : 'Ongoing'),
                      const SizedBox(width: 10),
                      _StatCard('–', isId ? 'Review\nDiberikan' : 'Reviews\nGiven'),
                    ]);
                  }),
                ),
                const SizedBox(height: 24),

                // Account section
                _SectionLabel('Account'),
                const SizedBox(height: 10),
                _Group(children: [
                  _Tile(
                    icon: Icons.person_outline_rounded,
                    title: isId ? 'Informasi Pribadi' : 'Personal Information',
                    onTap: _goEdit,
                  ),
                ]),
                const SizedBox(height: 20),

                // General section
                _SectionLabel('General'),
                const SizedBox(height: 10),
                _Group(children: [
                  _Tile(
                    icon: Icons.notifications_outlined,
                    title: isId ? 'Notifikasi' : 'Notifications',
                    onTap: () => Navigator.push(context,
                      slideRightRoute(const NotificationScreen())),
                  ),
                  Container(height: 1, color: const Color(0xFFF0EDE8)),
                  _Tile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                      activeColor: FPal.primary,
                      inactiveTrackColor: const Color(0xFFDDE2EE),
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFF0EDE8)),
                  _Tile(
                    icon: Icons.language_rounded,
                    title: isId ? 'Language / Bahasa' : 'Language / Bahasa',
                    trailing: _LangToggle(),
                  ),
                ]),
                const SizedBox(height: 20),

                // Support
                _SectionLabel('Support'),
                const SizedBox(height: 10),
                _Group(children: [
                  _Tile(
                    icon: Icons.help_outline_rounded,
                    title: isId ? 'Pusat Bantuan' : 'Help Center',
                    onTap: () => Navigator.push(context,
                      slideRightRoute(const HelpScreen())),
                  ),
                  Container(height: 1, color: const Color(0xFFF0EDE8)),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: isId ? 'Tentang Aplikasi' : 'About App',
                    onTap: () => Navigator.push(context,
                      slideRightRoute(const AboutScreen())),
                  ),
                ]),
                const SizedBox(height: 28),

                // Logout
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FPal.danger.withOpacity(0.2))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, color: FPal.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: FPal.danger)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Center(child: Text(
                  'SkillBantuin v1.0.24 • Made with Trust',
                  style: const TextStyle(fontSize: 12, color: FPal.inkMuted))),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

// ── Logout Sheet ───────────────────────────────────────────────────────────────

class _LogoutSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 20, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: FPal.dangerLight, shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, color: FPal.danger, size: 26)),
        const SizedBox(height: 14),
        const Text('Keluar dari Akun?', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: FPal.ink)),
        const SizedBox(height: 8),
        const Text(
          'Kamu akan keluar dari akun ini.\nSemua data lokal akan dihapus.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: FPal.inkMuted, height: 1.4)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: FPal.bgMuted, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Batal', style: TextStyle(
                fontWeight: FontWeight.w700, color: FPal.inkSoft, fontSize: 14)))),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: FPal.danger, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: FPal.danger.withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3))]),
              child: const Center(child: Text('Ya, Keluar', style: TextStyle(
                fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)))),
          )),
        ]),
      ]),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopAvatar extends StatelessWidget {
  final String name;
  final String? url;
  const _TopAvatar({required this.name, this.url});
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: FPal.primaryLight,
      border: Border.all(color: FPal.primary, width: 2)),
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'U',
      style: const TextStyle(
        color: FPal.primary, fontWeight: FontWeight.w800, fontSize: 16))));
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E5E0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Text(value, style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w900, color: FPal.primary)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: FPal.inkMuted, height: 1.3)),
      ]),
    ));
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, color: FPal.primary));
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: children));
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _Tile({required this.icon, required this.title, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: FPal.inkSoft, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: FPal.ink))),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: FPal.inkMuted, size: 22),
      ]),
    ));
}

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isId = LanguageNotifier.instance.isIndonesian;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => LanguageNotifier.instance.setLanguage('id'),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isId ? FPal.primaryLight : FPal.bgMuted,
            border: Border.all(
              color: isId ? FPal.primary : const Color(0xFFDDE2EE),
              width: isId ? 2 : 1)),
          child: const Center(child: Text('🇮🇩', style: TextStyle(fontSize: 16))))),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => LanguageNotifier.instance.setLanguage('en'),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !isId ? FPal.primaryLight : FPal.bgMuted,
            border: Border.all(
              color: !isId ? FPal.primary : const Color(0xFFDDE2EE),
              width: !isId ? 2 : 1)),
          child: const Center(child: Text('🇺🇸', style: TextStyle(fontSize: 16))))),
    ]);
  }
}