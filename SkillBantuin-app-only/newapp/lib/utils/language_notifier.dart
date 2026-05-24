import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ValueNotifier that holds the current language code ('id' or 'en').
/// Persists the selection via SharedPreferences.
class LanguageNotifier extends ValueNotifier<String> {
  LanguageNotifier._() : super('id');

  static final LanguageNotifier instance = LanguageNotifier._();

  static const _key = 'app_language';

  /// Load persisted language on startup.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && (saved == 'id' || saved == 'en')) {
      value = saved;
    }
  }

  /// Toggle between 'id' and 'en', then persist.
  Future<void> setLanguage(String lang) async {
    if (lang == value) return;
    value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
  }

  bool get isIndonesian => value == 'id';
  bool get isEnglish => value == 'en';
}
