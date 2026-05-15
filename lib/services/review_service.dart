// lib/services/review_service.dart

import '../models/review.dart';
import '../network/api_client.dart';
import '../network/media_url.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _api = ApiClient.instance;

  // ─────────────────────────────────────────────────────────────
  // NHẬN XÉT THEO SÂN — GET /api/reviews/field/{fieldId}
  // ─────────────────────────────────────────────────────────────

  Future<FieldReviewSummary> getFieldReviews(int fieldId) async {
    final res = await _api.get('/api/reviews/field/$fieldId');
    final summary = res.item(FieldReviewSummary.fromJson);
    return _patchUrls(summary);
  }

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

    if (identical(patched, summary.reviews)) return summary;
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
