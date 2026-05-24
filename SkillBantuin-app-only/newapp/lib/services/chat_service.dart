import 'api_client.dart';
import '../config/app_config.dart';

/// Service chat — menghubungkan ke Laravel /chats endpoints.
class ChatService {
  final _api = ApiClient();

  /// List semua chat rooms milik user — GET /chats
  Future<ApiResponse> getChats() async {
    return _api.get('/chats');
  }

  /// Ambil pesan dalam chat room — GET /chats/{id}/messages
  ///
  /// [afterId] opsional: jika diisi, server hanya return pesan dengan
  /// id > afterId (mode delta/polling). Jika 0 / null → mode paginated normal.
  Future<ApiResponse> getMessages(
    int chatId, {
    int page = 1,
    int perPage = AppConfig.chatMessagesPerPage,
    int afterId = 0,
  }) async {
    final params = <String, String>{
      'page':     page.toString(),
      'per_page': perPage.toString(),
    };
    if (afterId > 0) {
      params['after_id'] = afterId.toString();
    }
    return _api.get('/chats/$chatId/messages', queryParams: params);
  }

  /// Kirim pesan baru — POST /chats/{id}/messages
  Future<ApiResponse> sendMessage(
    int chatId, {
    String? body,
    String? attachment,
    String type = 'text',
  }) async {
    final data = <String, dynamic>{'type': type};
    if (body != null) data['body'] = body;
    if (attachment != null) data['attachment'] = attachment;
    return _api.post('/chats/$chatId/messages', body: data);
  }

  /// Buat atau dapatkan chat room — POST /chats
  Future<ApiResponse> findOrCreateChat({
    required int freelancerId,
    int? taskId,
  }) async {
    final body = <String, dynamic>{'freelancer_id': freelancerId};
    if (taskId != null) body['task_id'] = taskId;
    return _api.post('/chats', body: body);
  }

  /// Upload file/image — POST /upload
  Future<ApiResponse> uploadAttachment(String filePath) async {
    return _api.uploadFile('/upload', filePath, field: 'file');
  }
}
