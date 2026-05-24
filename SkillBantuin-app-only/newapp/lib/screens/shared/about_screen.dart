import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FPal.bg,
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
        onPressed: () => Navigator.pop(context)),
      title: const Text('Tentang Aplikasi', style: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFEEECE8))),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        BounceIn(child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A6B55), Color(0xFF2D9470)]),
            boxShadow: [BoxShadow(
              color: FPal.primary.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 6))]),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 48))),
        const SizedBox(height: 16),
        const Text('SkillBantuin', style: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w900, color: FPal.ink)),
        const SizedBox(height: 4),
        Text('Versi ${AppConfig.appVersion}', style: const TextStyle(
          fontSize: 14, color: FPal.inkMuted)),
        const SizedBox(height: 28),
        ...[
          ('🎯', 'Misi', 'Menghubungkan para profesional berbakat dengan klien yang membutuhkan keahlian mereka secara efisien dan terpercaya.'),
          ('👁️', 'Visi', 'Menjadi platform freelance #1 di Indonesia yang memberdayakan jutaan profesional digital.'),
          ('🔒', 'Keamanan', 'Data kamu dilindungi dengan enkripsi end-to-end. Pembayaran aman melalui escrow system.'),
          ('⚡', 'Teknologi', 'Dibangun dengan Flutter & Laravel 12, didukung algoritma AI untuk rekomendasi cerdas.'),
        ].map((e) => StaggerItem(
          index: [('🎯','Misi',''),('👁️','Visi',''),('🔒','Keamanan',''),('⚡','Teknologi','')].indexOf(e),
          fromY: 16,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$2, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 4),
                Text(e.$3, style: const TextStyle(
                  fontSize: 13, color: FPal.inkSoft, height: 1.4)),
              ])),
            ]),
          ))).toList(),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFEEECE8)),
        const SizedBox(height: 16),
        const Text('Dibuat dengan ❤️ di Indonesia',
          style: TextStyle(fontSize: 13, color: FPal.inkMuted)),
        Text('© 2024 SkillBantuin. All rights reserved.',
          style: const TextStyle(fontSize: 12, color: FPal.inkMuted)),
      ]),
    ),
  );
}
