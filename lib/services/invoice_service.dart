// lib/services/invoice_service.dart

import 'package:url_launcher/url_launcher.dart';

import 'package:klcn_app/models/invoice.dart';
import 'package:klcn_app/network/api_client.dart';

class InvoiceService {
  InvoiceService._();
  static final InvoiceService instance = InvoiceService._();

  final _api = ApiClient.instance;

  // ── GET INVOICE ────────────────────────────────────────────────
  /// GET /api/invoices/{paymentId}
  /// Trả về chi tiết hóa đơn: thông tin khách hàng, số tiền,
  /// danh sách slot sân (details) và dịch vụ kèm theo (services).
  Future<InvoiceModel> getInvoice(int paymentId) async {
    final res = await _api.get('/api/invoices/$paymentId');
    return res.item(InvoiceModel.fromJson);
  }

  // ── OPEN INVOICE PDF ───────────────────────────────────────────
  /// Mở file PDF hóa đơn trên trình duyệt / app ngoài.
  /// URL: {baseUrl}/api/invoices/{paymentId}/pdf
  Future<void> openInvoicePdf(int paymentId) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/api/invoices/$paymentId/pdf');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không thể mở hóa đơn PDF');
    }
  }
}
