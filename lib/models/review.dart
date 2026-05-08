// lib/models/review.dart
// Ánh xạ bảng Reviews trong SportPlusDB

class ReviewModel {
  final int reviewId;
  final int bookingId;
  final int userId;
  final int fieldId;
  final String fieldName;
  final int rating;         // 1–5
  final String? comment;
  final String? imageUrl;
  final bool isVisible;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.fieldId,
    required this.fieldName,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.isVisible,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId:  json['ReviewId']  as int,
      bookingId: json['BookingId'] as int,
      userId:    json['UserId']    as int,
      fieldId:   json['FieldId']   as int,
      fieldName: json['FieldName'] as String? ?? '',
      rating:    json['Rating']    as int,
      comment:   json['Comment']   as String?,
      imageUrl:  json['ImageUrl']  as String?,
      isVisible: (json['IsVisible'] as int) == 1,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
    );
  }
}
