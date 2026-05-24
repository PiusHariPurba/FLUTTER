// ─────────────────────────────────────────────────────────────────────────────
//  hire_freelancer_screen.dart  —  Alur Hire Lengkap untuk Client
//  Flow: Preview Freelancer → Isi Detail Proyek → Konfirmasi → Buka Chat
//  API: POST /tasks → POST /chats
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../services/task_service.dart';
import '../../services/chat_service.dart';
import '../../models/chat_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';
import '../shared/chat_room_screen.dart';

// ── Data model freelancer yang di-hire ────────────────────────────────────────
class FreelancerHireData {
  final String id;
  final String name;
  final String skill;
  final double rating;
  final int baseRate;
  final String? avatar;
  final String responseTime;

  const FreelancerHireData({
    required this.id,
    required this.name,
    required this.skill,
    required this.rating,
    required this.baseRate,
    this.avatar,
    this.responseTime = '< 1 jam',
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class HireFreelancerScreen extends StatefulWidget {
  final FreelancerHireData freelancer;

  const HireFreelancerScreen({super.key, required this.freelancer});

  @override
  State<HireFreelancerScreen> createState() => _HireFreelancerScreenState();
}

class _HireFreelancerScreenState extends State<HireFreelancerScreen> {
  // ── Form ───────────────────────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _pageCtrl     = PageController();

  int     _step       = 0;  // 0 = preview, 1 = form, 2 = konfirmasi
  int     _catIndex   = 0;
  String? _deadline;
  bool    _isCreating = false;
  String? _error;

  static const _categories = [
    'UI/UX Design', 'Web Development', 'Mobile App',
    'Copywriting', 'Graphic Design', 'Marketing',
    'Data Analysis', 'Video Editing', 'Others',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _budgetMinCtrl.dispose(); _budgetMaxCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Create Task + Open Chat ────────────────────────────────────────
  Future<void> _doHire() async {
    setState(() { _isCreating = true; _error = null; });
    HapticFeedback.lightImpact();

    try {
      final svc     = TaskService();
      final chatSvc = ChatService();

      // 1. Create task
      final taskRes = await svc.createTask(
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _categories[_catIndex],
        budgetMin:   double.tryParse(_budgetMinCtrl.text.replaceAll('.', '')) ?? 0,
        budgetMax:   double.tryParse(_budgetMaxCtrl.text.replaceAll('.', '')) ?? 0,
        deadline:    _deadline,
      );

      if (!taskRes.success) {
        setState(() { _isCreating = false; _error = taskRes.message ?? 'Gagal membuat proyek'; });
        return;
      }

      final taskId  = taskRes['data']?['id'] ?? taskRes['id'];
      final freelId = int.tryParse(widget.freelancer.id) ?? 0;

      // 2. Find or create chat with freelancer
      final chatRes = await chatSvc.findOrCreateChat(
        freelancerId: freelId,
        taskId:       taskId is int ? taskId : int.tryParse(taskId.toString()),
      );

      if (!mounted) return;

      if (chatRes.success) {
        final auth   = context.read<AuthProvider>();
        final chatData = chatRes['data'] as Map<String, dynamic>? ?? chatRes.data ?? {};
        final room = ChatRoom.fromApiJson(
          chatData,
          myUserId: auth.user?.id ?? '',
          myRole:   'client',
        );

        // 3. Navigate to chat, clear hire screens
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              room:        room,
              currentRole: UserRole.client,
            ),
          ),
          (route) => route.isFirst,
        );

        // Show snack after navigation
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Proyek dibuat! Chat dengan freelancer sekarang.'),
            backgroundColor: FPal.primary,
            behavior: SnackBarBehavior.floating,
          ));
        });
      } else {
        setState(() { _isCreating = false; _error = 'Proyek dibuat, tapi gagal membuka chat. Coba dari menu Chat.'; });
      }
    } catch (e) {
      setState(() { _isCreating = false; _error = 'Terjadi kesalahan: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      appBar: _buildAppBar(),
      body: Column(children: [
        _StepIndicator(current: _step),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepPreview(
                freelancer: widget.freelancer,
                onNext: _goNext,
              ),
              _StepForm(
                formKey:     _formKey,
                titleCtrl:   _titleCtrl,
                descCtrl:    _descCtrl,
                minCtrl:     _budgetMinCtrl,
                maxCtrl:     _budgetMaxCtrl,
                categories:  _categories,
                catIndex:    _catIndex,
                deadline:    _deadline,
                onCatChange: (i) => setState(() => _catIndex = i),
                onDeadline:  (d) => setState(() => _deadline = d),
                onBack:      _goBack,
                onNext:      _goNext,
              ),
              _StepConfirm(
                freelancer:  widget.freelancer,
                title:       _titleCtrl.text,
                category:    _categories[_catIndex],
                budgetMin:   _budgetMinCtrl.text,
                budgetMax:   _budgetMaxCtrl.text,
                deadline:    _deadline,
                isCreating:  _isCreating,
                error:       _error,
                onBack:      _goBack,
                onHire:      _doHire,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Profil Freelancer', 'Detail Proyek', 'Konfirmasi'];
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
        onPressed: () => _step > 0 ? _goBack() : Navigator.pop(context),
      ),
      title: Text(titles[_step],
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFEEECE8))),
    );
  }

  void _goNext() {
    if (_step == 1 && !_formKey.currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STEP INDICATOR
// ═══════════════════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['Profil', 'Proyek', 'Konfirmasi'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: List.generate(3, (i) {
          final done   = i < current;
          final active = i == current;
          return Expanded(
            child: Row(children: [
              if (i > 0) Expanded(
                child: Container(height: 2,
                  color: done ? FPal.primary : const Color(0xFFDDE2EE))),
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || active ? FPal.primary : const Color(0xFFEEECE8),
                    border: Border.all(
                      color: done || active ? FPal.primary : const Color(0xFFDDE2EE),
                      width: 1.5)),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Text('${i + 1}',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: active ? Colors.white : FPal.inkMuted)))),
                const SizedBox(height: 4),
                Text(_labels[i], style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700,
                  color: done || active ? FPal.primary : FPal.inkMuted)),
              ]),
              if (i < 2) Expanded(
                child: Container(height: 2,
                  color: i < current ? FPal.primary : const Color(0xFFDDE2EE))),
            ]),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STEP 0 — Preview Freelancer
// ═══════════════════════════════════════════════════════════════════════════════

class _StepPreview extends StatelessWidget {
  final FreelancerHireData freelancer;
  final VoidCallback onNext;
  const _StepPreview({required this.freelancer, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final f = freelancer;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Freelancer card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: FPal.primary.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, 4))]),
          child: Column(children: [
            // Avatar
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: FPal.primaryLight,
                border: Border.all(color: FPal.primary, width: 2.5)),
              child: Center(child: Text(
                f.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: FPal.primary)))),
            const SizedBox(height: 14),
            Text(f.name, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: FPal.ink)),
            const SizedBox(height: 4),
            Text(f.skill, style: const TextStyle(
              fontSize: 14, color: FPal.inkMuted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            // Stats
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _Stat('⭐', f.rating.toStringAsFixed(1), 'Rating'),
              _divider(),
              _Stat('💰', 'Rp ${(f.baseRate / 1000).round()}k', 'Per Jam'),
              _divider(),
              _Stat('⚡', f.responseTime, 'Respons'),
            ]),
          ]),
        ),

        const SizedBox(height: 20),
        // Info hire
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FPal.primaryLight, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FPal.primary.withOpacity(0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded, color: FPal.primary, size: 16),
              SizedBox(width: 6),
              Text('Cara Hire Bekerja', style: TextStyle(
                fontWeight: FontWeight.w800, color: FPal.primary, fontSize: 13)),
            ]),
            SizedBox(height: 10),
            _HireStep('1', 'Isi detail proyek yang ingin kamu kerjakan'),
            SizedBox(height: 6),
            _HireStep('2', 'Proyek dibuat dan chat dibuka otomatis'),
            SizedBox(height: 6),
            _HireStep('3', 'Diskusikan detail & mulai bekerja bersama'),
          ]),
        ),

        const SizedBox(height: 28),
        _BigBtn(
          label: 'Lanjut — Isi Detail Proyek',
          icon: Icons.arrow_forward_rounded,
          onTap: onNext,
        ),
      ],
    );
  }

  Widget _divider() => Container(
    height: 32, width: 1, color: const Color(0xFFEEECE8));

  Widget _Stat(String emoji, String val, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 2),
    Text(val, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800, color: FPal.ink)),
    Text(label, style: const TextStyle(fontSize: 10.5, color: FPal.inkMuted)),
  ]);
}

class _HireStep extends StatelessWidget {
  final String number, text;
  const _HireStep(this.number, this.text);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(color: FPal.primary, shape: BoxShape.circle),
        child: Center(child: Text(number,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(
        fontSize: 12.5, color: FPal.inkSoft, height: 1.3))),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STEP 1 — Form Detail Proyek
// ═══════════════════════════════════════════════════════════════════════════════

class _StepForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl, descCtrl, minCtrl, maxCtrl;
  final List<String> categories;
  final int catIndex;
  final String? deadline;
  final ValueChanged<int> onCatChange;
  final ValueChanged<String?> onDeadline;
  final VoidCallback onBack, onNext;

  const _StepForm({
    required this.formKey, required this.titleCtrl, required this.descCtrl,
    required this.minCtrl, required this.maxCtrl, required this.categories,
    required this.catIndex, required this.deadline, required this.onCatChange,
    required this.onDeadline, required this.onBack, required this.onNext});

  @override
  State<_StepForm> createState() => _StepFormState();
}

class _StepFormState extends State<_StepForm> {
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate:   DateTime.now().add(const Duration(days: 1)),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: FPal.primary)),
        child: child!),
    );
    if (picked != null) {
      widget.onDeadline('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title
          _Label('Judul Proyek *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.titleCtrl,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
            decoration: _dec('Contoh: Desain UI Mobile App E-Commerce',
              Icons.title_rounded),
          ),
          const SizedBox(height: 16),

          // Description
          _Label('Deskripsi Proyek *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.descCtrl,
            maxLines: 4,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
            decoration: _dec('Jelaskan kebutuhan proyek kamu secara detail...',
              Icons.description_outlined, padding: 14),
          ),
          const SizedBox(height: 16),

          // Category
          _Label('Kategori'),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = i == widget.catIndex;
                return GestureDetector(
                  onTap: () => widget.onCatChange(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? FPal.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? FPal.primary : const Color(0xFFDDE2EE))),
                    child: Text(widget.categories[i], style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : FPal.inkSoft)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Budget
          _Label('Anggaran Proyek (Rp)'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(
              controller: widget.minCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib' : null,
              decoration: _dec('Min', Icons.money_off_rounded),
            )),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('–', style: TextStyle(fontSize: 20, color: FPal.inkMuted))),
            Expanded(child: TextFormField(
              controller: widget.maxCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Wajib' : null,
              decoration: _dec('Max', Icons.attach_money_rounded),
            )),
          ]),
          const SizedBox(height: 16),

          // Deadline
          _Label('Deadline'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE2EE))),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                  color: FPal.inkMuted, size: 20),
                const SizedBox(width: 10),
                Text(widget.deadline ?? 'Pilih tanggal deadline',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.deadline != null ? FPal.ink : FPal.inkMuted)),
              ]),
            ),
          ),

          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: _OutlineBtn(
              label: 'Kembali', icon: Icons.arrow_back_rounded,
              onTap: widget.onBack)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _BigBtn(
              label: 'Lanjut — Review', icon: Icons.arrow_forward_rounded,
              onTap: widget.onNext)),
          ]),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon, {double padding = 0}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: FPal.inkMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: FPal.inkMuted, size: 20),
      filled: true, fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14 + padding),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FPal.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FPal.danger)),
    );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STEP 2 — Konfirmasi
// ═══════════════════════════════════════════════════════════════════════════════

class _StepConfirm extends StatelessWidget {
  final FreelancerHireData freelancer;
  final String title, category;
  final String? budgetMin, budgetMax, deadline;
  final bool isCreating;
  final String? error;
  final VoidCallback onBack, onHire;

  const _StepConfirm({
    required this.freelancer, required this.title, required this.category,
    required this.budgetMin, required this.budgetMax, required this.deadline,
    required this.isCreating, required this.error,
    required this.onBack, required this.onHire});

  @override
  Widget build(BuildContext context) {
    final f = freelancer;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ringkasan Hire', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: FPal.ink)),
            const Divider(height: 20),
            // Freelancer
            _Row('Freelancer', '${f.name} (${f.skill})'),
            _Row('Tarif', 'Rp ${(f.baseRate / 1000).round()}k/jam'),
            const Divider(height: 20),
            // Project
            _Row('Judul Proyek', title),
            _Row('Kategori', category),
            if (budgetMin != null && budgetMax != null)
              _Row('Anggaran', 'Rp $budgetMin – Rp $budgetMax'),
            if (deadline != null) _Row('Deadline', deadline!),
          ]),
        ),
        const SizedBox(height: 16),

        // What happens next
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FPal.primaryLight, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FPal.primary.withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.chat_bubble_rounded, color: FPal.primary, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Setelah konfirmasi, chat dengan freelancer ini akan langsung dibuka. Kamu bisa diskusikan detail lebih lanjut.',
              style: TextStyle(fontSize: 12.5, color: FPal.primary, height: 1.4))),
          ]),
        ),

        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FPal.dangerLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FPal.danger.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: FPal.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(error!, style: const TextStyle(
                fontSize: 13, color: FPal.danger))),
            ]),
          ),
        ],

        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: _OutlineBtn(
            label: 'Kembali', icon: Icons.arrow_back_rounded, onTap: onBack)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _BigBtn(
            label: isCreating ? 'Memproses...' : 'Hire Sekarang 🚀',
            icon: Icons.done_all_rounded,
            isLoading: isCreating,
            onTap: isCreating ? () {} : onHire)),
        ]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(
        fontSize: 12.5, color: FPal.inkMuted, fontWeight: FontWeight.w500))),
      const Text(': ', style: TextStyle(color: FPal.inkMuted)),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: FPal.ink))),
    ]),
  );
}

// ── Shared buttons ─────────────────────────────────────────────────────────────

class _BigBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  const _BigBtn({required this.label, required this.icon,
    this.isLoading = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6B55), Color(0xFF2D9470)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: FPal.primary.withOpacity(0.3),
          blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isLoading)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else
          Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FPal.primary, width: 1.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: FPal.primary, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: FPal.primary)),
      ]),
    ),
  );
}

Widget _Label(String text) => Text(text, style: const TextStyle(
  fontSize: 13.5, fontWeight: FontWeight.w700, color: FPal.inkSoft));
