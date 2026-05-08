// lib/services/user_service.dart

import '../models/notification.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

class UserService {
  // ─────────────────────────────────────────────────────────────
  // LẤY PROFILE
  // GET /users/me
  // ─────────────────────────────────────────────────────────────

  static Future<UserModel> getProfile() async {
    final data = await ApiClient.get('/users/me');

    final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);

    await UserSession().updateUser(user);

    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE PROFILE
  // PUT /users/me
  // ─────────────────────────────────────────────────────────────

  static Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? address,
    String? dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,

      'email': email,

      'phone': phone,

      if (address != null && address.isNotEmpty) 'address': address,

      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'date_of_birth': dateOfBirth,
    };

    final data = await ApiClient.put('/users/me', body);

    final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);

    await UserSession().updateUser(user);

    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE AVATAR
  // POST /users/me/avatar
  // ─────────────────────────────────────────────────────────────
  // TODO:
  // multipart/form-data upload

  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH THÔNG BÁO
  // GET /notifications
  // ─────────────────────────────────────────────────────────────

  static Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool? unreadOnly,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),

      'per_page': perPage.toString(),

      if (unreadOnly == true) 'unread_only': '1',
    };

    final data = await ApiClient.get('/notifications', params: params);

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỌC THÔNG BÁO
  // PUT /notifications/{id}/read
  // ─────────────────────────────────────────────────────────────

  static Future<void> markAsRead(int notificationId) async {
    await ApiClient.put('/notifications/$notificationId/read', {});
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỌC TẤT CẢ THÔNG BÁO
  // PUT /notifications/read-all
  // ─────────────────────────────────────────────────────────────

  static Future<void> markAllAsRead() async {
    await ApiClient.put('/notifications/read-all', {});
  }

  // ─────────────────────────────────────────────────────────────
  // ĐÁNH GIÁ SÂN
  // POST /reviews
  // ─────────────────────────────────────────────────────────────

  static Future<ReviewModel> submitReview({
    required int bookingId,
    required int fieldId,
    required int rating,
    String? comment,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'booking_id': bookingId,

      'field_id': fieldId,

      'rating': rating,

      if (comment != null && comment.isNotEmpty) 'comment': comment,

      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };

    final data = await ApiClient.post('/reviews', body);

    return ReviewModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────
  // REVIEW CỦA USER
  // GET /reviews/me
  // ─────────────────────────────────────────────────────────────

  static Future<List<ReviewModel>> getMyReviews() async {
    final data = await ApiClient.get('/reviews/me');

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // REVIEW THEO SÂN
  // GET /fields/{id}/reviews
  // ─────────────────────────────────────────────────────────────

  static Future<List<ReviewModel>> getFieldReviews(int fieldId) async {
    final data = await ApiClient.get('/fields/$fieldId/reviews');

    final list = data['data'] as List<dynamic>;

    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
