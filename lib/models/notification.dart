// lib/models/notification.dart
// Ánh xạ bảng Notifications trong SportPlusDB

// Type: BOOKING_CONFIRM | BOOKING_CANCEL | PAYMENT | DEPOSIT | INCIDENT | REVIEW | SYSTEM
enum NotificationType {
  bookingConfirm,
  bookingCancel,
  payment,
  deposit,
  incident,
  review,
  system,
}

class NotificationModel {
  final int notificationId;
  final int userId;
  final String title;
  final String? body;
  final NotificationType type;
  final int? refId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    this.body,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['Type'] as String? ?? '').toUpperCase();
    final typeMap = {
      'BOOKING_CONFIRM': NotificationType.bookingConfirm,
      'BOOKING_CANCEL':  NotificationType.bookingCancel,
      'PAYMENT':         NotificationType.payment,
      'DEPOSIT':         NotificationType.deposit,
      'INCIDENT':        NotificationType.incident,
      'REVIEW':          NotificationType.review,
      'SYSTEM':          NotificationType.system,
    };
    return NotificationModel(
      notificationId: json['NotificationId'] as int,
      userId:         json['UserId']          as int,
      title:          json['Title']           as String,
      body:           json['Body']            as String?,
      type:           typeMap[typeStr] ?? NotificationType.system,
      refId:          json['RefId']           as int?,
      isRead:         (json['IsRead'] as int) == 1,
      createdAt:      DateTime.parse(json['CreatedAt'] as String),
    );
  }
}
