// lib/features/auth/services/auth_service.dart
import 'dart:async';

import 'package:dio/dio.dart';

import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/session/user_session.dart';

import 'package:klcn_app/models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static final _client = ApiClient.instance;

  final _session = UserSession.instance;

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) {
      throw const AppException('Vui lòng nhập username');
    }
    if (password.trim().isEmpty) {
      throw const AppException('Vui lòng nhập password');
    }

    final res = await _client.post(
      '/api/auth/login',
      body: {'username': username.trim(), 'password': password.trim()},
    );
    final user = res.item(UserModel.fromJson);

    // if (user.accessToken.isEmpty || user.refreshToken.isEmpty) {
    //   throw const AppException('Token không hợp lệ');
    // }

    await _session.save(user);

    return user;
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────

  Future<UserModel> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await _client.post(
      '/api/auth/register',
      body: {
        'email': email.trim(),
        'password': password.trim(),
        'confirmPassword': confirmPassword.trim(),
      },
    );

    final user = res.item(UserModel.fromJson);

    return user;
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await ApiClient.instance.plainDio.post(
        '/api/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer ${_session.accessToken ?? ''}'},
        ),
      );
    } catch (_) {
      // Bỏ qua lỗi logout — luôn xoá session
    } finally {
      await _session.clear();
    }
  }

  // ── FORGOT PASSWORD ───────────────────────────────────────────────────────

  Future<String> forgotPassword({required String username}) async {
    if (username.trim().isEmpty) {
      throw const AppException('Vui lòng nhập username');
    }

    final res = await _client.post(
      '/api/auth/forgot-password',
      body: {'username': username.trim()},
    );
    return res.raw<String?>() ?? '';
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────────

  Future<String> resetPassword({
    required String username,
    required String resetCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.trim() != confirmPassword.trim()) {
      throw const AppException('Mật khẩu không khớp');
    }

    final res = await _client.post(
      '/api/auth/reset-password',
      body: {
        'username': username.trim(),
        'resetCode': resetCode.trim(),
        'newPassword': newPassword.trim(),
        'confirmPassword': confirmPassword.trim(),
      },
    );
    return res.raw<String?>() ?? '';
  }

  // ── REFRESH TOKEN ─────────────────────────────────────────────────────────

  Future<String?> refreshToken({String? refreshToken}) async {
    try {
      final token = refreshToken ?? _session.refreshToken;
      if (token == null || token.isEmpty) return null;

      // plainDio — không qua interceptor để tránh vòng lặp 401
      final response = await ApiClient.instance.plainDio.post(
        '/api/auth/refresh-token',
        data: {'refreshToken': token},
      );

      final user = response.data(UserModel.fromJson);

      if (user.accessToken.isEmpty || user.refreshToken.isEmpty) {
        throw const AppException('Token không hợp lệ');
      }

      await _session.save(user);

      return user;
    } catch (_) {
      return null;
    }
  }
}
