import 'package:url_launcher/url_launcher.dart';

import 'package:klcn_app/models/booking.dart';
import 'package:klcn_app/network/api_client.dart';

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

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] as List<dynamic>? ?? [];
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return InvoiceModel(
      paymentId: json['paymentId'] as int,
      invoiceCode: json['invoiceCode'] as String,
      bookingId: json['bookingId'] as int,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      transactionCode: json['transactionCode'] as String?,
      note: json['note'] as String?,
      paidAt: DateTime.parse(json['paidAt'] as String),
      details: rawDetails
          .map((e) => BookingDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: rawServices
          .map((e) => BookingServiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InvoiceService {
  InvoiceService._();
  static final InvoiceService instance = InvoiceService._();

  final _api = ApiClient.instance;

  Future<InvoiceModel> getInvoice(int paymentId) async {
    final res = await _api.get('/api/invoices/$paymentId');
    return res.item(InvoiceModel.fromJson);
  }

  Future<void> openInvoicePdf(int paymentId) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/api/invoices/$paymentId/pdf');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không thể mở hóa đơn PDF');
    }
  }
}
