import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/language_notifier.dart';
import '../../widgets/app_theme.dart';
import 'freelancer_home_screen.dart';
import 'freelancer_progress_screen.dart';
import 'freelancer_chat_list_screen.dart';
import 'freelancer_profile_screen.dart';

/// Navigation shell khusus Freelancer — completely independent dari Client.
class FreelancerNavigationScreen extends StatefulWidget {
  const FreelancerNavigationScreen({super.key});
  @override
  State<FreelancerNavigationScreen> createState() => _FreelancerNavigationScreenState();
}

class _FreelancerNavigationScreenState extends State<FreelancerNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final List<Widget> _pages = const [
    FreelancerHomeScreen(),
    FreelancerProgressScreen(),
    FreelancerChatListScreen(),
    FreelancerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    LanguageNotifier.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_rebuild);
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final navItems = [
      _Nav(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _Nav(Icons.assignment_turned_in_rounded, Icons.assignment_outlined, 'Progress'),
      _Nav(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
      _Nav(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFEEECE8), width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Row(
              children: navItems.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final isActive = i == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200), curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? FPal.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(isActive ? item.activeIcon : item.inactiveIcon,
                              size: 22, color: isActive ? FPal.primary : FPal.inkMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(item.label, style: TextStyle(fontSize: 11,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? FPal.primary : FPal.inkMuted)),
                      ],
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

class _Nav {
  final IconData activeIcon, inactiveIcon;
  final String label;
  const _Nav(this.activeIcon, this.inactiveIcon, this.label);
}
