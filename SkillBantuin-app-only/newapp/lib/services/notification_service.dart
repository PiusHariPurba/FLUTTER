import 'api_client.dart';

class NotificationService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _client.get('/notifications');
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return response.data ?? {};
  }

  Future<void> markAsRead(int id) async {
    await _client.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _client.post('/notifications/read-all');
  }
}