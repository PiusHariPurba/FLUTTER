import 'package:flutter/material.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';

/// Filter Screen Freelancer — filter detail pekerjaan.
/// Design: pic 3
class FreelancerFilterScreen extends StatefulWidget {
  const FreelancerFilterScreen({super.key});
  @override
  State<FreelancerFilterScreen> createState() => _FreelancerFilterScreenState();
}

class _FreelancerFilterScreenState extends State<FreelancerFilterScreen> {
  // Tipe Pekerjaan
  final _jobTypes = const ['Magang', 'Full-time', 'Part-time', 'Volunteer'];
  int _activeJobType = 1; // Full-time default

  // Rentang Gaji
  RangeValues _salaryRange = const RangeValues(5000000, 15000000);

  // Mode Kerja
  final Map<String, bool> _workModes = {'Remote': true, 'Hybrid': false, 'On-site': false};
  final _workModeIcons = const [Icons.wifi_rounded, Icons.grid_view_rounded, Icons.location_on_rounded];

  // Tingkat Pengalaman
  final _expLevels = const ['Entry\nLevel', 'Junior', 'Senior'];
  int _activeExp = 1;

  // Batas Waktu
  final _deadlines = const ['Minggu Ini', 'Bulan Ini'];
  int _activeDeadline = 1;

  // Keahlian
  final _searchSkillCtrl = TextEditingController();
  final List<String> _skills = ['UI/UX\nDesign', 'React.js', 'Copywriting'];

  @override
  void dispose() { _searchSkillCtrl.dispose(); super.dispose(); }

  void _reset() {
    setState(() {
      _activeJobType = 1; _salaryRange = const RangeValues(5000000, 15000000);
      _workModes.updateAll((_, __) => false); _workModes['Remote'] = true;
      _activeExp = 1; _activeDeadline = 1;
      _skills.clear(); _skills.addAll(['UI/UX\nDesign', 'React.js', 'Copywriting']);
    });
  }

  String _fmtNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isId = LanguageNotifier.instance.isIndonesian;

    return Scaffold(
      backgroundColor: FPal.bg,
      appBar: AppBar(
        backgroundColor: FPal.bg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: FPal.ink),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FPal.ink)),
        centerTitle: true,
        actions: [TextButton(onPressed: _reset,
            child: const Text('Reset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FPal.inkSoft)))],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFEEECE8))),
      ),

      body: AnimatedPage(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                // ═══ TIPE PEKERJAAN ═══
                const Text('Tipe Pekerjaan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10,
                  children: List.generate(_jobTypes.length, (i) {
                    final isActive = i == _activeJobType;
                    return GestureDetector(
                      onTap: () => setState(() => _activeJobType = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          color: isActive ? FPal.primary : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isActive ? FPal.primary : const Color(0xFFDDE2EE)),
                        ),
                        child: Text(_jobTypes[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : FPal.inkSoft)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // ═══ RENTANG GAJI ═══
                const Text('Rentang Gaji (IDR)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Minimum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FPal.inkMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE2EE))),
                      child: Text('Rp ${_fmtNum(_salaryRange.start.toInt())}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FPal.ink)),
                    ),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Maksimum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FPal.inkMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDE2EE))),
                      child: Text('Rp ${_fmtNum(_salaryRange.end.toInt())}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FPal.ink)),
                    ),
                  ])),
                ]),
                const SizedBox(height: 14),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: FPal.primary, inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: FPal.primary, overlayColor: FPal.primary.withOpacity(0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2), trackHeight: 4,
                  ),
                  child: RangeSlider(values: _salaryRange, min: 0, max: 50000000, divisions: 100,
                      onChanged: (v) => setState(() => _salaryRange = v)),
                ),
                const SizedBox(height: 24),

                // ═══ MODE KERJA ═══
                const Text('Mode Kerja', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 14),
                ...List.generate(3, (i) {
                  final key = _workModes.keys.elementAt(i);
                  final checked = _workModes[key]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _workModes[key] = !checked),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: checked ? FPal.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: checked ? FPal.primary : const Color(0xFFDDE2EE), width: checked ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Icon(_workModeIcons[i], color: checked ? FPal.primary : FPal.inkMuted, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: checked ? FPal.primary : FPal.ink))),
                          // Checkbox
                          Container(width: 24, height: 24,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
                                  color: checked ? FPal.primary : Colors.white,
                                  border: Border.all(color: checked ? FPal.primary : const Color(0xFFCCC8C3), width: 2)),
                              child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null),
                        ]),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // ═══ TINGKAT PENGALAMAN ═══
                const Text('Tingkat Pengalaman', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 14),
                Row(children: List.generate(_expLevels.length, (i) {
                  final isActive = i == _activeExp;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeExp = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? FPal.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? FPal.primary : const Color(0xFFDDE2EE)),
                        ),
                        child: Text(_expLevels[i], textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : FPal.inkSoft)),
                      ),
                    ),
                  ));
                })),
                const SizedBox(height: 24),

                // ═══ BATAS WAKTU ═══
                const Text('Batas Waktu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 14),
                Row(children: List.generate(_deadlines.length, (i) {
                  final isActive = i == _activeDeadline;
                  return Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeDeadline = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? FPal.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? FPal.primary : const Color(0xFFDDE2EE)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.calendar_today_rounded, size: 16,
                              color: isActive ? Colors.white : FPal.inkMuted),
                          const SizedBox(width: 6),
                          Text(_deadlines[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : FPal.inkSoft)),
                        ]),
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 24),

                // ═══ KEAHLIAN ═══
                const Text('Keahlian', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDE2EE))),
                  child: TextField(
                    controller: _searchSkillCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari keahlian (misal: UI/UX)',
                      hintStyle: TextStyle(color: FPal.inkMuted, fontSize: 14, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, color: FPal.inkMuted, size: 20),
                      border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10,
                  children: _skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: FPal.primaryLight, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FPal.primary.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FPal.primary)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _skills.remove(s)),
                        child: const Icon(Icons.close_rounded, color: FPal.primary, size: 16),
                      ),
                    ]),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ═══ TERAPKAN FILTER BUTTON ═══
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(color: FPal.bg,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
            child: SafeArea(top: false,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: FPal.primary, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: FPal.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(isId ? 'Terapkan Filter' : 'Apply Filter',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
