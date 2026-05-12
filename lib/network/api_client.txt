// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

// ───────────────────────────────────────────────────────────────
// CONFIG
// ───────────────────────────────────────────────────────────────

const String _baseUrl = 'http://klcnhost-001-site1.ntempurl.com/api';

// ───────────────────────────────────────────────────────────────
// API CLIENT
// ───────────────────────────────────────────────────────────────

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  // cache token
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  bool get hasToken => _token != null;

  // ───────────────────────────────────────────────────────────
  // COMMON EXCEPTIONS
  // ───────────────────────────────────────────────────────────

  Exception unauthorized(String message) {
    return AppException(message, type: ErrorType.unauthorized, code: 401);
  }

  Exception network(String message) {
    return AppException(message, type: ErrorType.network);
  }

  // Dio có interceptor
  late final Dio dio = _createDio();

  // Dio không interceptor
  // dùng cho refresh token
  late final Dio plainDio = _createPlainDio();

  // ───────────────────────────────────────────────────────────
  // CREATE DIO
  // ───────────────────────────────────────────────────────────

  Dio _createDio() {
    final dio = Dio(_baseOptions());

    dio.interceptors.add(ApiInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }

  Dio _createPlainDio() {
    final dio = Dio(_baseOptions());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }

  BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',

        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // GET
  // ───────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? params,
    bool usePlainDio = false,
  }) async {
    try {
      final dio = usePlainDio
          ? ApiClient.instance.plainDio
          : ApiClient.instance.dio;

      final response = await dio.get(path, queryParameters: params);

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString(), type: ErrorType.network);
    }
  }

  // ───────────────────────────────────────────────────────────
  // POST
  // ───────────────────────────────────────────────────────────

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool usePlainDio = false,
  }) async {
    try {
      final dio = usePlainDio
          ? ApiClient.instance.plainDio
          : ApiClient.instance.dio;

      final response = await dio.post(path, data: body);

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString(), type: ErrorType.network);
    }
  }

  // ───────────────────────────────────────────────────────────
  // PUT
  // ───────────────────────────────────────────────────────────

  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool usePlainDio = false,
  }) async {
    try {
      final dio = usePlainDio
          ? ApiClient.instance.plainDio
          : ApiClient.instance.dio;

      final response = await dio.put(path, data: body);

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString(), type: ErrorType.network);
    }
  }

  // ───────────────────────────────────────────────────────────
  // DELETE
  // ───────────────────────────────────────────────────────────

  Future<dynamic> delete(String path, {bool usePlainDio = false}) async {
    try {
      final dio = usePlainDio
          ? ApiClient.instance.plainDio
          : ApiClient.instance.dio;

      final response = await dio.delete(path);

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString(), type: ErrorType.network);
    }
  }

  // ───────────────────────────────────────────────────────────
  // HANDLE DIO ERROR
  // ───────────────────────────────────────────────────────────

  AppException _handleDioError(DioException e) {
    // timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AppException('Kết nối timeout', type: ErrorType.network);
    }

    // mất mạng
    if (e.response == null) {
      return AppException(
        e.message ?? 'Lỗi kết nối mạng',
        type: ErrorType.network,
      );
    }

    final statusCode = e.response?.statusCode;

    final data = e.response?.data;

    return ErrorParser.parse(data, statusCode: statusCode);
  }
}

enum ErrorType { network, unauthorized, validation, server, unknown }

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

class ErrorParser {
  ErrorParser._();
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
