// lib/services/user_service.dart
// Kết nối API người dùng: hồ sơ, cập nhật, avatar
// Bảng: Users, Profiles, Notifications, Reviews

import '../models/user.dart';
import '../models/review.dart';
import '../models/notification.dart';
import 'api_client.dart';
import 'user_session.dart';

class UserService {
  // ── LẤY THÔNG TIN HỒ SƠ ──────────────────────────────────────
  // GET /users/me
  static Future<UserModel> getProfile() async {
    final data = await ApiClient.get('/users/me');
    final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
    await UserSession.updateUser(user);
    return user;
  }

  // ── CẬP NHẬT HỒ SƠ ───────────────────────────────────────────
  // PUT /users/me
  static Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? address,
    String? dateOfBirth,  // 'yyyy-MM-dd'
  }) async {
    final data = await ApiClient.put('/users/me', {
      'full_name':    fullName,
      'email':        email,
      'phone':        phone,
      'address':       ?address,
      'date_of_birth': ?dateOfBirth,
    });
    final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
    await UserSession.updateUser(user);
    return user;
  }

  // ── CẬP NHẬT AVATAR ──────────────────────────────────────────
  // POST /users/me/avatar (multipart/form-data)
  // TODO: Implement với http.MultipartRequest
  // static Future<UserModel> updateAvatar(File imageFile) async { ... }

  // ── THÔNG BÁO ─────────────────────────────────────────────────
  // GET /notifications?page=&per_page=
  static Future<List<NotificationModel>> getNotifications({
    int page    = 1,
    int perPage = 20,
    bool? unreadOnly,
  }) async {
    final params = <String, String>{
      'page':     page.toString(),
      'per_page': perPage.toString(),
      if (unreadOnly == true) 'unread_only': '1',
    };
    final data = await ApiClient.get('/notifications', params: params);
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── ĐỌC THÔNG BÁO ─────────────────────────────────────────────
  // PUT /notifications/{id}/read
  static Future<void> markAsRead(int notificationId) async {
    await ApiClient.put('/notifications/$notificationId/read', {});
  }

  // ── ĐỌC TẤT CẢ THÔNG BÁO ─────────────────────────────────────
  // PUT /notifications/read-all
  static Future<void> markAllAsRead() async {
    await ApiClient.put('/notifications/read-all', {});
  }

  // ── ĐÁNH GIÁ SÂN ─────────────────────────────────────────────
  // POST /reviews
  // Chỉ cho phép sau khi booking StatusId=4 (Đã hoàn thành)
  static Future<ReviewModel> submitReview({
    required int bookingId,
    required int fieldId,
    required int rating,
    String? comment,
    String? imageUrl,
  }) async {
    final data = await ApiClient.post('/reviews', {
      'booking_id': bookingId,
      'field_id':   fieldId,
      'rating':     rating,
      'comment':   ?comment,
      'image_url': ?imageUrl,
    });
    return ReviewModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ── ĐÁNH GIÁ CỦA USER ─────────────────────────────────────────
  // GET /reviews/me
  static Future<List<ReviewModel>> getMyReviews() async {
    final data = await ApiClient.get('/reviews/me');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── ĐÁNH GIÁ THEO SÂN ─────────────────────────────────────────
  // GET /fields/{id}/reviews
  static Future<List<ReviewModel>> getFieldReviews(int fieldId) async {
    final data = await ApiClient.get('/fields/$fieldId/reviews');
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
