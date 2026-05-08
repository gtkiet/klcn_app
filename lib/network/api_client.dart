// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/errors.dart';
import 'api_interceptor.dart';

// ───────────────────────────────────────────────────────────────
// CONFIG
// ───────────────────────────────────────────────────────────────

const String _baseUrl = 'http://klcnhost-001-site1.ntempurl.com';

// ───────────────────────────────────────────────────────────────
// API CLIENT
// ───────────────────────────────────────────────────────────────

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  // cache token
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static bool get hasToken => _token != null;

  // ───────────────────────────────────────────────────────────
  // COMMON EXCEPTIONS
  // ───────────────────────────────────────────────────────────

  static Exception unauthorized(String message) {
    return AppException(message, type: ErrorType.unauthorized, code: 401);
  }

  static Exception network(String message) {
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

  static Future<dynamic> get(
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

  static Future<dynamic> post(
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

  static Future<dynamic> put(
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

  static Future<dynamic> delete(String path, {bool usePlainDio = false}) async {
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

  static AppException _handleDioError(DioException e) {
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
