import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationItem {
  final dynamic id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['read_at'] != null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Fetch All Notifications ─────────────────────────────────────────────────

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getNotifications();
      _notifications = (result['data'] as List? ?? [])
          .map((e) => NotificationItem.fromJson(e))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Unread Count ──────────────────────────────────────────────────────

  Future<void> fetchUnreadCount() async {
    try {
      final result = await _service.getUnreadCount();
      _unreadCount = result['count'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Mark Single As Read ─────────────────────────────────────────────────────

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationItem(
          id: old.id,
          type: old.type,
          title: old.title,
          body: old.body,
          data: old.data,
          isRead: true,
          createdAt: old.createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Mark All As Read ────────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _notifications = _notifications.map((n) => NotificationItem(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Clear ───────────────────────────────────────────────────────────────────

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _error = null;
    notifyListeners();
  }
}