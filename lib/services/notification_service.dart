// lib/services/notification_service.dart
// Ánh xạ:
//   GET   /api/notifications
//   GET   /api/notifications/unread-count
//   PATCH /api/notifications/{notificationId}/read
//   PATCH /api/notifications/read-all

import '../models/notification.dart';
import '../network/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  // ─────────────────────────────────────────────────────────────
  // DANH SÁCH THÔNG BÁO — GET /api/notifications
  // Parameters: IsRead?, Page, PageSize
  // ─────────────────────────────────────────────────────────────

  Future<PagedNotificationResult> getNotifications({
    bool? isRead,
    int page     = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.get(
      '/api/notifications',
      queryParameters: {
        'IsRead':    ?isRead,
        'Page':     page,
        'PageSize': pageSize,
      },
    );
    return res.item(PagedNotificationResult.fromJson);
  }

  // ─────────────────────────────────────────────────────────────
  // SỐ THÔNG BÁO CHƯA ĐỌC — GET /api/notifications/unread-count
  // Response data: int
  // ─────────────────────────────────────────────────────────────

  Future<int> getUnreadCount() async {
    final res = await _api.get('/api/notifications/unread-count');
    return res.raw<int>();
  }

  // ─────────────────────────────────────────────────────────────
  // ĐÁNH DẤU ĐÃ ĐỌC — PATCH /api/notifications/{id}/read
  // Response data: String
  // ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(int notificationId) async {
    await _api.patch('/api/notifications/$notificationId/read');
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỌC TẤT CẢ — PATCH /api/notifications/read-all
  // ─────────────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    await _api.patch('/api/notifications/read-all');
  }
}