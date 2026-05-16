// lib/services/notification_service.dart

import '../models/notification.dart';
import '../network/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  // GET /api/notifications
  Future<PagedNotificationResult> getNotifications({
    bool? isRead,
    int page     = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.get(
      '/api/notifications',
      queryParameters: {
        'IsRead': ?isRead,
        'Page':     page,
        'PageSize': pageSize,
      },
    );
    return res.item(PagedNotificationResult.fromJson);
  }

  // GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    final res = await _api.get('/api/notifications/unread-count');
    return res.raw<int>();
  }

  // PATCH /api/notifications/{id}/read
  Future<void> markAsRead(int notificationId) async {
    await _api.patch('/api/notifications/$notificationId/read');
  }

  // PATCH /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.patch('/api/notifications/read-all');
  }
}