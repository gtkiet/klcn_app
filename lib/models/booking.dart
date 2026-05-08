// lib/models/booking.dart
// Ánh xạ bảng Bookings, BookingDetails, Payments, Deposits, BookingServices

// ── ENUMS (khớp BookingStatuses lookup) ──────────────────────────
enum BookingStatus {
  pendingPayment,   // 1 - Chờ thanh toán
  confirmed,        // 2 - Đã xác nhận
  cancelled,        // 3 - Đã hủy
  completed,        // 4 - Đã hoàn thành
  pendingDeposit,   // 5 - Chờ đặt cọc
}

enum PaymentStatus {
  unpaid,           // 1 - Chưa thanh toán
  paid,             // 2 - Đã thanh toán
  failed,           // 3 - Thất bại
  refunded,         // 4 - Đã hoàn tiền
}

enum PaymentMethod {
  cash,             // 1 - Tiền mặt
  transfer,         // 2 - Chuyển khoản
  vnpay,            // 3 - VNPay
  momo,             // 4 - MoMo
}

enum DepositStatus {
  pending,          // 1 - Chờ nộp
  paid,             // 2 - Đã nộp
  refunded,         // 3 - Đã hoàn
  forfeited,        // 4 - Đã tịch thu
}

// ── SERVICE (dịch vụ đi kèm) ─────────────────────────────────────
// Bảng: Services
class ServiceModel {
  final int serviceId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const ServiceModel({
    required this.serviceId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  String get priceFmt => '${(price / 1000).toStringAsFixed(0)}k';

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId:   json['ServiceId']   as int,
      name:        json['Name']        as String,
      description: json['Description'] as String?,
      price:       (json['Price'] as num).toDouble(),
      imageUrl:    json['ImageUrl']    as String?,
      isAvailable: (json['IsAvailable'] as int) == 1,
    );
  }
}

// BookingServices (dịch vụ đã chọn trong booking)
class BookingServiceItem {
  final int serviceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;

  const BookingServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  factory BookingServiceItem.fromJson(Map<String, dynamic> json) {
    return BookingServiceItem(
      serviceId:   json['ServiceId']   as int,
      serviceName: json['ServiceName'] as String? ?? '',
      quantity:    json['Quantity']    as int,
      unitPrice:   (json['UnitPrice']  as num).toDouble(),
    );
  }
}

// ── PAYMENT MODEL ─────────────────────────────────────────────────
// Bảng: Payments
class PaymentModel {
  final int paymentId;
  final int bookingId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionCode;
  final String? note;
  final DateTime? paidAt;
  final DateTime createdAt;

  const PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionCode,
    this.note,
    this.paidAt,
    required this.createdAt,
  });

  String get amountFmt {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId:       json['PaymentId']       as int,
      bookingId:       json['BookingId']        as int,
      amount:          (json['Amount'] as num).toDouble(),
      status:          PaymentStatus.values[(json['StatusId'] as int) - 1],
      method:          PaymentMethod.values[(json['MethodId'] as int) - 1],
      transactionCode: json['TransactionCode'] as String?,
      note:            json['Note']            as String?,
      paidAt:          json['PaidAt'] != null
          ? DateTime.parse(json['PaidAt'] as String)
          : null,
      createdAt:       DateTime.parse(json['CreatedAt'] as String),
    );
  }
}

// ── DEPOSIT MODEL ─────────────────────────────────────────────────
// Bảng: Deposits
class DepositModel {
  final int depositId;
  final int bookingId;
  final double requiredAmount;
  final double paidAmount;
  final DepositStatus status;
  final DateTime deadlineAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final DateTime? forfeitedAt;

  const DepositModel({
    required this.depositId,
    required this.bookingId,
    required this.requiredAmount,
    required this.paidAmount,
    required this.status,
    required this.deadlineAt,
    this.paidAt,
    this.refundedAt,
    this.forfeitedAt,
  });

  bool get isPending   => status == DepositStatus.pending;
  bool get isPaid      => status == DepositStatus.paid;
  int  get minutesLeft => deadlineAt.difference(DateTime.now()).inMinutes;
  bool get isUrgent    => minutesLeft < 30 && isPending;

  String get requiredFmt => '${(requiredAmount / 1000).toStringAsFixed(0)}k';

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      depositId:      json['DepositId']      as int,
      bookingId:      json['BookingId']      as int,
      requiredAmount: (json['RequiredAmount'] as num).toDouble(),
      paidAmount:     (json['PaidAmount']    as num).toDouble(),
      status:         DepositStatus.values[(json['StatusId'] as int) - 1],
      deadlineAt:     DateTime.parse(json['DeadlineAt'] as String),
      paidAt:         json['PaidAt']         != null
          ? DateTime.parse(json['PaidAt']     as String) : null,
      refundedAt:     json['RefundedAt']     != null
          ? DateTime.parse(json['RefundedAt'] as String) : null,
      forfeitedAt:    json['ForfeitedAt']    != null
          ? DateTime.parse(json['ForfeitedAt'] as String) : null,
    );
  }
}

// ── BOOKING MODEL ─────────────────────────────────────────────────
// Bảng: Bookings (từ vw_BookingHistory — đầy đủ nhất)
class BookingModel {
  final int bookingId;
  final int userId;
  final String? customerName;
  final String? customerPhone;
  final BookingStatus status;
  final double? subTotal;
  final double discountAmount;
  final double taxAmount;
  final double? totalAmount;
  final double depositAmount;
  final int rescheduleCount;
  final String? promotionCode;
  final String? note;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // BookingDetails (join — 1 booking có thể có nhiều slot)
  final List<BookingDetailItem> details;

  // BookingServices
  final List<BookingServiceItem> services;

  // Payment (mới nhất)
  final PaymentModel? latestPayment;

  // Deposit (nếu có)
  final DepositModel? deposit;

  const BookingModel({
    required this.bookingId,
    required this.userId,
    this.customerName,
    this.customerPhone,
    required this.status,
    this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    this.totalAmount,
    required this.depositAmount,
    required this.rescheduleCount,
    this.promotionCode,
    this.note,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    this.details = const [],
    this.services = const [],
    this.latestPayment,
    this.deposit,
  });

  // Helpers
  bool get isPending        => status == BookingStatus.pendingPayment;
  bool get isConfirmed      => status == BookingStatus.confirmed;
  bool get isCancelled      => status == BookingStatus.cancelled;
  bool get isCompleted      => status == BookingStatus.completed;
  bool get isPendingDeposit => status == BookingStatus.pendingDeposit;

  bool get canCancel   => status == BookingStatus.confirmed
      || status == BookingStatus.pendingPayment
      || status == BookingStatus.pendingDeposit;
  bool get canReview   => status == BookingStatus.completed;
  bool get canReschedule =>
      status == BookingStatus.confirmed && rescheduleCount < 2;

  String get bookingCode => '#${bookingId.toString().padLeft(4, '0')}';

  String _fmt(double? v) {
    if (v == null) return '--';
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  String get totalFmt   => _fmt(totalAmount);
  String get subFmt     => _fmt(subTotal);
  String get depositFmt => _fmt(depositAmount);

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId:       json['BookingId']      as int,
      userId:          json['UserId']          as int,
      customerName:    json['CustomerName']   as String?,
      customerPhone:   json['CustomerPhone']  as String?,
      status:          BookingStatus.values[(json['BookingStatusId'] as int) - 1],
      subTotal:        (json['SubTotal'] as num?)?.toDouble(),
      discountAmount:  (json['DiscountAmount'] as num? ?? 0).toDouble(),
      taxAmount:       (json['TaxAmount']      as num? ?? 0).toDouble(),
      totalAmount:     (json['TotalAmount'] as num?)?.toDouble(),
      depositAmount:   (json['DepositAmount']  as num? ?? 0).toDouble(),
      rescheduleCount: json['RescheduleCount'] as int? ?? 0,
      promotionCode:   json['PromotionCode']  as String?,
      note:            json['Note']           as String?,
      cancelReason:    json['CancelReason']   as String?,
      createdAt:       DateTime.parse(json['BookingDate'] as String),
      updatedAt:       DateTime.parse(json['UpdatedAt']  as String),
    );
  }
}

// ── BOOKING DETAIL ITEM ───────────────────────────────────────────
// Từ BookingDetails JOIN FieldSlots JOIN Fields JOIN TimeSlots
class BookingDetailItem {
  final int bookingDetailId;
  final int fieldSlotId;
  final int fieldId;
  final String fieldName;
  final String fieldType;
  final String startTime;
  final String endTime;
  final DateTime slotDate;
  final double price;

  const BookingDetailItem({
    required this.bookingDetailId,
    required this.fieldSlotId,
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    required this.startTime,
    required this.endTime,
    required this.slotDate,
    required this.price,
  });

  String get displayTime => '$startTime - $endTime';
  String get displayDate {
    return '${slotDate.day.toString().padLeft(2,'0')}/'
        '${slotDate.month.toString().padLeft(2,'0')}/'
        '${slotDate.year}';
  }

  factory BookingDetailItem.fromJson(Map<String, dynamic> json) {
    return BookingDetailItem(
      bookingDetailId: json['BookingDetailId'] as int,
      fieldSlotId:     json['FieldSlotId']     as int,
      fieldId:         json['FieldId']          as int,
      fieldName:       json['FieldName']        as String,
      fieldType:       json['FieldType']        as String,
      startTime:       json['StartTime']        as String,
      endTime:         json['EndTime']          as String,
      slotDate:        DateTime.parse(json['SlotDate'] as String),
      price:           (json['SlotPrice'] as num).toDouble(),
    );
  }
}
