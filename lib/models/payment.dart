// lib/models/payment.dart
//
// Payment gateway models cho deep link result sau khi user thanh toán.
//
// Deep link scheme: sportplus://payment/result?status=success&bookingId=88
//                               hoặc     ?status=failed&bookingId=88
//
// MoMo:  đang hoạt động.
// VNPay: đã setup nhưng hiện tại chưa dùng — để lại để bật sau.

// ── PAYMENT METHOD IDs ────────────────────────────────────────────
// Dùng khi gọi POST /api/bookings/{id}/payment (manual payment by staff)
abstract class PaymentMethodId {
  static const int cash  = 1;
  static const int momo  = 2;
  static const int vnpay = 3;
}

// ── PAYMENT RESULT (từ deep link) ────────────────────────────────
// Parse từ deep link query params khi gateway redirect về app
class PaymentDeepLinkResult {
  final int bookingId;
  final bool isSuccess;

  const PaymentDeepLinkResult({
    required this.bookingId,
    required this.isSuccess,
  });

  /// Parse từ Uri của deep link
  /// sportplus://payment/result?status=success&bookingId=88
  factory PaymentDeepLinkResult.fromUri(Uri uri) {
    final bookingId = int.tryParse(uri.queryParameters['bookingId'] ?? '') ?? 0;
    final status    = uri.queryParameters['status'] ?? '';
    return PaymentDeepLinkResult(
      bookingId: bookingId,
      isSuccess: status == 'success',
    );
  }
}

// ── MOMO ──────────────────────────────────────────────────────────
// POST /api/payments/momo/create/{bookingId}
// Response data: String (paymentUrl) — không cần model riêng
// Service trả trực tiếp String

// ── VNPAY (chưa dùng) ────────────────────────────────────────────
// POST /api/payments/vnpay/create/{bookingId}
// Response data: String (paymentUrl) — không cần model riêng
// Uncomment PaymentService.createVnPayPayment() khi backend VNPay ổn định