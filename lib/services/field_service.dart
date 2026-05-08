// lib/services/field_service.dart

import '../models/field.dart';
import '../network/api_client.dart';

class FieldService {
  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH SÂN
  // GET /fields
  // ─────────────────────────────────────────────────────────────

  static Future<List<FieldModel>> getFields({
    int? typeId,
    String? keyword,

    // price_asc | price_desc | rating
    String? sortBy,
  }) async {
    final params = <String, dynamic>{
      if (typeId != null) 'type_id': typeId.toString(),

      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,

      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
    };

    final data = await ApiClient.get('/fields', params: params);

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => FieldModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // CHI TIẾT SÂN
  // GET /fields/{id}
  // ─────────────────────────────────────────────────────────────

  static Future<FieldModel> getFieldDetail(int fieldId) async {
    final data = await ApiClient.get('/fields/$fieldId');

    return FieldModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────
  // SLOT THEO NGÀY
  // GET /fields/{id}/slots
  // ─────────────────────────────────────────────────────────────

  static Future<List<FieldSlotModel>> getSlots({
    required int fieldId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final data = await ApiClient.get(
      '/fields/$fieldId/slots',
      params: {'date': dateStr},
    );

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => FieldSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // SLOT NHIỀU SÂN
  // GET /slots/available
  // ─────────────────────────────────────────────────────────────

  static Future<List<FieldSlotModel>> getAvailableSlots({
    required DateTime date,
    int? typeId,
    int? fieldId,
  }) async {
    final dateStr =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final params = <String, dynamic>{
      'date': dateStr,

      if (typeId != null) 'type_id': typeId.toString(),

      if (fieldId != null) 'field_id': fieldId.toString(),
    };

    final data = await ApiClient.get('/slots/available', params: params);

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => FieldSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
