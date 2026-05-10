// lib/core/network/api_interceptor.dart

import 'dart:async';

import 'package:dio/dio.dart';

import '../guards/auth_guard.dart';
import '../services/auth_service.dart';
import '../session/user_session.dart';

class ApiInterceptor extends Interceptor {
  final Dio dio;

  final UserSession _session = UserSession();

  ApiInterceptor(this.dio);

  bool _isRefreshing = false;

  final List<_PendingRequest> _queue = [];

  // ─────────────────────────────────────────────────────────────
  // REQUEST
  // ─────────────────────────────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final token = _session.accessToken;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  // ─────────────────────────────────────────────────────────────
  // RESPONSE
  // ─────────────────────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR
  // ─────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;

    // Không phải 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Request retry fail -> logout
    if (request.extra['skipAuth'] == true || request.extra['isRetry'] == true) {
      await _logout();

      return handler.next(err);
    }

    // Đang refresh token
    if (_isRefreshing) {
      final completer = Completer<Response>();

      _queue.add(_PendingRequest(request, completer));

      try {
        final response = await completer.future;

        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      // Refresh token
      await AuthService.instance.refreshToken();

      // Retry request hiện tại
      final response = await _retry(request);

      // Retry queue
      for (final pending in _queue) {
        try {
          final retryResponse = await _retry(pending.request);

          pending.completer.complete(retryResponse);
        } catch (e) {
          pending.completer.completeError(e);
        }
      }

      _queue.clear();

      return handler.resolve(response);
    } catch (_) {
      await _failQueue();

      await _logout();

      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RETRY REQUEST
  // ─────────────────────────────────────────────────────────────

  Future<Response> _retry(RequestOptions request) async {
    final token = _session.accessToken;

    return dio.request(
      request.path,
      data: request.data,
      queryParameters: request.queryParameters,
      options: Options(
        method: request.method,
        headers: {
          ...request.headers,

          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        extra: {...request.extra, 'isRetry': true},
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FAIL QUEUE
  // ─────────────────────────────────────────────────────────────

  Future<void> _failQueue() async {
    for (final pending in _queue) {
      pending.completer.completeError(Exception('Refresh token failed'));
    }

    _queue.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await AuthGuard.instance.logout();
  }
}

class _PendingRequest {
  final RequestOptions request;

  final Completer<Response> completer;

  _PendingRequest(this.request, this.completer);
}
