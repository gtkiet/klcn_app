// lib/models/promotion.dart
// Ánh xạ GET /api/promotions/{code}
// Response spec chưa có data schema — model dựa theo convention của project
// và các field cần thiết cho flow apply-voucher.

class PromotionModel {
  final String code;
  final String? name;
  final String? description;
  final String discountType;    // "percent" | "fixed"
  final double discountValue;   // % hoặc số tiền cố định
  final double? minOrderAmount; // đơn tối thiểu để áp dụng
  final double? maxDiscount;    // giảm tối đa (dùng khi type = percent)
  final DateTime? expiresAt;
  final bool isActive;

  const PromotionModel({
    required this.code,
    this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.expiresAt,
    required this.isActive,
  });

  bool get isPercent => discountType == 'percent';

  /// Tính tiền giảm thực tế từ tổng đơn hàng
  double calcDiscount(double orderTotal) {
    if (isPercent) {
      final disc = orderTotal * discountValue / 100;
      return maxDiscount != null && disc > maxDiscount! ? maxDiscount! : disc;
    }
    return discountValue > orderTotal ? orderTotal : discountValue;
  }

  String get discountLabel {
    if (isPercent) return '-${discountValue.toStringAsFixed(0)}%';
    if (discountValue >= 1000000) {
      return '-${(discountValue / 1000000).toStringAsFixed(1)}M';
    }
    return '-${(discountValue / 1000).toStringAsFixed(0)}k';
  }

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
    code:            json['code']            as String,
    name:            json['name']            as String?,
    description:     json['description']     as String?,
    discountType:    json['discountType']    as String,
    discountValue:   (json['discountValue']  as num).toDouble(),
    minOrderAmount:  (json['minOrderAmount'] as num?)?.toDouble(),
    maxDiscount:     (json['maxDiscount']    as num?)?.toDouble(),
    expiresAt:       json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : null,
    isActive:        json['isActive']        as bool? ?? true,
  );
}