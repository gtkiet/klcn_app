// lib/services/booking_service.dart
// Ánh xạ toàn bộ Booking + Payment + MoMo API

import '../models/booking.dart';
import '../models/service.dart';
import '../models/promotion.dart';
import '../network/api_client.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _api = ApiClient.instance;

  // ─────────────────────────────────────────────────────────────
  // GIỮ SLOT — POST /api/bookings/hold
  // Body: { fieldSlotIds: [int] }
  // Response data: String (hold session token hoặc message)
  // ─────────────────────────────────────────────────────────────

  Future<String> holdSlots(List<int> fieldSlotIds) async {
    final res = await _api.post(
      '/api/bookings/hold',
      body: {'fieldSlotIds': fieldSlotIds},
    );
    return res.raw<String>();
  }

  // ─────────────────────────────────────────────────────────────
  // TẠO BOOKING — POST /api/bookings
  // Body: { fieldSlotIds, services?, promotionCode?, note? }
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel> createBooking({
    required List<int> fieldSlotIds,
    List<ServiceRequestItem> services = const [],
    String? promotionCode,
    String? note,
  }) async {
    final res = await _api.post(
      '/api/bookings',
      body: {
        'fieldSlotIds': fieldSlotIds,
        if (services.isNotEmpty) 'services': services.map((s) => s.toJson()).toList(),
        if (promotionCode != null && promotionCode.isNotEmpty)
          'promotionCode': promotionCode,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return res.item(BookingModel.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // LỊCH SỬ BOOKING — GET /api/bookings/my
  // Parameters: statusId?, page, pageSize
  // ─────────────────────────────────────────────────────────────

  Future<PagedBookingResult> getMyBookings({
    int? statusId,
    int page     = 1,
    int pageSize = 10,
  }) async {
    final res = await _api.get(
      '/api/bookings/my',
      queryParameters: {
        'statusId': ?statusId,
        'page':     page,
        'pageSize': pageSize,
      },
    );
    return res.item(PagedBookingResult.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // CHI TIẾT BOOKING — GET /api/bookings/{bookingId}
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel> getBookingDetail(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId');
    return res.item(BookingModel.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // HỦY BOOKING — POST /api/bookings/{bookingId}/cancel
  // Body: { reason? }
  // Response data: String
  // ─────────────────────────────────────────────────────────────

  Future<void> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/cancel',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỔI LỊCH — POST /api/bookings/{bookingId}/reschedule
  // Body: { bookingDetailId, newFieldSlotId }
  // Response data: String
  // ─────────────────────────────────────────────────────────────

  Future<void> reschedule({
    required int bookingId,
    required int bookingDetailId,
    required int newFieldSlotId,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/reschedule',
      body: {
        'bookingDetailId': bookingDetailId,
        'newFieldSlotId':  newFieldSlotId,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ÁP DỤNG VOUCHER — POST /api/bookings/{bookingId}/apply-voucher
  // Body: { code }
  // Response data: String
  // ─────────────────────────────────────────────────────────────

  Future<void> applyVoucher({
    required int bookingId,
    required String code,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/apply-voucher',
      body: {'code': code.trim()},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // THANH TOÁN — POST /api/bookings/{bookingId}/payment
  // Body: { methodId, transactionCode?, note? }
  // methodId: 1=Cash | 2=Transfer | 3=MoMo (tuỳ server định nghĩa)
  // Response data: String
  // ─────────────────────────────────────────────────────────────

  Future<void> submitPayment({
    required int bookingId,
    required int methodId,
    String? transactionCode,
    String? note,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/payment',
      body: {
        'methodId': methodId,
        if (transactionCode != null && transactionCode.isNotEmpty)
          'transactionCode': transactionCode,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LỊCH SỬ THANH TOÁN — GET /api/bookings/{bookingId}/payments
  // ─────────────────────────────────────────────────────────────

  Future<List<PaymentModel>> getPayments(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/payments');
    return res.list(PaymentModel.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // THÔNG TIN ĐẶT CỌC — GET /api/bookings/{bookingId}/deposit
  // ─────────────────────────────────────────────────────────────

  Future<DepositModel> getDeposit(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/deposit');
    return res.item(DepositModel.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // MOMO — POST /api/payments/momo/create/{bookingId}
  // Response data: String (payment URL)
  // ─────────────────────────────────────────────────────────────

  Future<String> createMoMoPayment(int bookingId) async {
    final res = await _api.post('/api/payments/momo/create/$bookingId');
    return res.raw<String>();
  }

  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH DỊCH VỤ — GET /api/services
  // ─────────────────────────────────────────────────────────────

  Future<List<ServiceModel>> getServices({bool? isAvailable}) async {
    final res = await _api.get(
      '/api/services',
      queryParameters: {
        'isAvailable': ?isAvailable,
      },
    );
    return res.list(ServiceModel.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // KIỂM TRA VOUCHER — GET /api/promotions/{code}
  // ─────────────────────────────────────────────────────────────

  Future<PromotionModel> getPromotion(String code) async {
    final res = await _api.get('/api/promotions/${code.trim()}');
    return res.item(PromotionModel.fromJson);
  }
}