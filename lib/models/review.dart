// lib/models/review.dart
//
// API:
//   POST /api/reviews                    → tạo review (multipart/form-data)
//   GET  /api/reviews/field/{fieldId}    → lấy summary + list reviews

// ── REVIEW MODEL ──────────────────────────────────────────────────
class ReviewModel {
  final int reviewId;
  final int bookingId;
  final int userId;
  final String userName;
  final String? avatarUrl;
  final int fieldId;
  final String fieldName;
  final int rating; // 1–5
  final String? comment;
  final String? imageUrl;
  final bool isVisible;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.fieldId,
    required this.fieldName,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.isVisible,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    reviewId: json['reviewId'] as int,
    bookingId: json['bookingId'] as int,
    userId: json['userId'] as int,
    userName: json['userName'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    fieldId: json['fieldId'] as int,
    fieldName: json['fieldName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    imageUrl: json['imageUrl'] as String?,
    isVisible: json['isVisible'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// ── FIELD REVIEW SUMMARY ──────────────────────────────────────────
// Toàn bộ data{} của GET /api/reviews/field/{fieldId}
class FieldReviewSummary {
  final int fieldId;
  final String fieldName;
  final String fieldType;
  final double avgRating;
  final int totalReviews;
  final int stars5;
  final int stars4;
  final int stars3;
  final int stars2;
  final int stars1;
  final List<ReviewModel> reviews;

  const FieldReviewSummary({
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    required this.avgRating,
    required this.totalReviews,
    required this.stars5,
    required this.stars4,
    required this.stars3,
    required this.stars2,
    required this.stars1,
    required this.reviews,
  });

  /// Tỷ lệ 0.0–1.0 của mỗi mức sao — dùng để vẽ progress bar
  double starRatio(int star) {
    if (totalReviews == 0) return 0;
    final count = switch (star) {
      5 => stars5,
      4 => stars4,
      3 => stars3,
      2 => stars2,
      _ => stars1,
    };
    return count / totalReviews;
  }

  factory FieldReviewSummary.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'] as List<dynamic>? ?? [];
    return FieldReviewSummary(
      fieldId: json['fieldId'] as int,
      fieldName: json['fieldName'] as String,
      fieldType: json['fieldType'] as String,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['totalReviews'] as int,
      stars5: json['stars5'] as int? ?? 0,
      stars4: json['stars4'] as int? ?? 0,
      stars3: json['stars3'] as int? ?? 0,
      stars2: json['stars2'] as int? ?? 0,
      stars1: json['stars1'] as int? ?? 0,
      reviews: rawReviews
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
