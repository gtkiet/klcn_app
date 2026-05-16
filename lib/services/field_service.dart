// lib/services/field_service.dart

import '../models/field.dart';
import '../network/api_client.dart';
import '../network/media_url.dart';

class FieldService {
  FieldService._();
  static final FieldService instance = FieldService._();

  final _api = ApiClient.instance;

  // GET /api/fields
  Future<PagedFieldResult> getFields({
    String? search,
    int? typeId,
    int? statusId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final res = await _api.get(
      '/api/fields',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'Search': search.trim(),
        'TypeId':   ?typeId,
        'StatusId': ?statusId,
        'Page':     page,
        'PageSize': pageSize,
      },
    );

    final result = res.item(PagedFieldResult.fromJson);
    final patchedItems = result.items.map(_patchImageUrl).toList();
    return PagedFieldResult(
      items:           patchedItems,
      totalCount:      result.totalCount,
      page:            result.page,
      pageSize:        result.pageSize,
      totalPages:      result.totalPages,
      hasNextPage:     result.hasNextPage,
      hasPreviousPage: result.hasPreviousPage,
    );
  }

  // GET /api/fields/{fieldId}
  Future<FieldModel> getFieldDetail(int fieldId) async {
    final res = await _api.get('/api/fields/$fieldId');
    return _patchImageUrl(res.item(FieldModel.fromJson));
  }

  // GET /api/fields/schedule
  Future<List<FieldScheduleModel>> getSchedule({
    required DateTime date,
    int? fieldId,
    int? typeId,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final res = await _api.get(
      '/api/fields/schedule',
      queryParameters: {
        'Date': dateStr,
        'FieldId': ?fieldId,
        'TypeId':  ?typeId,
      },
    );

    final schedules = res.list(FieldScheduleModel.fromJson);
    return schedules.map((s) {
      final full = s.imageUrl.toFullMediaUrl;
      if (full == s.imageUrl) return s;
      return FieldScheduleModel(
        fieldId:   s.fieldId,
        fieldName: s.fieldName,
        fieldType: s.fieldType,
        imageUrl:  full,
        slotDate:  s.slotDate,
        slots:     s.slots,
      );
    }).toList();
  }

  static FieldModel _patchImageUrl(FieldModel field) {
    final full = field.imageUrl.toFullMediaUrl;
    if (full == field.imageUrl) return field;
    return FieldModel(
      fieldId:      field.fieldId,
      name:         field.name,
      description:  field.description,
      basePrice:    field.basePrice,
      peakPrice:    field.peakPrice,
      imageUrl:     full,
      fieldType:    field.fieldType,
      typeId:       field.typeId,
      status:       field.status,
      statusId:     field.statusId,
      avgRating:    field.avgRating,
      totalReviews: field.totalReviews,
      createdAt:    field.createdAt,
    );
  }
}