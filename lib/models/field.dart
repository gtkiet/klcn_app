// lib/models/field.dart

// ── FIELD MODEL ───────────────────────────────────────────────────
// Item trong GET /api/fields và detail GET /api/fields/{fieldId}
class FieldModel {
  final int fieldId;
  final String name;
  final String? description;
  final double basePrice;
  final double peakPrice;
  final String? imageUrl;
  final String fieldType;
  final int typeId;
  final String status;
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
    fieldId: json['fieldId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
    peakPrice: (json['peakPrice'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String?,
    fieldType: json['fieldType'] as String,
    typeId: json['typeId'] as int,
    status: json['status'] as String,
    statusId: json['statusId'] as int,
    avgRating: (json['avgRating'] as num?)?.toDouble(),
    totalReviews: json['totalReviews'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// ── SLOT MODEL ────────────────────────────────────────────────────
// Một time slot trong FieldScheduleModel.slots[]
class SlotModel {
  final int fieldSlotId;
  final int slotId;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final double price;
  final bool isPeakHour;
  final String status;
  final int statusId;
  final int? holdRemainingSeconds;

  const SlotModel({
    required this.fieldSlotId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isPeakHour,
    required this.status,
    required this.statusId,
    this.holdRemainingSeconds,
  });

  bool get isAvailable => statusId == 1;
  bool get isHolding => statusId == 2;
  bool get isBooked => statusId == 3;

  String get displayTime => '$startTime - $endTime';

  String get priceFmt {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  // Server trả "HH:mm:ss.sssZ" hoặc "HH:mm:ss" — chuẩn hoá về "HH:mm"
  static String _parseTime(String raw) {
    final clean = raw.contains('T') ? raw.split('T').last : raw;
    final parts = clean.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0]}:${parts[1]}';
  }

  factory SlotModel.fromJson(Map<String, dynamic> json) => SlotModel(
    fieldSlotId: json['fieldSlotId'] as int,
    slotId: json['slotId'] as int,
    startTime: _parseTime(json['startTime'] as String),
    endTime: _parseTime(json['endTime'] as String),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    isPeakHour: json['isPeakHour'] as bool? ?? false,
    status: json['status'] as String,
    statusId: json['statusId'] as int,
    holdRemainingSeconds: json['holdRemainingSeconds'] as int?,
  );
}

// ── FIELD SCHEDULE MODEL ──────────────────────────────────────────
// Một item trong List trả về từ GET /api/fields/schedule
class FieldScheduleModel {
  final int fieldId;
  final String fieldName;
  final String fieldType;
  final String? imageUrl;
  final DateTime slotDate;
  final List<SlotModel> slots;

  const FieldScheduleModel({
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    this.imageUrl,
    required this.slotDate,
    required this.slots,
  });

  factory FieldScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return FieldScheduleModel(
      fieldId: json['fieldId'] as int,
      fieldName: json['fieldName'] as String,
      fieldType: json['fieldType'] as String,
      imageUrl: json['imageUrl'] as String?,
      slotDate: DateTime.parse(json['slotDate'] as String),
      slots: rawSlots
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── PAGED FIELD RESULT ────────────────────────────────────────────
// data{} của GET /api/fields
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
      items: rawItems
          .map((e) => FieldModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}
