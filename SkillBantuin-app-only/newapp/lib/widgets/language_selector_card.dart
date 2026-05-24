import 'package:flutter/material.dart';
import '../utils/language_notifier.dart';
import '../utils/app_localizations.dart';
import 'app_theme.dart';

/// A reusable card widget that lets users switch between Indonesian and English.
/// Place it in any profile screen. Rebuilds automatically on language change.
class LanguageSelectorCard extends StatefulWidget {
  const LanguageSelectorCard({super.key});

  @override
  State<LanguageSelectorCard> createState() => _LanguageSelectorCardState();
}

class _LanguageSelectorCardState extends State<LanguageSelectorCard> {
  @override
  void initState() {
    super.initState();
    LanguageNotifier.instance.addListener(_onLanguageChange);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_onLanguageChange);
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  Future<void> _selectLanguage(String lang) async {
    await LanguageNotifier.instance.setLanguage(lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL.tr('language_changed')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: FPal.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = LanguageNotifier.instance.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FPal.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL.tr('language'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: FPal.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LangOption(
                flag: '🇮🇩',
                label: AppL.tr('language_id'),
                isSelected: current == 'id',
                onTap: () => _selectLanguage('id'),
              ),
              const SizedBox(width: 10),
              _LangOption(
                flag: '🇬🇧',
                label: AppL.tr('language_en'),
                isSelected: current == 'en',
                onTap: () => _selectLanguage('en'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? FPal.primary : FPal.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? FPal.primary : const Color(0xFFDDE2EE),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: FPal.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : FPal.inkSoft,
                ),
              ),
              const SizedBox(height: 2),
              if (isSelected)
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
