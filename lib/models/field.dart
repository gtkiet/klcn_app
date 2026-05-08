// lib/models/field.dart
// Ánh xạ bảng Fields, FieldSlots, TimeSlots trong SportPlusDB

// ── ENUMS ────────────────────────────────────────────────────────
enum FieldType { san5, san7 }

enum FieldStatus { active, maintenance }

enum SlotStatus { empty, holding, booked }

// ── FIELD MODEL ───────────────────────────────────────────────────
// Bảng: Fields
class FieldModel {
  final int fieldId;
  final String name;
  final String? description;
  final double basePrice;   // Giá bình thường
  final double peakPrice;   // Giá giờ cao điểm
  final String? imageUrl;
  final FieldType type;
  final FieldStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Từ vw_FieldRatings (join khi cần)
  final double? avgRating;
  final int? totalReviews;

  const FieldModel({
    required this.fieldId,
    required this.name,
    this.description,
    required this.basePrice,
    required this.peakPrice,
    this.imageUrl,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.avgRating,
    this.totalReviews,
  });

  bool get isActive      => status == FieldStatus.active;
  String get typeName    => type == FieldType.san5 ? 'Sân 5' : 'Sân 7';
  String get basePriceFmt => '${(basePrice / 1000).toStringAsFixed(0)}k';
  String get peakPriceFmt => '${(peakPrice / 1000).toStringAsFixed(0)}k';

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      fieldId:      json['FieldId']    as int,
      name:         json['Name']       as String,
      description:  json['Description'] as String?,
      basePrice:    (json['BasePrice'] as num).toDouble(),
      peakPrice:    (json['PeakPrice'] as num).toDouble(),
      imageUrl:     json['ImageUrl']   as String?,
      type:         FieldType.values[(json['TypeId'] as int) - 1],
      status:       FieldStatus.values[(json['StatusId'] as int) - 1],
      createdAt:    DateTime.parse(json['CreatedAt'] as String),
      updatedAt:    DateTime.parse(json['UpdatedAt'] as String),
      avgRating:    (json['AvgRating'] as num?)?.toDouble(),
      totalReviews: json['TotalReviews'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'FieldId':     fieldId,
    'Name':        name,
    'Description': description,
    'BasePrice':   basePrice,
    'PeakPrice':   peakPrice,
    'ImageUrl':    imageUrl,
    'TypeId':      type.index + 1,
    'StatusId':    status.index + 1,
  };
}

// ── TIME SLOT MODEL ───────────────────────────────────────────────
// Bảng: TimeSlots
class TimeSlotModel {
  final int slotId;
  final String startTime;   // "HH:mm"
  final String endTime;     // "HH:mm"
  final bool isPeakHour;

  const TimeSlotModel({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.isPeakHour,
  });

  String get displayTime => '$startTime - $endTime';

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      slotId:     json['SlotId']    as int,
      startTime:  json['StartTime'] as String,
      endTime:    json['EndTime']   as String,
      isPeakHour: (json['IsPeakHour'] as int) == 1,
    );
  }
}

// ── FIELD SLOT MODEL ──────────────────────────────────────────────
// Bảng: FieldSlots (từ vw_FieldSchedule)
class FieldSlotModel {
  final int fieldSlotId;
  final int fieldId;
  final String fieldName;
  final int slotId;
  final String startTime;
  final String endTime;
  final bool isPeakHour;
  final DateTime slotDate;
  final double price;
  final SlotStatus status;
  final DateTime? holdExpireAt;
  final int? holdRemainingSeconds;

  const FieldSlotModel({
    required this.fieldSlotId,
    required this.fieldId,
    required this.fieldName,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.isPeakHour,
    required this.slotDate,
    required this.price,
    required this.status,
    this.holdExpireAt,
    this.holdRemainingSeconds,
  });

  bool get isAvailable => status == SlotStatus.empty;
  bool get isBooked    => status == SlotStatus.booked;
  bool get isHolding   => status == SlotStatus.holding;
  String get displayTime  => '$startTime - $endTime';
  String get priceFmt     => '${(price / 1000).toStringAsFixed(0)}k';

  factory FieldSlotModel.fromJson(Map<String, dynamic> json) {
    return FieldSlotModel(
      fieldSlotId: json['FieldSlotId'] as int,
      fieldId:     json['FieldId']     as int,
      fieldName:   json['FieldName']   as String,
      slotId:      json['SlotId']      as int,
      startTime:   json['StartTime']   as String,
      endTime:     json['EndTime']     as String,
      isPeakHour:  (json['IsPeakHour'] as int) == 1,
      slotDate:    DateTime.parse(json['SlotDate'] as String),
      price:       (json['Price'] as num).toDouble(),
      status:      SlotStatus.values[(json['SlotStatusId'] as int) - 1],
      holdExpireAt: json['HoldExpireAt'] != null
          ? DateTime.parse(json['HoldExpireAt'] as String)
          : null,
      holdRemainingSeconds: json['HoldRemainingSeconds'] as int?,
    );
  }
}
