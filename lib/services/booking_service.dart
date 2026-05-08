// lib/services/booking_service.dart
// Kết nối API đặt sân: tạo booking, giữ slot, xác nhận, hủy, đổi lịch
// Tương ứng SP: sp_HoldSlots, sp_ConfirmBooking, sp_CancelBooking,
//               sp_RescheduleBooking, sp_ApplyPromotion
// View: vw_BookingHistory, vw_PendingDeposits

import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  // ── GIỮ SLOT (Bước 1 của luồng đặt sân) ──────────────────────
  // POST /bookings/hold
  // Gọi sp_HoldSlots → trả về bookingId tạm thời
  static Future<int> holdSlots({
    required List<int> fieldSlotIds,
  }) async {
    final data = await ApiClient.post('/bookings/hold', {
      'field_slot_ids': fieldSlotIds,
    });
    return data['booking_id'] as int;
  }

  // ── XÁC NHẬN BOOKING (Bước 2) ─────────────────────────────────
  // POST /bookings/{id}/confirm
  // Gọi sp_ConfirmBooking → trả về booking đầy đủ
  static Future<BookingModel> confirmBooking({
    required int bookingId,
    required List<int> fieldSlotIds,
    required bool isFullPayment,
    List<Map<String, dynamic>>? services, // [{service_id, quantity}]
    String? promotionCode,
  }) async {
    final body = <String, dynamic>{
      'field_slot_ids':  fieldSlotIds,
      'is_full_payment': isFullPayment,
      'services':       ?services,
      'promotion_code': ?promotionCode,
    };
    final data = await ApiClient.post('/bookings/$bookingId/confirm', body);
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── ÁP DỤNG VOUCHER ──────────────────────────────────────────
  // POST /bookings/{id}/apply-promotion
  // Gọi sp_ApplyPromotion
  static Future<BookingModel> applyPromotion({
    required int bookingId,
    required String code,
  }) async {
    final data = await ApiClient.post(
      '/bookings/$bookingId/apply-promotion',
      {'code': code},
    );
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── LỊCH SỬ BOOKING ───────────────────────────────────────────
  // GET /bookings?status_id=&page=&per_page=
  // Từ vw_BookingHistory
  static Future<List<BookingModel>> getBookingHistory({
    int? statusId,
    int page    = 1,
    int perPage = 10,
  }) async {
    final params = <String, String>{
      'page':     page.toString(),
      'per_page': perPage.toString(),
      if (statusId != null) 'status_id': statusId.toString(),
    };
    final data = await ApiClient.get('/bookings', params: params);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── CHI TIẾT BOOKING ──────────────────────────────────────────
  // GET /bookings/{id}
  static Future<BookingModel> getBookingDetail(int bookingId) async {
    final data = await ApiClient.get('/bookings/$bookingId');
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── HỦY BOOKING ──────────────────────────────────────────────
  // POST /bookings/{id}/cancel
  // Gọi sp_CancelBooking (kiểm tra MIN_CANCEL_BEFORE_HOURS)
  static Future<BookingModel> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    final data = await ApiClient.post(
      '/bookings/$bookingId/cancel',
      {'reason': reason ?? ''},
    );
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── ĐỔI LỊCH ─────────────────────────────────────────────────
  // POST /bookings/details/{detailId}/reschedule
  // Gọi sp_RescheduleBooking (kiểm tra MIN_RESCHEDULE_BEFORE_HOURS)
  static Future<BookingModel> reschedule({
    required int bookingDetailId,
    required int newFieldSlotId,
  }) async {
    final data = await ApiClient.post(
      '/bookings/details/$bookingDetailId/reschedule',
      {'new_field_slot_id': newFieldSlotId},
    );
    return BookingModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── DANH SÁCH DỊCH VỤ ─────────────────────────────────────────
  // GET /services
  static Future<List<ServiceModel>> getServices() async {
    final data = await ApiClient.get('/services');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
