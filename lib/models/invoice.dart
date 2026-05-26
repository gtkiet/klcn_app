// lib/models/invoice.dart
//
// Model cho GET /api/invoices/{paymentId}
// Response schema:
// {
//   "paymentId": 0,
//   "invoiceCode": "string",
//   "bookingId": 0,
//   "customerName": "string",
//   "customerPhone": "string",
//   "customerEmail": "string",
//   "amount": 0,
//   "paymentMethod": "string",
//   "paymentStatus": "string",
//   "transactionCode": "string",
//   "note": "string",
//   "paidAt": "2026-05-26T12:13:02.917Z",
//   "details": [ { bookingDetailId, fieldId, fieldName, fieldType,
//                  slotDate, startTime, endTime, price } ],
//   "services": [ { serviceId, serviceName, quantity, unitPrice, total } ]
// }

import 'package:klcn_app/models/booking.dart';

// ── HELPERS (local, không export) ─────────────────────────────────
double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

String _fmtMoney(double amount) {
  if (amount == 0) return '0đ';
  if (amount >= 1_000_000) {
    return '${(amount / 1_000_000).toStringAsFixed(amount % 1_000_000 == 0 ? 0 : 1)}M';
  }
  return '${(amount / 1_000).toStringAsFixed(0)}k';
}

// ── INVOICE MODEL ──────────────────────────────────────────────────
// Reuse BookingDetailItem & BookingServiceItem từ booking.dart vì schema
// của details[] và services[] trong invoice khớp hoàn toàn.
class InvoiceModel {
  final int paymentId;
  final String invoiceCode;
  final int bookingId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final double amount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionCode;
  final String? note;
  final DateTime paidAt;
  final List<BookingDetailItem> details;
  final List<BookingServiceItem> services;

  const InvoiceModel({
    required this.paymentId,
    required this.invoiceCode,
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionCode,
    this.note,
    required this.paidAt,
    required this.details,
    required this.services,
  });

  // ── Display helpers ────────────────────────────────────────────
  /// Tổng tiền format: "150k", "1.5M", …
  String get amountFmt => _fmtMoney(amount);

  /// Ngày thanh toán format: "26/05/2026"
  String get paidAtFmt {
    final d = paidAt;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  /// Field name chính (slot đầu tiên), fallback '--'
  String get primaryField =>
      details.isNotEmpty ? details.first.fieldName : '--';

  /// Khoảng thời gian chính (slot đầu tiên), fallback '--'
  String get primaryTime =>
      details.isNotEmpty ? details.first.displayTime : '--';

  /// Ngày chính (slot đầu tiên), fallback '--'
  String get primaryDate =>
      details.isNotEmpty ? details.first.displayDate : '--';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] as List<dynamic>? ?? [];
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return InvoiceModel(
      paymentId: json['paymentId'] as int,
      invoiceCode: json['invoiceCode'] as String,
      bookingId: json['bookingId'] as int,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      amount: _toDouble(json['amount']),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      transactionCode: json['transactionCode'] as String?,
      note: json['note'] as String?,
      paidAt:
          DateTime.tryParse(json['paidAt'] as String? ?? '') ?? DateTime.now(),
      details: rawDetails
          .map((e) => BookingDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: rawServices
          .map((e) => BookingServiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
