// lib/services/payment_service.dart
//
// Backend thực tế dùng VNPay cho tất cả thanh toán online.
// Endpoint duy nhất: POST /api/payments/vnpay/create/{bookingId}
//
// Endpoint này thông minh — tự detect context từ bookingStatus:
//   • statusId == 5 (PendingDeposit)  → charge depositAmount
//   • statusId == 2 (Confirmed)       → charge TotalAmount − ĐãCọc
//
// Response data: {
//   paymentUrl:       String   — redirect đến VNPay sandbox/prod
//   amountDue:        double   — số tiền thực tế sẽ charge (để hiển thị UI)
//   bookingStatus:    String
//   bookingStatusId:  int
// }
//
// Direct (walk-in): Staff dùng POST /api/bookings/{id}/payment — app không gọi.

import 'package:klcn_app/network/api_client.dart';

// ── VNPAY CREATE RESULT ───────────────────────────────────────────
// Response data{} của POST /api/payments/vnpay/create/{bookingId}
class VnPayCreateResult {
  final String paymentUrl;
  final double amountDue;
  final String bookingStatus;
  final int    bookingStatusId;

  const VnPayCreateResult({
    required this.paymentUrl,
    required this.amountDue,
    required this.bookingStatus,
    required this.bookingStatusId,
  });

  factory VnPayCreateResult.fromJson(Map<String, dynamic> json) =>
      VnPayCreateResult(
        paymentUrl:      json['paymentUrl']      as String,
        amountDue:       (json['amountDue'] as num).toDouble(),
        bookingStatus:   json['bookingStatus']    as String,
        bookingStatusId: json['bookingStatusId']  as int,
      );
}

// ── PAYMENT SERVICE ───────────────────────────────────────────────
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiClient.instance;

  // ── VNPAY ─────────────────────────────────────────────────────────
  /// POST /api/payments/vnpay/create/{bookingId}
  ///
  /// Gọi được ở cả 2 bước trong Flow 1:
  ///   - Lần 1: booking statusId == 5 → charge depositAmount
  ///   - Lần 2: booking statusId == 2 → charge phần còn lại
  ///
  /// Và trong Flow 2 (isFullPayment=true):
  ///   - Lần duy nhất: booking statusId == 2 → charge toàn bộ totalAmount
  ///
  /// SP backend tự tính amountDue — client không cần tính.
  /// Trả VnPayCreateResult để UI có thể hiển thị amountDue trước khi redirect.
  Future<VnPayCreateResult> createVnPayPayment(int bookingId) async {
    final res = await _api.post('/api/payments/vnpay/create/$bookingId');
    return res.item(VnPayCreateResult.fromJson);
  }
}