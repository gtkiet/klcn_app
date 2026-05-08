// lib/services/payment_service.dart

import '../models/booking.dart';
import '../network/api_client.dart';

class PaymentService {
  // ─────────────────────────────────────────────────────────────
  // THANH TOÁN ONLINE
  // POST /payments/online
  // ─────────────────────────────────────────────────────────────

  static Future<String> createOnlinePayment({
    required int bookingId,
    required PaymentMethod method,
    required double amount,
  }) async {
    final methodStr = switch (method) {
      PaymentMethod.vnpay => 'vnpay',

      PaymentMethod.momo => 'momo',

      PaymentMethod.transfer => 'transfer',

      PaymentMethod.cash => 'cash',
    };

    final data = await ApiClient.post('/payments/online', {
      'booking_id': bookingId,
      'method': methodStr,
      'amount': amount,
    });

    return data['payment_url'] as String;
  }

  // ─────────────────────────────────────────────────────────────
  // GHI NHẬN ĐẶT CỌC
  // POST /payments/deposit
  // ─────────────────────────────────────────────────────────────

  static Future<BookingModel> recordDeposit({
    required int bookingId,
    required double amount,
    required PaymentMethod method,
    String? transactionCode,
  }) async {
    final body = <String, dynamic>{
      'booking_id': bookingId,

      'amount': amount,

      'method_id': method.index + 1,

      if (transactionCode != null && transactionCode.isNotEmpty)
        'transaction_code': transactionCode,
    };

    final data = await ApiClient.post('/payments/deposit', body);

    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────
  // THANH TOÁN FULL
  // POST /payments/full
  // ─────────────────────────────────────────────────────────────

  static Future<BookingModel> recordFullPayment({
    required int bookingId,
    required PaymentMethod method,
    String? transactionCode,
  }) async {
    final body = <String, dynamic>{
      'booking_id': bookingId,

      'method_id': method.index + 1,

      if (transactionCode != null && transactionCode.isNotEmpty)
        'transaction_code': transactionCode,
    };

    final data = await ApiClient.post('/payments/full', body);

    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFY CALLBACK
  // POST /payments/callback/verify
  // ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> verifyCallback({
    required String provider,
    required Map<String, String> params,
  }) async {
    final data = await ApiClient.post('/payments/callback/verify', {
      'provider': provider,
      'params': params,
    });

    return Map<String, dynamic>.from(data);
  }

  // ─────────────────────────────────────────────────────────────
  // LỊCH SỬ THANH TOÁN
  // GET /payments
  // ─────────────────────────────────────────────────────────────

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
