// lib/services/payment_service.dart
//
// Theo Enums.cs — PaymentMethodEnum chỉ có 2 loại:
//   Direct (1): Trực tiếp tại quầy — Staff dùng, app không cần gọi
//   MoMo   (2): Bắt buộc dùng để đặt cọc online
//
// VNPay KHÔNG tồn tại trong hệ thống backend này.

import 'package:klcn_app/network/api_client.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ── MOMO ──────────────────────────────────────────────────────────
  /// POST /api/payments/momo/create/{bookingId}
  /// Trả về paymentUrl (String) — mở bằng url_launcher
  /// Bắt buộc dùng để đặt cọc, booking mới được Confirmed
  Future<String> createMoMoPayment(int bookingId) async {
    final res = await _api.post('/api/payments/momo/create/$bookingId');
    return res.raw<String>();
  }
}