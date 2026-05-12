// // lib/services/payment_service.dart

// import '../models/booking.dart';
// import '../network/api_client.dart';

// class PaymentService {
//   PaymentService._();
//   static final instance = PaymentService._();
//   final _api = ApiClient.instance;
//   // ─────────────────────────────────────────────────────────────
//   // THANH TOÁN ONLINE
//   // POST /payments/online
//   // ─────────────────────────────────────────────────────────────

//   Future<String> createOnlinePayment({
//     required int bookingId,
//     required PaymentMethod method,
//     required double amount,
//   }) async {
//     final methodStr = switch (method) {
//       PaymentMethod.vnpay => 'vnpay',

//       PaymentMethod.momo => 'momo',

//       PaymentMethod.transfer => 'transfer',

//       PaymentMethod.cash => 'cash',
//     };

//     final data = await _api.post('/payments/online', {
//       'booking_id': bookingId,
//       'method': methodStr,
//       'amount': amount,
//     });

//     return data['payment_url'] as String;
//   }

//   // ─────────────────────────────────────────────────────────────
//   // GHI NHẬN ĐẶT CỌC
//   // POST /payments/deposit
//   // ─────────────────────────────────────────────────────────────

//   Future<BookingModel> recordDeposit({
//     required int bookingId,
//     required double amount,
//     required PaymentMethod method,
//     String? transactionCode,
//   }) async {
//     final body = <String, dynamic>{
//       'booking_id': bookingId,

//       'amount': amount,

//       'method_id': method.index + 1,

//       if (transactionCode != null && transactionCode.isNotEmpty)
//         'transaction_code': transactionCode,
//     };

//     final data = await _api.post('/payments/deposit', body);

//     return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
//   }

//   // ─────────────────────────────────────────────────────────────
//   // THANH TOÁN FULL
//   // POST /payments/full
//   // ─────────────────────────────────────────────────────────────

//   Future<BookingModel> recordFullPayment({
//     required int bookingId,
//     required PaymentMethod method,
//     String? transactionCode,
//   }) async {
//     final body = <String, dynamic>{
//       'booking_id': bookingId,

//       'method_id': method.index + 1,

//       if (transactionCode != null && transactionCode.isNotEmpty)
//         'transaction_code': transactionCode,
//     };

//     final data = await _api.post('/payments/full', body);

//     return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
//   }

//   // ─────────────────────────────────────────────────────────────
//   // VERIFY CALLBACK
//   // POST /payments/callback/verify
//   // ─────────────────────────────────────────────────────────────

//   Future<Map<String, dynamic>> verifyCallback({
//     required String provider,
//     required Map<String, String> params,
//   }) async {
//     final data = await _api.post('/payments/callback/verify', {
//       'provider': provider,
//       'params': params,
//     });

//     return Map<String, dynamic>.from(data);
//   }

//   // ─────────────────────────────────────────────────────────────
//   // LỊCH SỬ THANH TOÁN
//   // GET /payments
//   // ─────────────────────────────────────────────────────────────

//   Future<List<PaymentModel>> getPayments(int bookingId) async {
//     final data = await _api.get(
//       '/payments',
//       params: {'booking_id': bookingId.toString()},
//     );

//     final list = data['data'] as List<dynamic>;

//     return list
//         .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
// }
