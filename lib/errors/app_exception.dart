// lib/core/errors/app_exception.dart

import 'error_type.dart';

class AppException implements Exception {
  /// Message gộp để show nhanh (dùng trong Text / SnackBar).
  final String message;

  /// Danh sách lỗi chi tiết – có khi server trả về nhiều lỗi cùng lúc.
  final List<String>? messages;

  final ErrorType type;

  /// HTTP status code gốc (nếu có).
  final int? code;

  /// Giữ response body gốc để debug.
  final dynamic raw;

  const AppException(
    this.message, {
    this.messages,
    this.type = ErrorType.unknown,
    this.code,
    this.raw,
  });

  @override
  String toString() => message;
}
