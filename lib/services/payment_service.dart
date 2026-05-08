// lib/services/payment_service.dart
// Kết nối API thanh toán: đặt cọc, thanh toán đủ, VNPay, MoMo
// Tương ứng SP: sp_RecordDeposit, sp_RecordFullPayment
// Bảng: Payments, Deposits

import '../models/booking.dart';
import 'api_client.dart';

class PaymentService {
  // ── THANH TOÁN ONLINE (VNPay / MoMo) ─────────────────────────
  // POST /payments/online
  // Backend tạo payment URL → app mở WebView / deep link
  static Future<String> createOnlinePayment({
    required int bookingId,
    required PaymentMethod method, // vnpay | momo
    required double amount,
  }) async {
    final methodStr = switch (method) {
      PaymentMethod.vnpay    => 'vnpay',
      PaymentMethod.momo     => 'momo',
      PaymentMethod.transfer => 'transfer',
      PaymentMethod.cash     => 'cash',
    };
    final data = await ApiClient.post('/payments/online', {
      'booking_id': bookingId,
      'method':     methodStr,
      'amount':     amount,
    });
    // Trả về URL để redirect (VNPay / MoMo)
    return data['payment_url'] as String;
  }

  // ── GHI NHẬN THANH TOÁN ĐẶT CỌC ─────────────────────────────
  // POST /payments/deposit
  // Gọi sp_RecordDeposit
  static Future<BookingModel> recordDeposit({
    required int bookingId,
    required double amount,
    required PaymentMethod method,
    String? transactionCode,
  }) async {
    final data = await ApiClient.post('/payments/deposit', {
      'booking_id':      bookingId,
      'amount':          amount,
      'method_id':       method.index + 1,
      'transaction_code': transactionCode,
    });
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── THANH TOÁN PHẦN CÒN LẠI ──────────────────────────────────
  // POST /payments/full
  // Gọi sp_RecordFullPayment
  static Future<BookingModel> recordFullPayment({
    required int bookingId,
    required PaymentMethod method,
    String? transactionCode,
  }) async {
    final data = await ApiClient.post('/payments/full', {
      'booking_id':       bookingId,
      'method_id':        method.index + 1,
      'transaction_code': transactionCode,
    });
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── XÁC NHẬN KẾT QUẢ CALLBACK (VNPay / MoMo) ────────────────
  // POST /payments/callback/verify
  // Backend kiểm tra chữ ký và cập nhật trạng thái payment
  static Future<Map<String, dynamic>> verifyCallback({
    required String provider,          // 'vnpay' | 'momo'
    required Map<String, String> params,
  }) async {
    final data = await ApiClient.post('/payments/callback/verify', {
      'provider': provider,
      'params':   params,
    });
    return data as Map<String, dynamic>;
  }

  // ── LỊCH SỬ THANH TOÁN ───────────────────────────────────────
  // GET /payments?booking_id=
  static Future<List<PaymentModel>> getPayments(int bookingId) async {
    final data = await ApiClient.get(
      '/payments',
      params: {'booking_id': bookingId.toString()},
    );
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
