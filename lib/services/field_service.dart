// lib/services/field_service.dart

import '../models/field.dart';
import '../network/api_client.dart';
import '../network/media_url.dart';

class FieldService {
  FieldService._();
  static final FieldService instance = FieldService._();

  final _api = ApiClient.instance;

  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH SÂN — GET /api/fields
  //
  // Parameters:
  //   Search   — tìm theo tên
  //   TypeId   — 1: Sân 5 | 2: Sân 7
  //   StatusId — 1: Hoạt động | 2: Bảo trì
  //   Page, PageSize
  // ─────────────────────────────────────────────────────────────

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

    // Patch imageUrl thành full URL (server trả path tương đối)
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

  // ─────────────────────────────────────────────────────────────
  // CHI TIẾT SÂN — GET /api/fields/{fieldId}
  // ─────────────────────────────────────────────────────────────

  Future<FieldModel> getFieldDetail(int fieldId) async {
    final res = await _api.get('/api/fields/$fieldId');
    return _patchImageUrl(res.item(FieldModel.fromJson));
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER: patch imageUrl thành full URL
  // ─────────────────────────────────────────────────────────────

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