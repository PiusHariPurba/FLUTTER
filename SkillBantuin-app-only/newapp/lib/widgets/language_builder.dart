import 'package:flutter/material.dart';
import '../utils/language_notifier.dart';

/// Wraps any widget tree and forces a full rebuild whenever the language changes.
/// Place this high in the widget tree (e.g. wrapping MaterialApp's home) to
/// propagate language updates to all screens at once.
class LanguageBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, String lang) builder;
  const LanguageBuilder({super.key, required this.builder});

  @override
  State<LanguageBuilder> createState() => _LanguageBuilderState();
}

class _LanguageBuilderState extends State<LanguageBuilder> {
  @override
  void initState() {
    super.initState();
    LanguageNotifier.instance.addListener(_onLangChange);
  }

  @override
  void dispose() {
    LanguageNotifier.instance.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, LanguageNotifier.instance.value);
  }
}
