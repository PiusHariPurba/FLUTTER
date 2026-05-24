import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';
import 'client_home_screen.dart';
import 'client_progress_screen.dart';
import 'client_chat_list_screen.dart';
import 'client_profile_screen.dart';

/// Navigation shell khusus Client — completely independent dari Freelancer.
/// Setiap tab punya page sendiri, bottom nav style sendiri.
class ClientNavigationScreen extends StatefulWidget {
  const ClientNavigationScreen({super.key});

  @override
  State<ClientNavigationScreen> createState() => _ClientNavigationScreenState();
}

class _ClientNavigationScreenState extends State<ClientNavigationScreen>
    with TickerProviderStateMixin {
  // Index tab yang aktif (0=Home, 1=Progress, 2=Chat, 3=Profile)
  int _currentIndex = 0;

  // Controller animasi fade saat pindah tab
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Daftar halaman client — hanya client screens, ga ada freelancer
  final List<Widget> _pages = const [
    ClientHomeScreen(),
    ClientProgressScreen(),
    ClientChatListScreen(),
    ClientProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Setup fade animation — tiap kali pindah tab akan fade in
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward(); // Langsung play di awal

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    // Listen perubahan bahasa agar label nav ikut update
    LanguageNotifier.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_onLanguageChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Rebuild widget saat bahasa berubah
  void _onLanguageChanged() => setState(() {});

  /// Handle tap pada tab — skip jika sudah di tab yang sama
  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _fadeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style ke dark (icon hitam di atas bg putih)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    final isId = LanguageNotifier.instance.isIndonesian;

    // Data untuk setiap nav item — icon active, icon inactive, label
    final navItems = [
      _NavData(Icons.home_rounded, Icons.home_outlined, isId ? 'Home' : 'Home'),
      _NavData(Icons.assignment_turned_in_rounded, Icons.assignment_outlined, isId ? 'Progress' : 'Progress'),
      _NavData(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, isId ? 'Chat' : 'Chat'),
      _NavData(Icons.person_rounded, Icons.person_outline_rounded, isId ? 'Profile' : 'Profile'),
    ];

    return Scaffold(
      // Body: IndexedStack menjaga state tiap page saat pindah tab
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),

      // Bottom Navigation Bar — custom design sesuai mockup
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Garis tipis di atas nav bar sebagai separator
          border: const Border(
            top: BorderSide(color: Color(0xFFEEECE8), width: 1),
          ),
          // Shadow halus ke atas
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false, // Hanya padding bottom (untuk gesture bar / home indicator)
          child: SizedBox(
            height: 65,
            child: Row(
              children: navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == _currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque, // Seluruh area bisa di-tap
                    child: _ClientNavItem(
                      item: item,
                      isActive: isActive,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data model untuk setiap item di bottom nav
class _NavData {
  final IconData activeIcon;   // Icon saat tab aktif (filled)
  final IconData inactiveIcon; // Icon saat tab tidak aktif (outlined)
  final String label;          // Text di bawah icon

  const _NavData(this.activeIcon, this.inactiveIcon, this.label);
}

/// Widget untuk satu item di bottom nav — animasi warna & size saat active
class _ClientNavItem extends StatelessWidget {
  final _NavData item;
  final bool isActive;

  const _ClientNavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Container animated — saat active, ada background hijau muda (pill shape)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            // Active: bg hijau muda (primaryLight), inactive: transparent
            color: isActive ? FPal.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isActive ? item.activeIcon : item.inactiveIcon,
            size: 22,
            // Active: hijau primer, inactive: abu-abu
            color: isActive ? FPal.primary : FPal.inkMuted,
          ),
        ),
        const SizedBox(height: 3),
        // Label text di bawah icon
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            // Active: lebih tebal & hijau, inactive: lebih tipis & abu
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? FPal.primary : FPal.inkMuted,
          ),
        ),
      ],
    );
  }
}
