// lib/services/booking_service.dart

import 'package:klcn_app/models/booking.dart';
import 'package:klcn_app/models/service.dart';
import 'package:klcn_app/models/promotion.dart';
import 'package:klcn_app/network/api_client.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _api = ApiClient.instance;

  // ── HOLD SLOTS ─────────────────────────────────────────────────
  /// POST /api/bookings/hold
  /// Body: { fieldSlotIds: [int] }
  /// Giữ slot tạm thời (status = PendingPayment) trước khi tạo booking chính thức
  Future<void> holdSlots(List<int> fieldSlotIds) async {
    await _api.post('/api/bookings/hold', body: {'fieldSlotIds': fieldSlotIds});
  }

  // ── CREATE BOOKING ─────────────────────────────────────────────
  /// POST /api/bookings
  /// Body: { fieldSlotIds, services?, promotionCode?, note? }
  /// Trả về BookingModel đầy đủ kèm deposit info
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
        if (services.isNotEmpty)
          'services': services.map((s) => s.toJson()).toList(),
        if (promotionCode != null && promotionCode.trim().isNotEmpty)
          'promotionCode': promotionCode.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return res.item(BookingModel.fromJson);
  }

  // ── GET MY BOOKINGS ────────────────────────────────────────────
  /// GET /api/bookings/my
  /// Params: statusId?, page, pageSize
  Future<PagedBookingResult> getMyBookings({
    int? statusId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final res = await _api.get(
      '/api/bookings/my',
      queryParameters: {
        'statusId': ?statusId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return res.item(PagedBookingResult.fromJson);
  }

  // ── GET BOOKING DETAIL ─────────────────────────────────────────
  /// GET /api/bookings/{bookingId}
  Future<BookingModel> getBookingDetail(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId');
    return res.item(BookingModel.fromJson);
  }

  // ── CANCEL BOOKING ─────────────────────────────────────────────
  /// POST /api/bookings/{bookingId}/cancel
  /// Body: { reason? }
  Future<void> cancelBooking({required int bookingId, String? reason}) async {
    await _api.post(
      '/api/bookings/$bookingId/cancel',
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  // ── RESCHEDULE ─────────────────────────────────────────────────
  /// POST /api/bookings/{bookingId}/reschedule
  /// Body: { bookingDetailId, newFieldSlotId }
  Future<void> reschedule({
    required int bookingId,
    required int bookingDetailId,
    required int newFieldSlotId,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/reschedule',
      body: {
        'bookingDetailId': bookingDetailId,
        'newFieldSlotId': newFieldSlotId,
      },
    );
  }

  // ── APPLY VOUCHER ──────────────────────────────────────────────
  /// POST /api/bookings/{bookingId}/apply-voucher
  /// Body: { code }
  Future<void> applyVoucher({
    required int bookingId,
    required String code,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/apply-voucher',
      body: {'code': code.trim()},
    );
  }

  // ── GET PAYMENTS ───────────────────────────────────────────────
  /// GET /api/bookings/{bookingId}/payments
  Future<List<PaymentModel>> getPayments(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/payments');
    return res.list(PaymentModel.fromJson);
  }

  // ── GET DEPOSIT ────────────────────────────────────────────────
  /// GET /api/bookings/{bookingId}/deposit
  Future<DepositModel> getDeposit(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/deposit');
    return res.item(DepositModel.fromJson);
  }

  // ── GET SERVICES ───────────────────────────────────────────────
  /// GET /api/services
  /// Params: isAvailable?
  Future<List<ServiceModel>> getServices({bool? isAvailable}) async {
    final res = await _api.get(
      '/api/services',
      queryParameters: {'isAvailable': ?isAvailable},
    );
    return res.list(ServiceModel.fromJson);
  }

  // ── GET PROMOTION ──────────────────────────────────────────────
  /// GET /api/promotions/{code}
  Future<PromotionModel> getPromotion(String code) async {
    final res = await _api.get('/api/promotions/${code.trim()}');
    return res.item(PromotionModel.fromJson);
  }
}
