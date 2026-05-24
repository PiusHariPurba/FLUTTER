import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_flow_widgets.dart';

class DashboardScaffold extends StatelessWidget {
  final Widget body;
  const DashboardScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverToBoxAdapter(child: body),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHeroCard extends StatelessWidget {
  final String greeting;
  final String title;
  final String description;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;
  final List<DashboardQuickAction> quickActions;
  final Widget trailing;

  const DashboardHeroCard({
    super.key,
    required this.greeting,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.quickActions,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: Pal.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Pal.accent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, height: 1.2, fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.55, fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              trailing,
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBtn(label: primaryActionLabel, icon: primaryActionIcon, onTap: onPrimaryAction, filled: true),
              ...quickActions.map((a) => _HeroBtn(label: a.label, icon: a.icon, onTap: a.onTap, filled: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _HeroBtn({required this.label, required this.icon, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: filled ? Pal.accent : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: filled ? Pal.accent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardQuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const DashboardQuickAction({required this.label, required this.icon, required this.onTap});
}

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h2),
              const SizedBox(height: 3),
              Text(subtitle, style: AppText.caption.copyWith(color: Pal.inkMuted, fontSize: 12.5)),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, color: Pal.accent)),
          ),
      ],
    );
  }
}

class DashboardMetricGrid extends StatelessWidget {
  final List<DashboardMetricData> metrics;
  const DashboardMetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final w = cons.maxWidth;
        final cols = w >= 560 ? 2 : 1;
        const sp = 12.0;
        final iw = cols == 1 ? w : (w - sp) / 2;

        return Wrap(
          spacing: sp,
          runSpacing: sp,
          children: metrics.map((m) => SizedBox(width: iw, child: _MetricCard(m: m))).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final DashboardMetricData m;
  const _MetricCard({required this.m});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: m.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.value, style: AppText.h2.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(m.label, style: AppText.caption),
                if (m.helperText != null)
                  Text(m.helperText!, style: TextStyle(fontSize: 11, color: m.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetricData {
  final String label, value;
  final String? helperText;
  final IconData icon;
  final Color color;
  const DashboardMetricData({required this.label, required this.value, required this.icon, required this.color, this.helperText});
}

class DashboardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DashboardPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: padding, child: child);
  }
}
