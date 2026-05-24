import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task_models.dart';
import '../../services/task_service.dart';
import '../../widgets/app_theme.dart';

/// Edit Task Screen — desain Image 2
/// Freelancer update progres, status, dan catatan. Koneksi ke PUT /api/offers/{id}/progress
class EditTaskScreen extends StatefulWidget {
  final FreelancerWorkItem workItem;

  const EditTaskScreen({super.key, required this.workItem});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _svc = TaskService();

  late int _percent;
  late String _selectedStatus;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  // Opsi status — key harus cocok dengan enum di Laravel
  static const _statusOptions = [
    {'key': 'on_track',    'label': 'On Track'},
    {'key': 'in_progress', 'label': 'In Progress'},
    {'key': 'revision',    'label': 'Revision'},
    {'key': 'completed',   'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _percent        = widget.workItem.progress.clamp(0, 100);
    _selectedStatus = widget.workItem.workStatus;
    _notesCtrl      = TextEditingController(
        text: widget.workItem.progressNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Simpan ke API ────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final res = await _svc.updateOfferProgress(
      offerId:        widget.workItem.id,
      progressPercent: _percent,
      workStatus:     _selectedStatus,
      progressNotes:  _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Progres berhasil disimpan!'),
          backgroundColor: FPal.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true); // true = ada perubahan, trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Gagal menyimpan.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: FPal.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FPal.ink),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Edit Task',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: FPal.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FPal.primary),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: FPal.primary, size: 26),
              onPressed: _save,
            ),
        ],
      ),
      // ── Body ──────────────────────────────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectCard(),
                  const SizedBox(height: 14),
                  _buildCompletionCard(),
                  const SizedBox(height: 14),
                  _buildStatusCard(),
                  const SizedBox(height: 14),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ─── Kartu info proyek ────────────────────────────────────────────────────
  Widget _buildProjectCard() {
    final item = widget.workItem;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon proyek
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: FPal.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.design_services_rounded,
                color: FPal.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.taskTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: FPal.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: FPal.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Client: ${item.clientName}',
                      style: const TextStyle(
                          fontSize: 13, color: FPal.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Badge "DUE IN X DAYS" / deadline
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FPal.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: FPal.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.deadlineLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FPal.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kartu Completion Progress ────────────────────────────────────────────
  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + input angka + %
          Row(
            children: [
              const Text(
                'COMPLETION PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FPal.inkMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const Spacer(),
              // Input angka
              Container(
                width: 58,
                height: 36,
                decoration: BoxDecoration(
                  color: FPal.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Center(
                  child: TextField(
                    key: ValueKey(_percent),
                    controller: TextEditingController(
                        text: _percent.toString()),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _PercentFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FPal.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v);
                      if (val != null) {
                        setState(() => _percent = val.clamp(0, 100));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FPal.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: FPal.primary,
              inactiveTrackColor: const Color(0xFFD1E8DF),
              thumbColor: FPal.primary,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 13),
              overlayColor: FPal.primary.withOpacity(0.15),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
              trackHeight: 6,
            ),
            child: Slider(
              value: _percent.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => setState(() => _percent = v.round()),
            ),
          ),
          // Label 0% — 50% — 100%
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0%', style: TextStyle(fontSize: 12, color: FPal.inkMuted)),
                Text('50%', style: TextStyle(fontSize: 12, color: FPal.inkMuted)),
                Text('100%', style: TextStyle(fontSize: 12, color: FPal.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kartu Current Status ─────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: FPal.inkMuted,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 14),
          // Grid 2×2
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _statusOptions.length,
            itemBuilder: (_, i) {
              final opt      = _statusOptions[i];
              final selected = _selectedStatus == opt['key'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedStatus = opt['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected ? FPal.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? FPal.primary
                          : const Color(0xFFDDDDDD),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected ? FPal.primary : FPal.inkSoft,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Kartu Update Notes ───────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'UPDATE NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FPal.inkMuted,
                  letterSpacing: 0.9,
                ),
              ),
              Spacer(),
              Text(
                'Visible to client',
                style: TextStyle(fontSize: 12, color: FPal.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: FPal.ink),
            decoration: InputDecoration(
              hintText:
                  'Briefly describe what you accomplished in this update...',
              hintStyle:
                  const TextStyle(fontSize: 14, color: FPal.inkMuted),
              filled: true,
              fillColor: FPal.bg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE0DDD8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE0DDD8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: FPal.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tombol Save Progress (sticky bawah) ──────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      color: FPal.bg,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: FPal.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: FPal.primary.withOpacity(0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Text(
                  'Save Progress',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// ─── Formatter: batasi input 0–100 ───────────────────────────────────────────
class _PercentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue neo) {
    if (neo.text.isEmpty) return neo;
    final val = int.tryParse(neo.text);
    if (val == null || val > 100) return old;
    return neo;
  }
}
