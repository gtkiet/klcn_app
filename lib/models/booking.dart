// lib/models/booking.dart
// Ánh xạ toàn bộ Booking API:
//   POST /api/bookings/hold
//   POST /api/bookings
//   GET  /api/bookings/my
//   GET  /api/bookings/{bookingId}
//   POST /api/bookings/{bookingId}/cancel
//   POST /api/bookings/{bookingId}/reschedule
//   POST /api/bookings/{bookingId}/apply-voucher
//   POST /api/bookings/{bookingId}/payment
//   GET  /api/bookings/{bookingId}/payments
//   GET  /api/bookings/{bookingId}/deposit

import 'package:klcn_app/network/media_url.dart';

// ── HELPERS ───────────────────────────────────────────────────────

// Cùng format "HH:mm:ss.sssZ" như SlotModel — dùng chung
String _parseTime(String raw) {
  final clean = raw.contains('T') ? raw.split('T').last : raw;
  final parts  = clean.split(':');
  if (parts.length < 2) return raw;
  return '${parts[0]}:${parts[1]}';
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year}';

// ── BOOKING CUSTOMER ──────────────────────────────────────────────
// Nhúng trong POST /api/bookings và GET /api/bookings/{id}
class BookingCustomer {
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final int roleId;
  final String status;
  final int statusId;
  final String? avatarUrl;
  final DateTime createdAt;

  const BookingCustomer({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.roleId,
    required this.status,
    required this.statusId,
    this.avatarUrl,
    required this.createdAt,
  });

  factory BookingCustomer.fromJson(Map<String, dynamic> json) => BookingCustomer(
    userId:    json['userId']    as int,
    fullName:  json['fullName']  as String,
    email:     json['email']     as String,
    phone:     json['phone']     as String,
    role:      json['role']      as String,
    roleId:    json['roleId']    as int,
    status:    json['status']    as String,
    statusId:  json['statusId']  as int,
    avatarUrl: (json['avatarUrl'] as String?).toFullMediaUrl,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// ── BOOKING DETAIL ITEM ───────────────────────────────────────────
// Một slot trong details[] — dùng trong cả booking full và list
class BookingDetailItem {
  final int bookingDetailId;
  final int fieldId;
  final String fieldName;
  final String fieldType;
  final DateTime slotDate;
  final String startTime;   // "HH:mm"
  final String endTime;
  final double price;

  const BookingDetailItem({
    required this.bookingDetailId,
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  String get displayTime  => '$startTime - $endTime';
  String get displayDate  => _fmtDate(slotDate);

  String get priceFmt {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  factory BookingDetailItem.fromJson(Map<String, dynamic> json) => BookingDetailItem(
    bookingDetailId: json['bookingDetailId'] as int,
    fieldId:         json['fieldId']         as int,
    fieldName:       json['fieldName']       as String,
    fieldType:       json['fieldType']       as String,
    slotDate:        DateTime.parse(json['slotDate'] as String),
    startTime:       _parseTime(json['startTime']    as String),
    endTime:         _parseTime(json['endTime']      as String),
    price:           (json['price']          as num).toDouble(),
  );
}

// ── BOOKING SERVICE ITEM ──────────────────────────────────────────
// Một dịch vụ đi kèm trong services[]
class BookingServiceItem {
  final int serviceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;
  final double total;

  const BookingServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  String get totalFmt {
    if (total >= 1000000) return '${(total / 1000000).toStringAsFixed(1)}M';
    return '${(total / 1000).toStringAsFixed(0)}k';
  }

  factory BookingServiceItem.fromJson(Map<String, dynamic> json) => BookingServiceItem(
    serviceId:   json['serviceId']   as int,
    serviceName: json['serviceName'] as String,
    quantity:    json['quantity']    as int,
    unitPrice:   (json['unitPrice']  as num).toDouble(),
    total:       (json['total']      as num).toDouble(),
  );
}

// ── DEPOSIT MODEL ─────────────────────────────────────────────────
// Nhúng trong booking response + GET /api/bookings/{id}/deposit
class DepositModel {
  final int depositId;
  final int bookingId;
  final double requiredAmount;
  final double paidAmount;
  final String status;
  final int statusId;
  final DateTime deadlineAt;
  final int minutesLeft;
  final DateTime? paidAt;

  const DepositModel({
    required this.depositId,
    required this.bookingId,
    required this.requiredAmount,
    required this.paidAmount,
    required this.status,
    required this.statusId,
    required this.deadlineAt,
    required this.minutesLeft,
    this.paidAt,
  });

  bool get isPaid   => statusId == 2;   // tuỳ server định nghĩa
  bool get isExpired => minutesLeft <= 0 && !isPaid;

  String get requiredFmt {
    if (requiredAmount >= 1000000) return '${(requiredAmount / 1000000).toStringAsFixed(1)}M';
    return '${(requiredAmount / 1000).toStringAsFixed(0)}k';
  }

  factory DepositModel.fromJson(Map<String, dynamic> json) => DepositModel(
    depositId:      json['depositId']      as int,
    bookingId:      json['bookingId']      as int,
    requiredAmount: (json['requiredAmount'] as num).toDouble(),
    paidAmount:     (json['paidAmount']    as num).toDouble(),
    status:         json['status']         as String,
    statusId:       json['statusId']       as int,
    deadlineAt:     DateTime.parse(json['deadlineAt'] as String),
    minutesLeft:    json['minutesLeft']    as int? ?? 0,
    paidAt:         json['paidAt'] != null
        ? DateTime.parse(json['paidAt'] as String)
        : null,
  );
}

// ── BOOKING MODEL (full) ──────────────────────────────────────────
// Response của POST /api/bookings và GET /api/bookings/{bookingId}
class BookingModel {
  final int bookingId;
  final BookingCustomer customer;
  final String status;
  final int statusId;
  final double subTotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double depositAmount;
  final String? promotionCode;
  final String? note;
  final String? cancelReason;
  final int rescheduleCount;
  final List<BookingDetailItem> details;
  final List<BookingServiceItem> services;
  final DepositModel? deposit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.bookingId,
    required this.customer,
    required this.status,
    required this.statusId,
    required this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.depositAmount,
    this.promotionCode,
    this.note,
    this.cancelReason,
    required this.rescheduleCount,
    required this.details,
    required this.services,
    this.deposit,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Convenience getters ───────────────────────────────────────
  bool get isBooked    => statusId == 1;
  bool get isCompleted => statusId == 2;
  bool get isCancelled => statusId == 3;

  /// Ngày + giờ của slot đầu tiên — dùng cho hiển thị nhanh
  String get primaryDate =>
      details.isNotEmpty ? details.first.displayDate : '--';

  String get primaryTime =>
      details.isNotEmpty ? details.first.displayTime : '--';

  String get primaryField =>
      details.isNotEmpty ? details.first.fieldName : '--';

  String get totalAmountFmt {
    if (totalAmount >= 1000000) {
      return '${(totalAmount / 1000000).toStringAsFixed(totalAmount % 1000000 == 0 ? 0 : 1)}M';
    }
    return '${(totalAmount / 1000).toStringAsFixed(0)}k';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawDetails  = json['details']  as List<dynamic>? ?? [];
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return BookingModel(
      bookingId:       json['bookingId']       as int,
      customer:        BookingCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      status:          json['status']          as String,
      statusId:        json['statusId']        as int,
      subTotal:        (json['subTotal']       as num).toDouble(),
      discountAmount:  (json['discountAmount'] as num).toDouble(),
      taxAmount:       (json['taxAmount']      as num).toDouble(),
      totalAmount:     (json['totalAmount']    as num).toDouble(),
      depositAmount:   (json['depositAmount']  as num).toDouble(),
      promotionCode:   json['promotionCode']   as String?,
      note:            json['note']            as String?,
      cancelReason:    json['cancelReason']    as String?,
      rescheduleCount: json['rescheduleCount'] as int? ?? 0,
      details:  rawDetails.map((e) => BookingDetailItem.fromJson(e as Map<String, dynamic>)).toList(),
      services: rawServices.map((e) => BookingServiceItem.fromJson(e as Map<String, dynamic>)).toList(),
      deposit:  json['deposit'] != null
          ? DepositModel.fromJson(json['deposit'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// ── BOOKING SUMMARY (list item) ───────────────────────────────────
// Một item trong data.items[] của GET /api/bookings/my
// Server trả ít field hơn — dùng riêng cho list để tránh null issue
class BookingSummary {
  final int bookingId;
  final String customerName;
  final String customerPhone;
  final String status;
  final int statusId;
  final double totalAmount;
  final int slotCount;
  final DateTime earliestSlotDate;
  final String earliestSlotTime;   // "HH:mm"
  final String fieldName;
  final DateTime createdAt;

  const BookingSummary({
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.statusId,
    required this.totalAmount,
    required this.slotCount,
    required this.earliestSlotDate,
    required this.earliestSlotTime,
    required this.fieldName,
    required this.createdAt,
  });

  bool get isBooked    => statusId == 1;
  bool get isCompleted => statusId == 2;
  bool get isCancelled => statusId == 3;

  String get displayDate => _fmtDate(earliestSlotDate);

  String get totalAmountFmt {
    if (totalAmount >= 1000000) {
      return '${(totalAmount / 1000000).toStringAsFixed(totalAmount % 1000000 == 0 ? 0 : 1)}M';
    }
    return '${(totalAmount / 1000).toStringAsFixed(0)}k';
  }

  factory BookingSummary.fromJson(Map<String, dynamic> json) => BookingSummary(
    bookingId:         json['bookingId']         as int,
    customerName:      json['customerName']      as String,
    customerPhone:     json['customerPhone']     as String,
    status:            json['status']            as String,
    statusId:          json['statusId']          as int,
    totalAmount:       (json['totalAmount']      as num).toDouble(),
    slotCount:         json['slotCount']         as int,
    earliestSlotDate:  DateTime.parse(json['earliestSlotDate'] as String),
    earliestSlotTime:  _parseTime(json['earliestSlotTime'] as String),
    fieldName:         json['fieldName']         as String,
    createdAt:         DateTime.parse(json['createdAt'] as String),
  );
}

// ── PAGED BOOKING RESULT ──────────────────────────────────────────
// data{} của GET /api/bookings/my
class PagedBookingResult {
  final List<BookingSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedBookingResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedBookingResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedBookingResult(
      items:           rawItems.map((e) => BookingSummary.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount:      json['totalCount']      as int? ?? 0,
      page:            json['page']            as int? ?? 1,
      pageSize:        json['pageSize']        as int? ?? 10,
      totalPages:      json['totalPages']      as int? ?? 0,
      hasNextPage:     json['hasNextPage']     as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }
}

// ── PAYMENT MODEL ─────────────────────────────────────────────────
// Một item trong GET /api/bookings/{id}/payments
class PaymentModel {
  final int paymentId;
  final int bookingId;
  final double amount;
  final String status;
  final int statusId;
  final String paymentMethod;
  final int methodId;
  final String? transactionCode;
  final String? note;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.statusId,
    required this.paymentMethod,
    required this.methodId,
    this.transactionCode,
    this.note,
    this.paidAt,
    required this.createdAt,
  });

  String get amountFmt {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    paymentId:       json['paymentId']       as int,
    bookingId:       json['bookingId']       as int,
    amount:          (json['amount']         as num).toDouble(),
    status:          json['status']          as String,
    statusId:        json['statusId']        as int,
    paymentMethod:   json['paymentMethod']   as String,
    methodId:        json['methodId']        as int,
    transactionCode: json['transactionCode'] as String?,
    note:            json['note']            as String?,
    paidAt:          json['paidAt'] != null
        ? DateTime.parse(json['paidAt'] as String)
        : null,
    createdAt:       DateTime.parse(json['createdAt'] as String),
  );
}