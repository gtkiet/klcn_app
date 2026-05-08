// lib/services/api_client.dart
// Base HTTP client — kết nối Laravel API backend

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── CONFIG ────────────────────────────────────────────────────────
// Đổi baseUrl khi deploy
const String _baseUrl = 'https://api.sportplus.vn/api';
// const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator local

// ── EXCEPTIONS ───────────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

// ── API CLIENT ────────────────────────────────────────────────────
class ApiClient {
  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken()           => _token = null;
  static bool get hasToken           => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET ──────────────────────────────────────────────────────
  static Future<dynamic> get(String path,
      {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path')
          .replace(queryParameters: params);
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handle(resp);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── POST ─────────────────────────────────────────────────────
  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final uri  = Uri.parse('$_baseUrl$path');
      final resp = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _handle(resp);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── PUT ──────────────────────────────────────────────────────
  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final uri  = Uri.parse('$_baseUrl$path');
      final resp = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _handle(resp);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── DELETE ───────────────────────────────────────────────────
  static Future<dynamic> delete(String path) async {
    try {
      final uri  = Uri.parse('$_baseUrl$path');
      final resp = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handle(resp);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  // ── RESPONSE HANDLER ─────────────────────────────────────────
  static dynamic _handle(http.Response resp) {
    if (kDebugMode) {
      debugPrint('[API] ${resp.request?.method} ${resp.request?.url} → ${resp.statusCode}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body;
    }
    final msg = (body is Map && body['message'] != null)
        ? body['message'] as String
        : 'Lỗi không xác định';
    throw ApiException(resp.statusCode, msg);
  }
}
