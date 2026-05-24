import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool showCheckIcon;

  const ProfileSection({
    super.key,
    required this.title,
    required this.items,
    this.showCheckIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      if (showCheckIcon) ...[
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: Pal.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.check_rounded, size: 14, color: Pal.accent),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: Text(e.value, style: AppText.bodyBold)),
                    ],
                  ),
                ),
                if (!isLast) const AppDivider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}
