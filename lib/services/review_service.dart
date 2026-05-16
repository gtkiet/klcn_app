// lib/services/review_service.dart

import 'package:dio/dio.dart';

import 'package:klcn_app/models/review.dart';
import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/network/media_url.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _api = ApiClient.instance;

  // ── GET FIELD REVIEWS ──────────────────────────────────────────
  /// GET /api/reviews/field/{fieldId}
  /// Trả về FieldReviewSummary (avgRating, star breakdown, + reviews[])
  Future<FieldReviewSummary> getFieldReviews(int fieldId) async {
    final res = await _api.get('/api/reviews/field/$fieldId');
    final summary = res.item(FieldReviewSummary.fromJson);
    return _patchUrls(summary);
  }

  // ── CREATE REVIEW ──────────────────────────────────────────────
  /// POST /api/reviews
  /// Body: multipart/form-data
  ///   BookingId (int, required)
  ///   Rating    (int 1–5, required)
  ///   Comment   (String, optional)
  ///   Image     (file, optional)
  Future<ReviewModel> createReview({
    required int bookingId,
    required int rating,
    String? comment,
    String? imagePath, // local file path, null nếu không kèm ảnh
  }) async {
    final fields = <String, dynamic>{
      'BookingId': bookingId.toString(),
      'Rating': rating.toString(),
      if (comment != null && comment.trim().isNotEmpty)
        'Comment': comment.trim(),
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      fields['Image'] = await MultipartFile.fromFile(imagePath);
    }

    final formData = FormData.fromMap(fields);
    final res = await _api.postForm('/api/reviews', formData);
    return res.item(ReviewModel.fromJson);
  }

  // ── HELPERS ────────────────────────────────────────────────────

  // Patch avatarUrl + imageUrl trong từng review thành full URL
  static FieldReviewSummary _patchUrls(FieldReviewSummary summary) {
    final patched = summary.reviews.map((r) {
      final avatar = r.avatarUrl.toFullMediaUrl;
      final image = r.imageUrl.toFullMediaUrl;
      if (avatar == r.avatarUrl && image == r.imageUrl) return r;
      return ReviewModel(
        reviewId: r.reviewId,
        bookingId: r.bookingId,
        userId: r.userId,
        userName: r.userName,
        avatarUrl: avatar,
        fieldId: r.fieldId,
        fieldName: r.fieldName,
        rating: r.rating,
        comment: r.comment,
        imageUrl: image,
        isVisible: r.isVisible,
        createdAt: r.createdAt,
      );
    }).toList();

    return FieldReviewSummary(
      fieldId: summary.fieldId,
      fieldName: summary.fieldName,
      fieldType: summary.fieldType,
      avgRating: summary.avgRating,
      totalReviews: summary.totalReviews,
      stars5: summary.stars5,
      stars4: summary.stars4,
      stars3: summary.stars3,
      stars2: summary.stars2,
      stars1: summary.stars1,
      reviews: patched,
    );
  }
}
