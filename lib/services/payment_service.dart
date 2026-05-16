// lib/services/payment_service.dart
//
// MoMo:  hoạt động bình thường.
// VNPay: tạo sẵn nhưng comment out — bật lại khi backend ổn định.

import 'package:klcn_app/network/api_client.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ── MOMO ────────────────────────────────────────────────────────
  /// POST /api/payments/momo/create/{bookingId}
  /// Trả về paymentUrl (String) — mở bằng url_launcher
  Future<String> createMoMoPayment(int bookingId) async {
    final res = await _api.post('/api/payments/momo/create/$bookingId');
    return res.raw<String>();
  }

  // ── VNPAY (chưa dùng) ──────────────────────────────────────────
  // /// POST /api/payments/vnpay/create/{bookingId}
  // /// Trả về paymentUrl (String) — mở bằng url_launcher
  // Future<String> createVnPayPayment(int bookingId) async {
  //   final res = await _api.post('/api/payments/vnpay/create/$bookingId');
  //   return res.raw<String>();
  // }
}