import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../config/app_config.dart';
import '../providers/notification_provider.dart';

/// Realtime polling service — sinkronisasi data antara Flutter dan Laravel.
///
/// Polling schedule:
///   • Chat unread count  : setiap 5 detik  (chatPollInterval)
///   • Task updates       : setiap 15 detik (taskPollInterval)
///   • Notifikasi unread  : setiap 15 detik (bersama task polling)
class RealtimeService extends ChangeNotifier {
  // Singleton
  static final RealtimeService _instance = RealtimeService._();
  factory RealtimeService() => _instance;
  RealtimeService._();

  final _api = ApiClient();

  // Timers
  Timer? _chatTimer;
  Timer? _taskTimer;

  // State publik
  bool _hasNewMessages = false;
  bool _hasTaskUpdates = false;
  int  _totalUnreadChats = 0;

  // Timestamp delta‑check
  DateTime? _lastChatCheck;
  DateTime? _lastTaskCheck;

  // Referensi ke NotificationProvider (di-inject saat startPolling)
  NotificationProvider? _notificationProvider;

  // ── Getters ───────────────────────────────────────────────────

  bool get hasNewMessages   => _hasNewMessages;
  bool get hasTaskUpdates   => _hasTaskUpdates;
  int  get totalUnreadChats => _totalUnreadChats;

  // ── Start / Stop ──────────────────────────────────────────────

  /// Mulai polling. Panggil setelah login berhasil.
  /// [notificationProvider] opsional — jika diisi, unread notif ikut di-poll.
  void startPolling({NotificationProvider? notificationProvider}) {
    stopPolling();

    _notificationProvider = notificationProvider;

    // Chat: setiap 5 detik
    _chatTimer = Timer.periodic(
      AppConfig.chatPollInterval,
      (_) => _pollChats(),
    );

    // Task + Notifikasi: setiap 15 detik
    _taskTimer = Timer.periodic(
      AppConfig.taskPollInterval,
      (_) => _pollTasksAndNotifications(),
    );

    debugPrint(
      '[Realtime] Polling started: '
      'chat=${AppConfig.chatPollInterval.inSeconds}s, '
      'task=${AppConfig.taskPollInterval.inSeconds}s',
    );
  }

  /// Inject NotificationProvider dari ProxyProvider di main.dart.
  /// Dipanggil setiap kali NotificationProvider rebuild (provider pattern).
  void injectNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  /// Stop semua polling — panggil saat logout.
  void stopPolling() {
    _chatTimer?.cancel();
    _taskTimer?.cancel();
    _chatTimer            = null;
    _taskTimer            = null;
    _hasNewMessages       = false;
    _hasTaskUpdates       = false;
    _totalUnreadChats     = 0;
    _notificationProvider = null;
    debugPrint('[Realtime] Polling stopped');
  }

  /// Paksa refresh sekarang — berguna setelah aksi user (misal kirim pesan)
  Future<void> forceRefresh() async {
    await Future.wait([_pollChats(), _pollTasksAndNotifications()]);
  }

  // ── Clear Flags ───────────────────────────────────────────────

  void clearNewMessages() {
    _hasNewMessages = false;
    notifyListeners();
  }

  void clearTaskUpdates() {
    _hasTaskUpdates = false;
    notifyListeners();
  }

  // ── Private Polling ───────────────────────────────────────────

  Future<void> _pollChats() async {
    try {
      final res = await _api.get('/chats');
      if (!res.success) return;

      final chats = res['data'] as List? ?? [];
      int totalUnread = 0;
      for (final chat in chats) {
        totalUnread += (chat['unread_count'] ?? 0) as int;
      }

      if (totalUnread != _totalUnreadChats) {
        _totalUnreadChats = totalUnread;
        _hasNewMessages   = totalUnread > 0;
        notifyListeners();
        debugPrint('[Realtime] Chat update: $totalUnread unread');
      }

      _lastChatCheck = DateTime.now();
    } catch (e) {
      debugPrint('[Realtime] Chat poll error: $e');
    }
  }

  Future<void> _pollTasksAndNotifications() async {
    await Future.wait([
      _pollTasks(),
      _pollNotifications(),
    ]);
  }

  Future<void> _pollTasks() async {
    try {
      final res = await _api.get('/tasks', queryParams: {'per_page': '50'});
      if (!res.success) return;

      if (_lastTaskCheck != null) {
        final tasks = res['data']?['data'] as List? ?? [];
        for (final task in tasks) {
          final updatedAt = DateTime.tryParse(task['updated_at'] ?? '');
          if (updatedAt != null && updatedAt.isAfter(_lastTaskCheck!)) {
            _hasTaskUpdates = true;
            notifyListeners();
            debugPrint('[Realtime] Task update: ${task["title"]}');
            break;
          }
        }
      }

      _lastTaskCheck = DateTime.now();
    } catch (e) {
      debugPrint('[Realtime] Task poll error: $e');
    }
  }

  /// Poll jumlah notifikasi belum dibaca — update NotificationProvider
  Future<void> _pollNotifications() async {
    if (_notificationProvider == null) return;
    try {
      await _notificationProvider!.fetchUnreadCount();
    } catch (e) {
      debugPrint('[Realtime] Notif poll error: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
