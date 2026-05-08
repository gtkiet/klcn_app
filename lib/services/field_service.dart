// lib/services/field_service.dart
// Kết nối API sân bóng: danh sách sân, lịch slot, chi tiết
// Tương ứng: bảng Fields, FieldSlots, vw_FieldSchedule, vw_FieldRatings

import '../models/field.dart';
import 'api_client.dart';

class FieldService {
  // ── DANH SÁCH SÂN ─────────────────────────────────────────────
  // GET /fields?type_id=&status_id=1
  // Trả về Fields JOIN vw_FieldRatings
  static Future<List<FieldModel>> getFields({
    int? typeId,       // 1=Sân5, 2=Sân7
    String? keyword,
    String? sortBy,    // 'price_asc' | 'price_desc' | 'rating'
  }) async {
    final params = <String, String>{
      if (typeId  != null) 'type_id': typeId.toString(),
      'keyword': ?keyword,
      'sort_by': ?sortBy,
    };
    final data = await ApiClient.get('/fields', params: params);
    final list = data['data'] as List<dynamic>;
    return list.map((e) => FieldModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── CHI TIẾT SÂN ──────────────────────────────────────────────
  // GET /fields/{id}
  static Future<FieldModel> getFieldDetail(int fieldId) async {
    final data = await ApiClient.get('/fields/$fieldId');
    return FieldModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── LỊCH SLOT THEO NGÀY ───────────────────────────────────────
  // GET /fields/{id}/slots?date=2026-06-01
  // Trả về vw_FieldSchedule filter theo fieldId + slotDate
  static Future<List<FieldSlotModel>> getSlots({
    required int fieldId,
    required DateTime date,
  }) async {
    final dateStr = '${date.year}-'
        '${date.month.toString().padLeft(2,'0')}-'
        '${date.day.toString().padLeft(2,'0')}';
    final data = await ApiClient.get(
      '/fields/$fieldId/slots',
      params: {'date': dateStr},
    );
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => FieldSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── LỊCH SLOT NHIỀU SÂN (trang chủ) ──────────────────────────
  // GET /slots/available?date=2026-06-01&type_id=1
  static Future<List<FieldSlotModel>> getAvailableSlots({
    required DateTime date,
    int? typeId,
    int? fieldId,
  }) async {
    final dateStr = '${date.year}-'
        '${date.month.toString().padLeft(2,'0')}-'
        '${date.day.toString().padLeft(2,'0')}';
    final params = <String, String>{
      'date': dateStr,
      if (typeId  != null) 'type_id':  typeId.toString(),
      if (fieldId != null) 'field_id': fieldId.toString(),
    };
    final data = await ApiClient.get('/slots/available', params: params);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => FieldSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
