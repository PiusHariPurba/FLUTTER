import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// HTTP client utama — menangani semua request ke Laravel API.
/// Otomatis attach Bearer token dari SharedPreferences ke setiap request.
/// Semua method return [ApiResponse] yang wrap success/error secara konsisten.
class ApiClient {
  // Singleton instance — satu ApiClient untuk seluruh app
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  // Key untuk menyimpan token di SharedPreferences
  static const _tokenKey = 'auth_token';

  // ─── Token Management ─────────────────────────────────────

  /// Simpan token setelah login/register berhasil
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Ambil token yang tersimpan (null jika belum login)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Hapus token saat logout
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Cek apakah user sudah login (ada token tersimpan)
  Future<bool> get isAuthenticated async => (await getToken()) != null;

  // ─── HTTP Methods ─────────────────────────────────────────

  /// GET request ke [path] dengan optional [queryParams]
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    // Bangun URI dengan query parameters
    final uri = _buildUri(path, queryParams);
    try {
      // Kirim request dengan headers (termasuk Bearer token)
      final response = await http.get(uri, headers: await _headers())
          .timeout(AppConfig.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request ke [path] dengan [body] data
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(AppConfig.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT request ke [path] dengan [body] data
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(AppConfig.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request ke [path]
  Future<ApiResponse> delete(String path) async {
    final uri = _buildUri(path);
    try {
      final response = await http.delete(uri, headers: await _headers())
          .timeout(AppConfig.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Multipart POST untuk upload file
  Future<ApiResponse> uploadFile(String path, String filePath, {String field = 'file'}) async {
    final uri = _buildUri(path);
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(field, filePath));
      final headers = await _headers();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      final streamed = await request.send().timeout(AppConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Upload file dengan field-field form tambahan (misal: type, offer_id).
  /// Dipakai untuk avatar upload, work_result, dll.
  Future<ApiResponse> uploadFileWithFields(
    String path,
    String filePath, {
    String fileField = 'file',
    Map<String, String> fields = const {},
  }) async {
    final uri = _buildUri(path);
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      request.fields.addAll(fields);
      final headers = await _headers();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      final streamed = await request.send().timeout(AppConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─── Internal Helpers ─────────────────────────────────────

  /// Bangun URI dari base URL + path + query params
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    // Pastikan path dimulai dengan '/' tapi base URL tidak diakhiri '/'
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final fullPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$fullPath').replace(queryParameters: queryParams);
  }

  /// Buat headers standar — Content-Type JSON + Bearer token (jika ada)
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // Attach token jika sudah login
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Parse response dari server ke ApiResponse
  ApiResponse _handleResponse(http.Response response) {
    // Coba parse body sebagai JSON
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {'raw': response.body};
    }

    // Status 2xx = success
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        statusCode: response.statusCode,
        data: data,
        message: data is Map ? (data['message'] as String?) : null,
      );
    }

    // Status 401 = Unauthorized (token expired / invalid)
    if (response.statusCode == 401) {
      clearToken(); // Auto-clear token yang expired
    }

    // Error response
    String errorMsg = 'Terjadi kesalahan.';
    if (data is Map) {
      errorMsg = data['message'] ?? errorMsg;
      // Laravel validation errors
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          errorMsg = firstError.first.toString();
        }
      }
    }

    return ApiResponse(
      success: false,
      statusCode: response.statusCode,
      data: data,
      message: errorMsg,
    );
  }

  /// Handle exception (timeout, no internet, dll)
  ApiResponse _handleError(dynamic error) {
    String msg;
    if (error is TimeoutException) {
      msg = 'Koneksi timeout. Periksa jaringan Anda.';
    } else if (error.toString().contains('SocketException') ||
               error.toString().contains('Connection refused')) {
      msg = 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
    } else {
      msg = 'Terjadi kesalahan jaringan: ${error.toString()}';
    }
    return ApiResponse(success: false, statusCode: 0, data: null, message: msg);
  }
}

/// Wrapper response API — konsisten untuk semua endpoint.
/// [success] true jika status 2xx, [data] berisi JSON response,
/// [message] berisi pesan dari server (sukses atau error).
class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? message;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  /// Shortcut untuk ambil data dari response
  /// Misal: response.get('user') -> data['user']
  dynamic operator [](String key) => data is Map ? data[key] : null;

  @override
  String toString() => 'ApiResponse(success=$success, status=$statusCode, msg=$message)';
}
