import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Auth Flow Palette (green-white — matches Laravel design) ────────────────
class AuthFlowPalette {
  static const Color primary = FPal.primary;
  static const Color secondary = FPal.primaryDark;
  static const Color accent = Color(0xFF2D9470);
  static const Color textPrimary = Colors.white;
  static const LinearGradient backgroundGradient = FPal.heroGradient;
}

double authMaxWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1100) return 540;
  if (width >= 700) return 500;
  return 460;
}

double authHorizontalPadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 700) return 28;
  return 22;
}

double authVerticalSpacing(BuildContext context) {
  final height = MediaQuery.of(context).size.height;
  if (height < 700) return 18;
  if (height < 820) return 24;
  return 30;
}

// ─── Navy Gradient Background ─────────────────────────────────────────────────
class AuthGradientBackground extends StatelessWidget {
  final Widget child;
  const AuthGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FPal.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -120, right: -40,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2D9470).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: 200, left: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A6B55).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          child,
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthContentContainer extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  const AuthContentContainer({super.key, required this.child, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: authMaxWidth(context)),
            child: child,
          ),
        );
        final padding = EdgeInsets.symmetric(
          horizontal: authHorizontalPadding(context),
          vertical: 16,
        );
        if (scrollable) {
          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: content,
            ),
          );
        }
        return Padding(
          padding: padding,
          child: SizedBox(height: constraints.maxHeight - 32, width: double.infinity, child: content),
        );
      },
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AuthGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthBrandMark extends StatelessWidget {
  final double size;
  const AuthBrandMark({super.key, this.size = 56});
  @override
  Widget build(BuildContext context) => BrandMark(size: size, dark: true);
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  const AuthPrimaryButton({super.key, required this.label, required this.onPressed, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: FPal.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class AuthOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  const AuthOutlineButton({super.key, required this.label, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
