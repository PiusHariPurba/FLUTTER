import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';

/// Penyimpanan lokal pesan chat menggunakan SharedPreferences.
/// Setiap chat room disimpan sebagai JSON list dengan key unik.
/// Reactions disimpan terpisah per message supaya update cepat.
class LocalChatStorage {
  // Singleton
  static final LocalChatStorage _instance = LocalChatStorage._();
  factory LocalChatStorage() => _instance;
  LocalChatStorage._();

  static const _msgPrefix      = 'chat_msgs_';
  static const _reactPrefix    = 'chat_react_';
  static const _maxCachedMsgs  = 200; // maks pesan per room yang disimpan

  // ── Pesan ────────────────────────────────────────────────────────────────

  /// Simpan list pesan ke SharedPreferences.
  /// Hanya simpan [_maxCachedMsgs] pesan terakhir per room.
  Future<void> saveMessages(int chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = messages.length > _maxCachedMsgs
          ? messages.sublist(messages.length - _maxCachedMsgs)
          : messages;

      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString('$_msgPrefix$chatId', encoded);
    } catch (e) {
      debugPrint('[LocalStorage] saveMessages error: $e');
    }
  }

  /// Muat pesan dari SharedPreferences.
  /// Return list kosong jika belum ada cache.
  Future<List<ChatMessage>> loadMessages(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString('$_msgPrefix$chatId');
      if (raw == null) return [];

      final list = jsonDecode(raw) as List;
      return list
          .map((j) => ChatMessage.fromLocalJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocalStorage] loadMessages error: $e');
      return [];
    }
  }

  /// Hapus cache pesan untuk satu room (misal setelah logout)
  Future<void> clearMessages(int chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_msgPrefix$chatId');
  }

  // ── Reactions (lokal saja, tidak disimpan ke server) ──────────────────────

  /// Simpan map reactions untuk satu pesan.
  /// key = messageId, value = Map<emoji, List<userId>>
  Future<void> saveReactions(int chatId, String messageId, List<MessageReaction> reactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key   = '$_reactPrefix${chatId}_$messageId';
      final encoded = jsonEncode(reactions.map((r) => r.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('[LocalStorage] saveReactions error: $e');
    }
  }

  /// Muat reactions untuk satu pesan.
  Future<List<MessageReaction>> loadReactions(int chatId, String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key   = '$_reactPrefix${chatId}_$messageId';
      final raw   = prefs.getString(key);
      if (raw == null) return [];

      final list = jsonDecode(raw) as List;
      return list.map((j) => MessageReaction.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[LocalStorage] loadReactions error: $e');
      return [];
    }
  }

  /// Muat semua reactions untuk sekumpulan messageId sekaligus
  Future<Map<String, List<MessageReaction>>> loadAllReactions(
    int chatId,
    List<String> messageIds,
  ) async {
    final result = <String, List<MessageReaction>>{};
    for (final mid in messageIds) {
      result[mid] = await loadReactions(chatId, mid);
    }
    return result;
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Hapus semua data chat lokal (panggil saat logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_msgPrefix) || key.startsWith(_reactPrefix)) {
        await prefs.remove(key);
      }
    }
    debugPrint('[LocalStorage] All chat data cleared');
  }
}
