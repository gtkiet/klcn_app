// lib/services/booking_service.dart

import '../models/booking.dart';
import '../network/api_client.dart';

class BookingService {
  BookingService._();
  static final instance = BookingService._();
  final _api = ApiClient.instance;
  // ─────────────────────────────────────────────────────────────
  // GIỮ SLOT
  // POST /bookings/hold
  // ─────────────────────────────────────────────────────────────

  Future<int> holdSlots({
    required List<int> fieldSlotIds,
  }) async {
    final data = await _api.post(
      '/bookings/hold',
      {
        'field_slot_ids':
            fieldSlotIds,
      },
    );

    return data['booking_id'] as int;
  }

  // ─────────────────────────────────────────────────────────────
  // XÁC NHẬN BOOKING
  // POST /bookings/{id}/confirm
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel>
      confirmBooking({
    required int bookingId,
    required List<int> fieldSlotIds,
    required bool isFullPayment,

    // [{service_id, quantity}]
    List<Map<String, dynamic>>?
        services,

    String? promotionCode,
  }) async {
    final body = <String, dynamic>{
      'field_slot_ids':
          fieldSlotIds,

      'is_full_payment':
          isFullPayment,

      'services': ?services,

      if (promotionCode != null &&
          promotionCode.isNotEmpty)
        'promotion_code':
            promotionCode,
    };

    final data = await _api.post(
      '/bookings/$bookingId/confirm',
      body,
    );

    return BookingModel.fromJson(
      data['data']
          as Map<String, dynamic>,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ÁP DỤNG VOUCHER
  // POST /bookings/{id}/apply-promotion
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel>
      applyPromotion({
    required int bookingId,
    required String code,
  }) async {
    final data = await _api.post(
      '/bookings/$bookingId/apply-promotion',
      {
        'code': code,
      },
    );

    return BookingModel.fromJson(
      data['data']
          as Map<String, dynamic>,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LỊCH SỬ BOOKING
  // GET /bookings
  // ─────────────────────────────────────────────────────────────

  Future<List<BookingModel>>
      getBookingHistory({
    int? statusId,
    int page = 1,
    int perPage = 10,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),

      'per_page':
          perPage.toString(),

      if (statusId != null)
        'status_id':
            statusId.toString(),
    };

    final data = await _api.get(
      '/bookings',
      params: params,
    );

    final list =
        data['data'] as List<dynamic>;

    return list
        .map(
          (e) => BookingModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // CHI TIẾT BOOKING
  // GET /bookings/{id}
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel>
      getBookingDetail(
    int bookingId,
  ) async {
    final data = await _api.get(
      '/bookings/$bookingId',
    );

    return BookingModel.fromJson(
      data['data']
          as Map<String, dynamic>,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HỦY BOOKING
  // POST /bookings/{id}/cancel
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel>
      cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    final body = {
      'reason': ?reason,
    };

    final data = await _api.post(
      '/bookings/$bookingId/cancel',
      body,
    );

    return BookingModel.fromJson(
      data['data']
          as Map<String, dynamic>,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỔI LỊCH
  // POST /bookings/details/{detailId}/reschedule
  // ─────────────────────────────────────────────────────────────

  Future<BookingModel>
      reschedule({
    required int bookingDetailId,
    required int newFieldSlotId,
  }) async {
    final data = await _api.post(
      '/bookings/details/$bookingDetailId/reschedule',
      {
        'new_field_slot_id':
            newFieldSlotId,
      },
    );

    return BookingModel.fromJson(
      data['data']
          as Map<String, dynamic>,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH DỊCH VỤ
  // GET /services
  // ─────────────────────────────────────────────────────────────

  Future<List<ServiceModel>>
      getServices() async {
    final data = await _api.get(
      '/services',
    );

    final list =
        data['data'] as List<dynamic>;

    return list
        .map(
          (e) => ServiceModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}