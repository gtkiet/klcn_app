// lib/services/payment_service.dart
//
// VNPay: đang sử dụng.
// MoMo:  comment out — bật lại khi có tài khoản doanh nghiệp MoMo.

import 'package:klcn_app/network/api_client.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ── VNPAY ────────────────────────────────────────────────────────
  /// POST /api/payments/vnpay/create/{bookingId}
  /// Trả về paymentUrl (String) — mở bằng url_launcher
  Future<String> createVnPayPayment(int bookingId) async {
    final res = await _api.post('/api/payments/vnpay/create/$bookingId');
    return res.raw<String>();
  }

  // ── MOMO (chưa dùng) ─────────────────────────────────────────────
  // Lỗi do chưa có tài khoản doanh nghiệp MoMo.
  // Thay thế createVnPayPayment bằng createMoMoPayment khi đã có tài khoản.
  //
  // /// POST /api/payments/momo/create/{bookingId}
  // /// Trả về paymentUrl (String) — mở bằng url_launcher
  // Future<String> createMoMoPayment(int bookingId) async {
  //   final res = await _api.post('/api/payments/momo/create/$bookingId');
  //   return res.raw<String>();
  // }
}