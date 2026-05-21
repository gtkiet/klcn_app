// lib/services/notification_service.dart

import 'package:klcn_app/models/notification.dart';
import 'package:klcn_app/network/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  // ── GET NOTIFICATIONS ──────────────────────────────────────────
  /// GET /api/notifications
  /// Params: IsRead?, Page, PageSize
  Future<PagedNotificationResult> getNotifications({
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.get(
      '/api/notifications',
      queryParameters: {'IsRead': ?isRead, 'Page': page, 'PageSize': pageSize},
    );
    return res.item(PagedNotificationResult.fromJson);
  }

  // ── GET UNREAD COUNT ───────────────────────────────────────────
  /// GET /api/notifications/unread-count
  /// Response data: int
  Future<int> getUnreadCount() async {
    final res = await _api.get('/api/notifications/unread-count');
    return res.raw<int>();
  }

  // ── MARK AS READ ───────────────────────────────────────────────
  /// PATCH /api/notifications/{notificationId}/read
  Future<void> markAsRead(int notificationId) async {
    await _api.patch('/api/notifications/$notificationId/read');
  }

  // ── MARK ALL AS READ ───────────────────────────────────────────
  /// PATCH /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.patch('/api/notifications/read-all');
  }
}
