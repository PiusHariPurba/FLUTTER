import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _open;

  static const _faqs = [
    ('Bagaimana cara membuat proyek?', 'Masuk ke akun Client, klik tombol "+" di halaman Progress, isi detail proyek, lalu klik "Buat Proyek". Freelancer akan melamar proyek kamu.'),
    ('Bagaimana cara melamar proyek?', 'Buka halaman Cari Proyek, gunakan filter atau search untuk menemukan proyek yang cocok, klik "Lamar", lalu isi penawaran harga dan pesan kamu.'),
    ('Apakah ada jaminan pembayaran?', 'Ya. SkillBantuin menggunakan sistem escrow — dana dari client ditahan terlebih dahulu dan baru dicairkan setelah pekerjaan selesai dan disetujui.'),
    ('Bagaimana cara chat dengan freelancer?', 'Setelah proses hire selesai, chat room otomatis terbuka. Kamu bisa akses semua percakapan dari menu Chat di bottom navigation.'),
    ('Bagaimana cara mengubah password?', 'Buka Profile → Informasi Pribadi → scroll ke bawah → klik "Ganti Password". Isi password lama dan password baru.'),
    ('Apa yang terjadi jika ada sengketa?', 'Hubungi tim support SkillBantuin via email di support@skillbantuin.com. Tim mediasi kami akan membantu menyelesaikan masalah dalam 2x24 jam.'),
    ('Berapa komisi SkillBantuin?', 'SkillBantuin mengambil komisi 5% dari nilai proyek untuk freelancer dan 0% untuk client. Komisi digunakan untuk menjaga keamanan platform.'),
    ('Bagaimana cara menarik dana?', 'Masuk ke Penghasilan → Tarik Dana → masukkan nomor rekening dan jumlah. Dana masuk 1-3 hari kerja.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FPal.bg,
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
        onPressed: () => Navigator.pop(context)),
      title: const Text('Pusat Bantuan', style: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFEEECE8))),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2B1E), Color(0xFF1A6B55)]),
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ada yang bisa kami bantu?', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 3),
                Text('support@skillbantuin.com', style: TextStyle(
                  fontSize: 12.5, color: Colors.white70)),
              ])),
          ])),
        const SizedBox(height: 24),
        const Text('FAQ — Pertanyaan Umum', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: FPal.ink)),
        const SizedBox(height: 12),
        ...List.generate(_faqs.length, (i) {
          final isOpen = _open == i;
          return StaggerItem(
            index: i, fromY: 10,
            child: GestureDetector(
              onTap: () => setState(() => _open = isOpen ? null : i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOpen ? FPal.primary.withOpacity(0.3) : const Color(0xFFEEECE8)),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(isOpen ? 0.06 : 0.03),
                    blurRadius: isOpen ? 10 : 4, offset: const Offset(0, 2))]),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(child: Text(_faqs[i].$1, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isOpen ? FPal.primary : FPal.ink))),
                      AnimatedRotation(
                        turns: isOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: isOpen ? FPal.primary : FPal.inkMuted)),
                    ])),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Text(_faqs[i].$2, style: const TextStyle(
                        fontSize: 13, color: FPal.inkSoft, height: 1.5))),
                    crossFadeState: isOpen
                      ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200)),
                ]),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
