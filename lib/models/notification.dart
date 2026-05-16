// lib/models/notification.dart
//
// API:
//   GET   /api/notifications
//   GET   /api/notifications/unread-count
//   PATCH /api/notifications/{notificationId}/read
//   PATCH /api/notifications/read-all

// ── NOTIFICATION MODEL ────────────────────────────────────────────
class NotificationModel {
  final int notificationId;
  final String title;
  final String body;
  final String type;    // "booking" | "payment" | "system" | ...
  final int? refId;     // bookingId hoặc id liên quan (nullable)
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  /// Trả về bản sao đã đánh dấu đọc — dùng khi optimistic update UI
  NotificationModel markRead() => NotificationModel(
        notificationId: notificationId,
        title:          title,
        body:           body,
        type:           type,
        refId:          refId,
        isRead:         true,
        createdAt:      createdAt,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        notificationId: json['notificationId'] as int,
        title:          json['title']          as String,
        body:           json['body']           as String,
        type:           json['type']           as String,
        refId:          json['refId']          as int?,
        isRead:         json['isRead']         as bool,
        createdAt:      DateTime.parse(json['createdAt'] as String),
      );
}

// ── PAGED NOTIFICATION RESULT ─────────────────────────────────────
// data{} của GET /api/notifications
class PagedNotificationResult {
  final List<NotificationModel> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedNotificationResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedNotificationResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedNotificationResult(
      items:           rawItems.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount:      json['totalCount']      as int?  ?? 0,
      page:            json['page']            as int?  ?? 1,
      pageSize:        json['pageSize']        as int?  ?? 10,
      totalPages:      json['totalPages']      as int?  ?? 0,
      hasNextPage:     json['hasNextPage']     as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}