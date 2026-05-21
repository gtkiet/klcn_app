// lib/services/auth_service.dart

import 'package:dio/dio.dart';

import 'package:klcn_app/guards/auth_guard.dart';
import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/network/media_url.dart';
import 'package:klcn_app/session/user_session.dart';
import 'package:klcn_app/models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _session = UserSession.instance;
  final _guard = AuthGuard.instance;

  // ── LOGIN ──────────────────────────────────────────────────────
  /// POST /api/auth/login
  /// Body: { identifier, password }
  /// identifier = email hoặc số điện thoại
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _client.post(
      '/api/auth/login',
      body: {'identifier': identifier.trim(), 'password': password},
    );

    final auth = res.item(AuthResponse.fromJson).withFullAvatarUrl;
    await _session.save(auth);
    _guard.setAuthenticated();
    return auth;
  }

  // ── REGISTER ───────────────────────────────────────────────────
  /// POST /api/auth/register
  /// Body: { email, phone, password, fullName }
  Future<AuthResponse> register({
    required String email,
    required String phone,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.post(
      '/api/auth/register',
      body: {
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'fullName': fullName.trim(),
      },
    );

    final auth = res.item(AuthResponse.fromJson).withFullAvatarUrl;
    await _session.save(auth);
    _guard.setAuthenticated();
    return auth;
  }

  // ── FORGOT PASSWORD ────────────────────────────────────────────
  /// POST /api/auth/forgot-password
  /// Body: { email }
  /// Server gửi OTP về email — response data là String message
  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/api/auth/forgot-password',
      body: {'email': email.trim()},
    );
  }

  // ── VERIFY OTP ─────────────────────────────────────────────────
  /// POST /api/auth/verify-otp
  /// Body: { email, otp }
  /// Response data: { resetToken }
  Future<String> verifyOtp({required String email, required String otp}) async {
    final res = await _client.post(
      '/api/auth/verify-otp',
      body: {'email': email.trim(), 'otp': otp.trim()},
    );
    final data = res.raw<Map<String, dynamic>>();
    return data['resetToken'] as String;
  }

  // ── RESET PASSWORD ─────────────────────────────────────────────
  /// POST /api/auth/reset-password
  /// Body: { resetToken, newPassword, confirmPassword }
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post(
      '/api/auth/reset-password',
      body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  // ── LOGOUT ─────────────────────────────────────────────────────
  /// POST /api/auth/logout  (Bearer token required)
  /// Luôn clear session dù API có lỗi hay không.
  Future<void> logout() async {
    try {
      await _client.plainDio.post(
        '/api/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer ${_session.accessToken ?? ''}'},
        ),
      );
    } catch (_) {
      // Bỏ qua lỗi mạng — session vẫn bị xoá
    } finally {
      await _session.clear();
    }
  }

  // ── REFRESH TOKEN ──────────────────────────────────────────────
  /// POST /api/auth/refresh-token
  /// Body: { accessToken, refreshToken }
  /// Trả về access token mới, hoặc null nếu thất bại.
  /// Dùng plainDio để tránh vòng lặp interceptor 401.
  Future<String?> refreshToken() async {
    try {
      final rToken = _session.refreshToken;
      final aToken = _session.accessToken;
      if (rToken == null || rToken.isEmpty) return null;

      final response = await _client.plainDio.post(
        '/api/auth/refresh-token',
        data: {'accessToken': aToken ?? '', 'refreshToken': rToken},
      );

      final map = response.data as Map<String, dynamic>;
      final ok = map['success'] as bool? ?? false;
      if (!ok) return null;

      final tokens = TokenResponse.fromJson(
        map['data'] as Map<String, dynamic>,
      );
      await _session.updateTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.accessToken;
    } catch (_) {
      return null;
    }
  }
}
