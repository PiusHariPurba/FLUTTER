import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/local_chat_storage.dart';

/// Provider chat — single source of truth untuk semua state percakapan.
///
/// Fitur:
/// • Offline-first: load dari cache lokal dulu, lalu sync ke server
/// • Optimistic send: pesan langsung muncul (status pending) sebelum server konfirmasi
/// • Delta polling: hanya ambil pesan baru (after_id) bukan semua ulang
/// • Reactions: disimpan lokal per device, tidak perlu server
/// • File/image: upload dulu ke /upload, lalu kirim URL sebagai attachment
class ChatProvider extends ChangeNotifier {
  final _svc     = ChatService();
  final _storage = LocalChatStorage();

  // ── State ──────────────────────────────────────────────────────────────────

  List<ChatRoom>              _rooms              = [];
  final Map<int, List<ChatMessage>> _messagesByRoom = {};
  final Map<int, int>         _lastIdByRoom       = {};
  final Map<int, bool>        _hasNewUnseen       = {};

  bool    _isLoading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ChatRoom> get rooms     => _rooms;
  bool           get isLoading => _isLoading;
  String?        get error     => _error;

  int get totalUnread =>
      _rooms.fold(0, (sum, r) => sum + r.unreadCount);

  ChatRoom? getRoomById(String id) {
    try { return _rooms.firstWhere((r) => r.id == id); } catch (_) { return null; }
  }

  List<ChatMessage> getMessages(int chatId) => _messagesByRoom[chatId] ?? [];

  bool hasNewUnseen(int chatId) => _hasNewUnseen[chatId] ?? false;

  // ── Load Chat Rooms ────────────────────────────────────────────────────────

  Future<void> loadChats({
    required String myUserId,
    required String myRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await _svc.getChats();
    if (res.success) {
      final list = res['data'] as List? ?? [];
      _rooms = list
          .map((j) => ChatRoom.fromApiJson(
                j as Map<String, dynamic>,
                myUserId: myUserId,
                myRole:   myRole,
              ))
          .toList();
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Load Messages (offline-first) ──────────────────────────────────────────

  /// 1. Load dari lokal → tampil instan
  /// 2. Fetch server → merge reactions dari lokal ke pesan baru
  Future<void> loadMessages(
    int chatId, {
    required String myUserId,
    required String clientId,
  }) async {
    // Langkah 1: Local cache dulu
    final cached = await _storage.loadMessages(chatId);
    if (cached.isNotEmpty && _messagesByRoom[chatId] == null) {
      // Inject stored reactions ke cached messages
      final withReact = await _injectReactions(chatId, cached);
      _messagesByRoom[chatId] = withReact;
      notifyListeners();
    }

    // Langkah 2: Fetch dari server
    _isLoading = true;
    notifyListeners();

    final res = await _svc.getMessages(chatId, page: 1);
    if (res.success) {
      final paginated = res['data'];
      final rawList   = paginated?['data'] as List? ?? paginated as List? ?? [];

      final msgs = (rawList)
          .map((j) => ChatMessage.fromApiJson(
                j as Map<String, dynamic>,
                myUserId: myUserId,
                clientId: clientId,
              ))
          .toList()
          .reversed
          .toList();

      // Inject reactions lokal ke pesan dari server
      final withReact = await _injectReactions(chatId, msgs);

      _messagesByRoom[chatId] = withReact;
      _updateLastId(chatId, withReact);

      // Simpan ke lokal (tanpa reactions agar disimpan terpisah)
      await _storage.saveMessages(chatId, msgs);
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Delta Polling ──────────────────────────────────────────────────────────

  /// Ambil hanya pesan baru (setelah lastId). Return jumlah pesan baru.
  Future<int> pollNewMessages(
    int chatId, {
    required String myUserId,
    required String clientId,
    required bool isAtBottom,
  }) async {
    final afterId = _lastIdByRoom[chatId] ?? 0;
    final res     = await _svc.getMessages(chatId, afterId: afterId);
    if (!res.success) return 0;

    List<dynamic> rawList;
    final mode = res['mode'] as String? ?? 'paginated';
    if (mode == 'delta') {
      rawList = res['data'] as List? ?? [];
    } else {
      rawList = (res['data']?['data'] as List? ?? []);
    }
    if (rawList.isEmpty) return 0;

    final newMsgs = rawList
        .map((j) => ChatMessage.fromApiJson(
              j as Map<String, dynamic>,
              myUserId: myUserId,
              clientId: clientId,
            ))
        .toList();

    final existing    = _messagesByRoom[chatId] ?? [];
    final existingIds = existing.map((m) => m.id).toSet();
    final toAdd       = newMsgs.where((m) => !existingIds.contains(m.id)).toList();
    if (toAdd.isEmpty) return 0;

    // Inject reactions lokal ke pesan baru
    final toAddWithReact = await _injectReactions(chatId, toAdd);

    final merged = [...existing, ...toAddWithReact];
    _messagesByRoom[chatId] = merged;
    _updateLastId(chatId, merged);

    if (!isAtBottom) {
      _hasNewUnseen[chatId] = true;
    }

    // Perbarui cache lokal
    await _storage.saveMessages(chatId, merged);

    notifyListeners();
    return toAdd.length;
  }

  void clearNewUnseen(int chatId) {
    _hasNewUnseen[chatId] = false;
    notifyListeners();
  }

  // ── Send Message ───────────────────────────────────────────────────────────

  /// Kirim pesan dengan optimistic UI.
  /// [localFilePath] → path file lokal, di-upload dulu sebelum kirim.
  /// Return true jika berhasil.
  Future<bool> sendMessage({
    required int chatId,
    required String myUserId,
    required String clientId,
    required ChatPartyRole mySenderRole,
    String? body,
    String? localFilePath, // path file yang dipilih user
    String type = 'text',
  }) async {
    // ── Optimistic: tambah pesan dengan status pending ──
    final now       = DateTime.now();
    final timeLabel = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tempId    = 'temp_${now.millisecondsSinceEpoch}';

    final optimistic = ChatMessage(
      id:          tempId,
      sender:      mySenderRole,
      senderId:    myUserId,
      type:        type == 'image'
          ? ChatMessageType.image
          : (type == 'file' ? ChatMessageType.file : ChatMessageType.text),
      content:     body ?? '',
      timeLabel:   timeLabel,
      status:      ChatStatus.sent,
      localStatus: LocalMessageStatus.pending,
      attachment:  localFilePath, // tampilkan preview lokal dulu
      createdAt:   now,
    );

    final existing = _messagesByRoom[chatId] ?? [];
    _messagesByRoom[chatId] = [...existing, optimistic];
    notifyListeners();

    // ── Upload file jika ada ──
    String? attachmentUrl;
    if (localFilePath != null) {
      final uploadRes = await _svc.uploadAttachment(localFilePath);
      if (uploadRes.success) {
        attachmentUrl = uploadRes['data']?['url'] as String? ??
                        uploadRes['url'] as String?;
      } else {
        _markFailed(chatId, tempId);
        return false;
      }
    }

    // ── POST ke server ──
    final res = await _svc.sendMessage(
      chatId,
      body:       body,
      attachment: attachmentUrl,
      type:       type,
    );

    if (res.success && res['data'] != null) {
      final confirmed = ChatMessage.fromApiJson(
        res['data'] as Map<String, dynamic>,
        myUserId: myUserId,
        clientId: clientId,
      );
      // Ganti pesan optimistic dengan yang sudah dikonfirmasi
      _replaceTemp(chatId, tempId, confirmed);

      // Update cache lokal
      await _storage.saveMessages(chatId, _messagesByRoom[chatId] ?? []);
      return true;
    }

    _markFailed(chatId, tempId);
    return false;
  }

  // ── Reactions (lokal saja) ─────────────────────────────────────────────────

  /// Toggle reaction pada sebuah pesan.
  /// Jika user sudah react emoji yang sama → hapus. Jika belum → tambah.
  Future<void> toggleReaction(
    int chatId,
    String messageId,
    String emoji,
    String myUserId,
  ) async {
    final msgs = _messagesByRoom[chatId];
    if (msgs == null) return;

    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final msg          = msgs[idx];
    final reactions    = List<MessageReaction>.from(msg.reactions);
    final emojiIdx     = reactions.indexWhere((r) => r.emoji == emoji);

    if (emojiIdx == -1) {
      // Tambah reaction baru
      reactions.add(MessageReaction(emoji: emoji, userIds: [myUserId]));
    } else {
      final r       = reactions[emojiIdx];
      final userIds = List<String>.from(r.userIds);
      if (userIds.contains(myUserId)) {
        userIds.remove(myUserId);
        if (userIds.isEmpty) {
          reactions.removeAt(emojiIdx);
        } else {
          reactions[emojiIdx] = r.copyWith(userIds: userIds);
        }
      } else {
        reactions[emojiIdx] = r.copyWith(userIds: [...userIds, myUserId]);
      }
    }

    final updated  = msg.copyWith(reactions: reactions);
    final newMsgs  = List<ChatMessage>.from(msgs);
    newMsgs[idx]   = updated;
    _messagesByRoom[chatId] = newMsgs;

    // Simpan reactions ke lokal
    await _storage.saveReactions(chatId, messageId, reactions);

    notifyListeners();
  }

  // ── Mark as Read ───────────────────────────────────────────────────────────

  void markRoomAsRead(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    final newList = [..._rooms];
    newList[idx]  = newList[idx].copyWith(unreadCount: 0);
    _rooms        = newList;
    notifyListeners();
  }

  // ── Find or Create ─────────────────────────────────────────────────────────

  Future<int?> findOrCreateChat(int freelancerId, {int? taskId}) async {
    final res = await _svc.findOrCreateChat(
      freelancerId: freelancerId,
      taskId:       taskId,
    );
    if (res.success && res['data'] != null) {
      return (res['data']['id'] as int?) ??
             int.tryParse(res['data']['id'].toString());
    }
    _error = res.message;
    notifyListeners();
    return null;
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  void _updateLastId(int chatId, List<ChatMessage> msgs) {
    if (msgs.isEmpty) return;
    final ids = msgs
        .map((m) => int.tryParse(m.id) ?? 0)
        .where((id) => id > 0);
    if (ids.isNotEmpty) {
      _lastIdByRoom[chatId] = ids.reduce((a, b) => a > b ? a : b);
    }
  }

  void _markFailed(int chatId, String tempId) {
    final msgs = _messagesByRoom[chatId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.id == tempId);
    if (idx == -1) return;
    final newMsgs = List<ChatMessage>.from(msgs);
    newMsgs[idx]  = msgs[idx].copyWith(localStatus: LocalMessageStatus.failed);
    _messagesByRoom[chatId] = newMsgs;
    notifyListeners();
  }

  void _replaceTemp(int chatId, String tempId, ChatMessage confirmed) {
    final msgs = _messagesByRoom[chatId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.id == tempId);
    if (idx == -1) return;
    final newMsgs = List<ChatMessage>.from(msgs);
    newMsgs[idx]  = confirmed;
    _messagesByRoom[chatId] = newMsgs;
    _updateLastId(chatId, newMsgs);
    notifyListeners();
  }

  /// Inject reactions yang disimpan lokal ke list pesan
  Future<List<ChatMessage>> _injectReactions(
    int chatId,
    List<ChatMessage> messages,
  ) async {
    if (messages.isEmpty) return messages;
    final ids           = messages.map((m) => m.id).toList();
    final reactionsMap  = await _storage.loadAllReactions(chatId, ids);
    return messages.map((m) {
      final r = reactionsMap[m.id];
      if (r == null || r.isEmpty) return m;
      return m.copyWith(reactions: r);
    }).toList();
  }
}
