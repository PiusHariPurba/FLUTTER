import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Original Palette (kept for non-freelancer screens) ──────────────────────
class Pal {
  static const Color bg = Color(0xFFF7F6F3);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF2F1EE);
  static const Color ink = Color(0xFF1A1918);
  static const Color inkSoft = Color(0xFF5C5855);
  static const Color inkMuted = Color(0xFF9C9893);
  static const Color accent = Color(0xFF1A6B55);
  static const Color accentLight = Color(0xFFE8F4F0);
  static const Color accentMid = Color(0xFF2D9470);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFEDE9FE);
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2318), Color(0xFF1A6B55), Color(0xFF2D9470)],
    stops: [0.0, 0.55, 1.0],
  );
}

// ─── Unified Green Palette (aligns with Pal — green-white Laravel style) ─────
class FPal {
  // Background
  static const Color bg = Color(0xFFF7F6F3);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF2F1EE);

  // Text
  static const Color ink = Color(0xFF1A1918);
  static const Color inkSoft = Color(0xFF5C5855);
  static const Color inkMuted = Color(0xFF9C9893);

  // Primary — forest green (matching Laravel green-white design)
  static const Color primary = Color(0xFF1A6B55);
  static const Color primaryDark = Color(0xFF0F4A3A);
  static const Color primaryLight = Color(0xFFE8F4F0);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color highDemand = Color(0xFF059669);
  static const Color highDemandBg = Color(0xFFD1FAE5);

  // Hero gradient (green — matching Laravel 12 design)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2318), Color(0xFF1A6B55), Color(0xFF2D9470)],
    stops: [0.0, 0.55, 1.0],
  );

  // Stats gradient
  static const LinearGradient statsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B55), Color(0xFF0F2318)],
  );
}

// ─── Text Styles ────────────────────────────────────────────────────────────
class AppText {
  static const TextStyle display = TextStyle(
    fontSize: 30, fontWeight: FontWeight.w800,
    color: Pal.ink, letterSpacing: -0.5, height: 1.1,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: Pal.ink, letterSpacing: -0.3, height: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: Pal.ink, letterSpacing: -0.2, height: 1.25,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: Pal.ink, height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: Pal.inkSoft, height: 1.6,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: Pal.ink, height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: Pal.inkMuted, height: 1.4,
    letterSpacing: 0.1,
  );
  static const TextStyle captionBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: Pal.inkSoft, height: 1.4,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: Pal.inkMuted, letterSpacing: 0.6,
  );
}

// ─── Theme Builder ──────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Pal.bg,
    colorScheme: const ColorScheme.light(
      primary: Pal.accent,
      secondary: Pal.accentMid,
      surface: Pal.bgCard,
      onPrimary: Colors.white,
    ),
    fontFamily: 'Nunito',
    appBarTheme: const AppBarTheme(
      backgroundColor: Pal.bg,
      foregroundColor: Pal.ink,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: Pal.ink, letterSpacing: -0.1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Pal.bgMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E4E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Pal.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Pal.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Pal.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Pal.inkMuted, fontSize: 14),
      labelStyle: const TextStyle(color: Pal.inkSoft, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Pal.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pal.ink,
        side: const BorderSide(color: Color(0xFFE0DDD9)),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Pal.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Pal.bgMuted,
      selectedColor: Pal.accentLight,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Pal.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: Color(0xFFE6E4E0)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFECEAE6), thickness: 1),
  );
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = 18,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? Pal.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: hasBorder ? Border.all(color: const Color(0xFFECEAE6)) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1918).withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      );
    }
    return card;
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const SectionLabel(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text, style: AppText.h2),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppText.body.copyWith(color: Pal.accent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;

  const StatusPill({super.key, required this.label, required this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Pal.bgMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E4E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Pal.inkMuted),
          const SizedBox(width: 5),
          Text(label, style: AppText.caption.copyWith(color: Pal.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFECEAE6));
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  final bool dark;

  const BrandMark({super.key, this.size = 52, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = dark ? Colors.white : FPal.primary;
    final iconColor = dark ? FPal.primary : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.handshake_rounded, size: size * 0.48, color: iconColor),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else ...[
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(label),
            ],
          ],
        ),
      ),
    );
  }
}
