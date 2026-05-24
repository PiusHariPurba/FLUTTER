import 'api_client.dart';

/// Service payment — menghubungkan ke Laravel /payments endpoints.
/// Client: buat pembayaran untuk task.
/// Admin: verifikasi pembayaran via Web Admin panel.
class PaymentService {
  final _api = ApiClient();

  /// List semua pembayaran milik user — GET /payments
  Future<ApiResponse> getMyPayments() async {
    return _api.get('/payments');
  }

  /// Detail pembayaran untuk task — GET /tasks/{taskId}/payment
  Future<ApiResponse> getPayment(int taskId) async {
    return _api.get('/tasks/$taskId/payment');
  }

  /// Buat pembayaran baru — POST /tasks/{taskId}/payment
  Future<ApiResponse> createPayment(int taskId, {
    required double amount,
    required String method,
    String? notes,
  }) async {
    return _api.post('/tasks/$taskId/payment', body: {
      'amount': amount,
      'method': method,
      'notes': notes,
    });
  }
}
