// lib/core/errors/error_parser.dart

import 'app_exception.dart';
import 'error_type.dart';

class ErrorParser {
  ErrorParser._();

  /// Chuyển response body + status code thành [AppException].
  ///
  /// Thứ tự ưu tiên:
  ///   1. `errors[].description`  (validation từ server)
  ///   2. `warningMessages[]`
  ///   3. `message`               (fallback đơn giản)
  ///   4. Generic "Có lỗi xảy ra"
  static AppException parse(dynamic data, {int? statusCode}) {
    try {
      if (data == null) {
        return AppException(
          'Có lỗi xảy ra',
          type: _mapType(statusCode),
          code: statusCode,
        );
      }

      if (data is Map<String, dynamic>) {
        // ── 1. errors[] ───────────────────────────────────────────────────
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          final msgs = errors
              .map<String>((e) => e['description']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();

          if (msgs.isNotEmpty) {
            return AppException(
              msgs.join('\n'),
              messages: msgs,
              type: ErrorType.validation,
              code: statusCode,
              raw: data,
            );
          }
        }

        // ── 2. warningMessages[] ──────────────────────────────────────────
        final warnings = data['warningMessages'];
        if (warnings is List && warnings.isNotEmpty) {
          final msgs = warnings.map((e) => e.toString()).toList();
          return AppException(
            msgs.join('\n'),
            messages: msgs,
            type: ErrorType.validation,
            code: statusCode,
            raw: data,
          );
        }

        // ── 3. message field ──────────────────────────────────────────────
        final msg = data['message'];
        if (msg != null) {
          return AppException(
            msg.toString(),
            type: _mapType(statusCode),
            code: statusCode,
            raw: data,
          );
        }
      }

      // ── 4. generic fallback ───────────────────────────────────────────────
      return AppException(
        'Có lỗi xảy ra',
        type: _mapType(statusCode),
        code: statusCode,
        raw: data,
      );
    } catch (_) {
      return AppException(
        'Có lỗi xảy ra',
        type: ErrorType.unknown,
        code: statusCode,
        raw: data,
      );
    }
  }

  /// Map HTTP status code → [ErrorType].
  static ErrorType _mapType(int? statusCode) {
    if (statusCode == null) return ErrorType.unknown;
    if (statusCode == 401) return ErrorType.unauthorized;
    if (statusCode >= 400 && statusCode < 500) return ErrorType.validation;
    if (statusCode >= 500) return ErrorType.server;
    return ErrorType.unknown;
  }
}
