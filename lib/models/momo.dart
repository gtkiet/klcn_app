// lib/models/momo.dart
// Ánh xạ MoMo payment flow:
//   POST /api/payments/momo/create/{bookingId}
//   GET  /api/payments/momo/return?orderId=&resultCode=
//
// Backend redirect sau khi MoMo return:
//   resultCode == 0  → yourfrontend.com/booking/{bookingId}/success
//   resultCode != 0  → yourfrontend.com/booking/{bookingId}/failed
//
// Trong app mobile: dùng deep link (custom scheme) thay vì URL web.
// Ví dụ: sportplus://booking/{bookingId}/success
//         sportplus://booking/{bookingId}/failed
//
// Backend cần đổi redirect URL thành deep link của app:
//   var frontendUrl = resultCode == 0
//       ? $"sportplus://booking/{bookingId}/success"
//       : $"sportplus://booking/{bookingId}/failed";
//
// Sau đó app lắng nghe deep link qua package app_links hoặc uni_links.

// ── MOMO PAYMENT RESULT ───────────────────────────────────────────
// Parse từ deep link query params khi MoMo redirect về app
class MoMoReturnResult {
  final int bookingId;
  final bool isSuccess; // resultCode == 0

  const MoMoReturnResult({required this.bookingId, required this.isSuccess});
}

// ── MOMO CREATE RESPONSE ──────────────────────────────────────────
// data của POST /api/payments/momo/create/{bookingId} là String (payment URL)
// Không cần model riêng — BookingService.createMoMoPayment() trả về String
