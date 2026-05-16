// lib/services/booking_service.dart

import '../models/booking.dart';
import '../models/service.dart';
import '../models/promotion.dart';
import '../network/api_client.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _api = ApiClient.instance;

  // POST /api/bookings/hold
  Future<String> holdSlots(List<int> fieldSlotIds) async {
    final res = await _api.post(
      '/api/bookings/hold',
      body: {'fieldSlotIds': fieldSlotIds},
    );
    return res.raw<String>();
  }

  // POST /api/bookings
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
        if (promotionCode != null && promotionCode.isNotEmpty)
          'promotionCode': promotionCode,
        if (note != null && note.trim().isNotEmpty)
          'note': note.trim(),
      },
    );
    return res.item(BookingModel.fromJson);
  }

  // GET /api/bookings/my
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

  // GET /api/bookings/{bookingId}
  Future<BookingModel> getBookingDetail(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId');
    return res.item(BookingModel.fromJson);
  }

  // POST /api/bookings/{bookingId}/cancel
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

  // POST /api/bookings/{bookingId}/reschedule
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

  // POST /api/bookings/{bookingId}/apply-voucher
  Future<void> applyVoucher({
    required int bookingId,
    required String code,
  }) async {
    await _api.post(
      '/api/bookings/$bookingId/apply-voucher',
      body: {'code': code.trim()},
    );
  }

  // POST /api/bookings/{bookingId}/payment
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
        if (note != null && note.trim().isNotEmpty)
          'note': note.trim(),
      },
    );
  }

  // GET /api/bookings/{bookingId}/payments
  Future<List<PaymentModel>> getPayments(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/payments');
    return res.list(PaymentModel.fromJson);
  }

  // GET /api/bookings/{bookingId}/deposit
  Future<DepositModel> getDeposit(int bookingId) async {
    final res = await _api.get('/api/bookings/$bookingId/deposit');
    return res.item(DepositModel.fromJson);
  }

  // POST /api/payments/momo/create/{bookingId}
  Future<String> createMoMoPayment(int bookingId) async {
    final res = await _api.post('/api/payments/momo/create/$bookingId');
    return res.raw<String>();
  }

  // GET /api/services
  Future<List<ServiceModel>> getServices({bool? isAvailable}) async {
    final res = await _api.get(
      '/api/services',
      queryParameters: {
        'isAvailable': ?isAvailable,
      },
    );
    return res.list(ServiceModel.fromJson);
  }

  // GET /api/promotions/{code}
  Future<PromotionModel> getPromotion(String code) async {
    final res = await _api.get('/api/promotions/${code.trim()}');
    return res.item(PromotionModel.fromJson);
  }
}