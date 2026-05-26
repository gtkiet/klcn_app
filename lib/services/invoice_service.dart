// lib/services/invoice_service.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:klcn_app/models/invoice.dart';
import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/services/auth_service.dart';
import 'package:klcn_app/session/user_session.dart';

class InvoiceService {
  InvoiceService._();
  static final InvoiceService instance = InvoiceService._();

  final _api = ApiClient.instance;

  // ── GET INVOICE ────────────────────────────────────────────────
  /// GET /api/invoices/{paymentId}
  Future<InvoiceModel> getInvoice(int paymentId) async {
    final res = await _api.get('/api/invoices/$paymentId');
    return res.item(InvoiceModel.fromJson);
  }

  // ── OPEN INVOICE PDF ───────────────────────────────────────────
  /// Download PDF về máy rồi mở bằng viewer trên thiết bị.
  ///
  /// KHÔNG dùng launchUrl vì trình duyệt ngoài không mang Bearer token → 401.
  ///
  /// dio.download() không đi qua ErrorInterceptor nên tự xử lý
  /// refresh token 1 lần nếu nhận 401.
  Future<void> openInvoicePdf(int paymentId) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/HoaDon_$paymentId.pdf';

    await _downloadWithAuth(
      '/api/invoices/$paymentId/pdf',
      savePath,
      paymentId: paymentId,
    );

    // Kiểm tra magic bytes — tránh lưu nhầm trang HTML lỗi vào file .pdf
    final bytes = await File(savePath).readAsBytes();
    final isPdf = bytes.length >= 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46;   // F
    if (!isPdf) {
      await File(savePath).delete();
      throw Exception('File trả về không hợp lệ. Vui lòng thử lại.');
    }

    final result = await OpenFile.open(savePath);
    if (result.type != ResultType.done) {
      throw Exception('Không thể mở file PDF: ${result.message}');
    }
  }

  // ── DOWNLOAD HELPER ────────────────────────────────────────────
  /// Gọi dio.download() với token hiện tại.
  /// Nếu nhận 401 → thử refresh token 1 lần rồi retry.
  /// dio.download() không qua ErrorInterceptor nên phải tự handle ở đây.
  Future<void> _downloadWithAuth(
    String path,
    String savePath, {
    required int paymentId,
  }) async {
    try {
      await _doDownload(path, savePath);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Thử refresh token rồi retry 1 lần
        try {
          await AuthService.instance.refreshToken();
        } catch (_) {
          throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.');
        }
        // Retry sau refresh
        try {
          await _doDownload(path, savePath);
        } on DioException catch (retryErr) {
          _rethrowDownloadError(retryErr, paymentId);
        }
      } else {
        _rethrowDownloadError(e, paymentId);
      }
    }
  }

  Future<void> _doDownload(String path, String savePath) async {
    final token = UserSession.instance.accessToken;
    await _api.dio.download(
      path,
      savePath,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Never _rethrowDownloadError(DioException e, int paymentId) {
    final code = e.response?.statusCode;
    if (code == 401) throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.');
    if (code == 404) throw Exception('Không tìm thấy hóa đơn #$paymentId.');
    throw Exception('Tải hóa đơn thất bại: ${e.message}');
  }
}