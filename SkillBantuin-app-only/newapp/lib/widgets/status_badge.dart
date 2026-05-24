export 'app_theme.dart' show StatusPill;
import 'package:flutter/material.dart';
import 'app_theme.dart';

// Backward-compatible StatusBadge alias
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: label, color: color);
  }
}
