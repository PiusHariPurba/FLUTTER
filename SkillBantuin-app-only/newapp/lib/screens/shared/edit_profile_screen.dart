// ─────────────────────────────────────────────────────────────────────────────
//  edit_profile_screen.dart  —  Informasi Pribadi + Ganti Password + Avatar
//  Dipakai oleh kedua role: Client & Freelancer
//  API: PUT /user · PUT /user/password · PUT /freelancers/profile · POST /upload
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../providers/providers.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/freelancer_service.dart';
import '../../widgets/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────
  final _nameCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _bioCtrl       = TextEditingController();
  final _rateCtrl      = TextEditingController();
  final _curPassCtrl   = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  final _passFormKey    = GlobalKey<FormState>();
  final _skillCtrl     = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────
  bool _isSaving      = false;
  bool _isSavingPass  = false;
  bool _isUploadingAvatar = false;
  bool _showPassSec   = false;
  bool _obscureCur    = true;
  bool _obscureNew    = true;
  bool _obscureConf   = true;
  List<String> _skills = [];
  String? _saveError;
  String? _passError;
  bool _savedOk       = false;
  String? _localAvatarPath; // path file lokal setelah user pick gambar

  late final AuthService      _authSvc;
  late final FreelancerService _flSvc;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _authSvc = AuthService();
    _flSvc   = FreelancerService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _populate() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameCtrl.text     = user.fullName;
    _usernameCtrl.text = user.username;
    _phoneCtrl.text    = user.phoneNumber;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _usernameCtrl, _phoneCtrl, _bioCtrl,
        _rateCtrl, _curPassCtrl, _newPassCtrl, _confPassCtrl, _skillCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Avatar Pick & Upload ───────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    HapticFeedback.lightImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() { _isUploadingAvatar = true; _localAvatarPath = file.path; });

    try {
      final res = await _api.uploadFileWithFields(
        '/upload',
        file.path!,
        fields: {'type': 'avatar'},
      );

      if (res.success) {
        // Refresh user dari server agar avatar URL terbaru tersimpan di provider
        final auth = context.read<AuthProvider>();
        await auth.refreshUser();
        _showSnack('Foto profil berhasil diperbarui', isError: false);
      } else {
        _showSnack(res.message ?? 'Gagal upload foto', isError: true);
        setState(() => _localAvatarPath = null);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      setState(() => _localAvatarPath = null);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Save Profile ───────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _saveError = null; _savedOk = false; });
    HapticFeedback.lightImpact();

    final auth   = context.read<AuthProvider>();
    final isFL   = auth.user?.role == UserRole.freelancer;

    final ok = await auth.updateProfile(
      name:     _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
    );

    if (ok && isFL && (_bioCtrl.text.isNotEmpty || _skills.isNotEmpty || _rateCtrl.text.isNotEmpty)) {
      await _flSvc.updateProfile(
        bio:        _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
        skills:     _skills.isNotEmpty ? _skills : null,
        hourlyRate: double.tryParse(_rateCtrl.text.replaceAll('.', '')),
      );
    }

    setState(() {
      _isSaving = false;
      _savedOk  = ok;
      _saveError = ok ? null : (auth.error ?? 'Gagal menyimpan profil');
    });

    if (ok) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context, true);
    }
  }

  // ── Change Password ────────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() { _isSavingPass = true; _passError = null; });
    HapticFeedback.lightImpact();

    final res = await _authSvc.updatePassword(
      currentPassword: _curPassCtrl.text,
      newPassword:     _newPassCtrl.text,
      confirmPassword: _confPassCtrl.text,
    );

    setState(() {
      _isSavingPass = false;
      _passError    = res.success ? null : (res.message ?? 'Gagal mengubah password');
    });

    if (res.success) {
      HapticFeedback.mediumImpact();
      _curPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      setState(() => _showPassSec = false);
      _showSnack('Password berhasil diubah', isError: false);
    } else {
      _showSnack(_passError ?? 'Error', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? FPal.danger : FPal.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isFL = user?.role == UserRole.freelancer;

    // Avatar: lokal dulu, fallback ke URL server, fallback ke initial
    Widget avatarChild;
    if (_localAvatarPath != null && !_isUploadingAvatar) {
      avatarChild = ClipOval(
        child: Image.file(File(_localAvatarPath!), fit: BoxFit.cover,
          width: 88, height: 88));
    } else if (user?.avatar != null && (user!.avatar!.startsWith('http'))) {
      avatarChild = ClipOval(
        child: Image.network(user.avatar!, fit: BoxFit.cover,
          width: 88, height: 88,
          errorBuilder: (_, __, ___) => _avatarInitial(user.fullName)));
    } else {
      avatarChild = _avatarInitial(user?.fullName ?? '?');
    }

    return Scaffold(
      backgroundColor: FPal.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: FPal.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Informasi Pribadi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: FPal.ink)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEECE8)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [

            // ── Avatar dengan pick & upload ────────────────────────
            Center(
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FPal.primaryLight,
                      border: Border.all(color: FPal.primary, width: 2.5),
                    ),
                    child: _isUploadingAvatar
                        ? const Center(child: SizedBox(width: 32, height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: FPal.primary)))
                        : avatarChild,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _isUploadingAvatar ? FPal.inkMuted : FPal.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Ketuk foto untuk mengganti',
                style: const TextStyle(fontSize: 12, color: FPal.inkMuted)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(user?.email ?? '',
                style: const TextStyle(
                  fontSize: 13, color: FPal.inkMuted, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 24),

            // ── Basic Info ─────────────────────────────────────────
            _SectionLabel('Informasi Dasar'),
            const SizedBox(height: 12),
            _Field(
              controller: _nameCtrl,
              label: 'Nama Lengkap',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email_rounded,
              hint: 'contoh: john_doe',
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return null;
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v!))
                  return 'Hanya huruf, angka, dan underscore';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _phoneCtrl,
              label: 'Nomor HP',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),

            // ── Freelancer Extra ───────────────────────────────────
            if (isFL) ...[
              const SizedBox(height: 24),
              _SectionLabel('Profil Freelancer'),
              const SizedBox(height: 12),
              _Field(
                controller: _bioCtrl,
                label: 'Bio / Deskripsi Diri',
                icon: Icons.info_outline_rounded,
                maxLines: 3,
                hint: 'Ceritakan keahlian dan pengalamanmu...',
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _rateCtrl,
                label: 'Tarif per Jam (Rp)',
                icon: Icons.payments_outlined,
                keyboard: TextInputType.number,
                hint: 'contoh: 150000',
              ),
              const SizedBox(height: 12),
              _SkillsInput(
                skills: _skills,
                ctrl:   _skillCtrl,
                onAdd: (s) => setState(() => _skills.add(s)),
                onRemove: (s) => setState(() => _skills.remove(s)),
              ),
            ],

            // ── Error / Success ────────────────────────────────────
            if (_saveError != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(_saveError!),
            ],
            if (_savedOk) ...[
              const SizedBox(height: 16),
              _SuccessBanner('Profil berhasil disimpan!'),
            ],

            // ── Save Button ────────────────────────────────────────
            const SizedBox(height: 24),
            _PrimaryBtn(
              label: 'Simpan Perubahan',
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onTap: _saveProfile,
            ),

            // ── Ganti Password ─────────────────────────────────────
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => setState(() => _showPassSec = !_showPassSec),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEECE8))),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: FPal.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.lock_outline_rounded,
                      color: FPal.primary, size: 18)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ganti Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FPal.ink)),
                      Text('Ubah password akun kamu',
                        style: TextStyle(fontSize: 12, color: FPal.inkMuted)),
                    ],
                  )),
                  Icon(_showPassSec
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                    color: FPal.inkMuted),
                ]),
              ),
            ),

            if (_showPassSec) ...[
              const SizedBox(height: 16),
              Form(
                key: _passFormKey,
                child: Column(children: [
                  _PassField(
                    controller: _curPassCtrl,
                    label: 'Password Saat Ini',
                    obscure: _obscureCur,
                    onToggle: () => setState(() => _obscureCur = !_obscureCur),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  _PassField(
                    controller: _newPassCtrl,
                    label: 'Password Baru',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Wajib diisi';
                      if ((v?.length ?? 0) < 8) return 'Minimal 8 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _PassField(
                    controller: _confPassCtrl,
                    label: 'Konfirmasi Password Baru',
                    obscure: _obscureConf,
                    onToggle: () => setState(() => _obscureConf = !_obscureConf),
                    validator: (v) => v != _newPassCtrl.text
                        ? 'Password tidak cocok' : null,
                  ),
                  if (_passError != null) ...[
                    const SizedBox(height: 10),
                    _ErrorBanner(_passError!),
                  ],
                  const SizedBox(height: 14),
                  _PrimaryBtn(
                    label: 'Ubah Password',
                    icon: Icons.lock_reset_rounded,
                    isLoading: _isSavingPass,
                    onTap: _changePassword,
                    color: const Color(0xFF0369A1),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatarInitial(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 32, fontWeight: FontWeight.w900, color: FPal.primary),
    ),
  );
}

// ── Skill Tags Input ──────────────────────────────────────────────────────────

class _SkillsInput extends StatelessWidget {
  final List<String> skills;
  final TextEditingController ctrl;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  const _SkillsInput({
    required this.skills, required this.ctrl,
    required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Skills',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: FPal.inkSoft)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE2EE))),
        child: Row(children: [
          const SizedBox(width: 14),
          Expanded(child: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Tambah skill (Enter)',
              hintStyle: TextStyle(color: FPal.inkMuted, fontSize: 14),
              border: InputBorder.none, isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 13)),
            onSubmitted: (v) {
              final s = v.trim();
              if (s.isNotEmpty && !skills.contains(s)) {
                onAdd(s); ctrl.clear();
              }
            },
          )),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: FPal.primary),
            onPressed: () {
              final s = ctrl.text.trim();
              if (s.isNotEmpty && !skills.contains(s)) {
                onAdd(s); ctrl.clear();
              }
            }),
        ]),
      ),
      if (skills.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: skills.map((s) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FPal.primaryLight, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FPal.primary.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(s, style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: FPal.primary)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onRemove(s),
                child: const Icon(Icons.close_rounded,
                  size: 14, color: FPal.primary)),
            ]),
          )).toList()),
      ],
    ],
  );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 16,
      decoration: BoxDecoration(
        color: FPal.primary, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w800, color: FPal.ink)),
  ]);
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller, required this.label, required this.icon,
    this.hint, this.keyboard, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: maxLines,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: FPal.inkMuted, size: 20),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FPal.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FPal.danger)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  const _PassField({required this.controller, required this.label,
    required this.obscure, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: FPal.inkMuted, size: 20),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: FPal.inkMuted, size: 20),
        onPressed: onToggle),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FPal.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  final Color? color;
  const _PrimaryBtn({required this.label, required this.icon,
    required this.isLoading, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: isLoading ? (color ?? FPal.primary).withOpacity(0.7) : (color ?? FPal.primary),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: (color ?? FPal.primary).withOpacity(0.3),
          blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (isLoading)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else
          Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FPal.dangerLight, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: FPal.danger.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: FPal.danger, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
        style: const TextStyle(fontSize: 13, color: FPal.danger))),
    ]),
  );
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FPal.successLight, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: FPal.success.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.check_circle_rounded, color: FPal.success, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
        style: const TextStyle(fontSize: 13, color: FPal.success))),
    ]),
  );
}
