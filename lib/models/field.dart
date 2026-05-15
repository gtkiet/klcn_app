// lib/models/field.dart
// Ánh xạ GET /api/fields và GET /api/fields/{fieldId}

// ── FIELD MODEL ───────────────────────────────────────────────────
class FieldModel {
  final int fieldId;
  final String name;
  final String? description;
  final double basePrice;
  final double peakPrice;
  final String? imageUrl;
  final String fieldType;   // "Sân 5" | "Sân 7" — string từ server
  final int typeId;
  final String status;      // "Hoạt động" | "Bảo trì"
  final int statusId;
  final double? avgRating;
  final int? totalReviews;
  final DateTime createdAt;

  const FieldModel({
    required this.fieldId,
    required this.name,
    this.description,
    required this.basePrice,
    required this.peakPrice,
    this.imageUrl,
    required this.fieldType,
    required this.typeId,
    required this.status,
    required this.statusId,
    this.avgRating,
    this.totalReviews,
    required this.createdAt,
  });

  bool get isActive => statusId == 1;

  String get basePriceFmt {
    if (basePrice >= 1000000) {
      return '${(basePrice / 1000000).toStringAsFixed(basePrice % 1000000 == 0 ? 0 : 1)}M';
    }
    return '${(basePrice / 1000).toStringAsFixed(0)}k';
  }

  String get peakPriceFmt {
    if (peakPrice >= 1000000) {
      return '${(peakPrice / 1000000).toStringAsFixed(peakPrice % 1000000 == 0 ? 0 : 1)}M';
    }
    return '${(peakPrice / 1000).toStringAsFixed(0)}k';
  }

  factory FieldModel.fromJson(Map<String, dynamic> json) => FieldModel(
    fieldId:      json['fieldId']      as int,
    name:         json['name']         as String,
    description:  json['description']  as String?,
    basePrice:    (json['basePrice']   as num).toDouble(),
    peakPrice:    (json['peakPrice']   as num).toDouble(),
    imageUrl:     json['imageUrl']     as String?,
    fieldType:    json['fieldType']    as String,
    typeId:       json['typeId']       as int,
    status:       json['status']       as String,
    statusId:     json['statusId']     as int,
    avgRating:    (json['avgRating']   as num?)?.toDouble(),
    totalReviews: json['totalReviews'] as int?,
    createdAt:    DateTime.parse(json['createdAt'] as String),
  );
}

// ── PAGED FIELD RESPONSE ──────────────────────────────────────────
// Khớp với data{} của GET /api/fields
class PagedFieldResult {
  final List<FieldModel> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedFieldResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedFieldResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedFieldResult(
      items:           rawItems.map((e) => FieldModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount:      json['totalCount']      as int? ?? 0,
      page:            json['page']            as int? ?? 1,
      pageSize:        json['pageSize']        as int? ?? 10,
      totalPages:      json['totalPages']      as int? ?? 0,
      hasNextPage:     json['hasNextPage']     as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}