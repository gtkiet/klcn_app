// lib/services/auth_service.dart

import 'package:dio/dio.dart';

import 'package:klcn_app/guards/auth_guard.dart';
import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/session/user_session.dart';
import 'package:klcn_app/models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _session = UserSession.instance;
  final _guard = AuthGuard.instance;

  // ─────────────────────────────────────────────────────────────
  // HELPER: prefix base URL cho avatar path từ server
  // Dùng chung với ProfileService — server trả "/Uploads/..."
  // ─────────────────────────────────────────────────────────────

  static String? _fullAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  /// Patch AuthResponse để avatarUrl trong user có full URL trước khi save.
  static AuthResponse _withFullAvatar(AuthResponse auth) {
    final raw = auth.user.profile?.avatarUrl;
    final full = _fullAvatarUrl(raw);
    if (full == raw) return auth;
    final patchedUser = auth.user.copyWith(
      profile:
          auth.user.profile?.copyWith(avatarUrl: full) ??
          ProfileModel(avatarUrl: full),
    );
    return AuthResponse(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      expiresAt: auth.expiresAt,
      user: patchedUser,
    );
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────
  /// POST /api/auth/login
  /// Body: { email, password }
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      throw const AppException('Vui lòng nhập email');
    }
    if (password.trim().isEmpty) {
      throw const AppException('Vui lòng nhập mật khẩu');
    }

    final res = await _client.post(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password.trim()},
    );

    final auth = _withFullAvatar(res.item(AuthResponse.fromJson));
    await _session.save(auth);
    _guard.setAuthenticated();
    return auth;
  }

  // ── REGISTER ───────────────────────────────────────────────────────────
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
        'password': password.trim(),
        'fullName': fullName.trim(),
      },
    );

    final auth = _withFullAvatar(res.item(AuthResponse.fromJson));
    await _session.save(auth);
    _guard.setAuthenticated();
    return auth;
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────
  /// POST /api/auth/logout  (Bearer token required)
  /// Chỉ clear session + gọi API — AuthGuard.logout() tự set unauthenticated.
  Future<void> logout() async {
    try {
      await _client.plainDio.post(
        '/api/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer ${_session.accessToken ?? ''}'},
        ),
      );
    } catch (_) {
      // Bỏ qua lỗi — luôn xoá session
    } finally {
      await _session.clear();
    }
  }

  // ── REFRESH TOKEN ──────────────────────────────────────────────────────
  /// POST /api/auth/refresh-token
  /// Body: { accessToken, refreshToken }
  /// Trả về access token mới, hoặc null nếu thất bại.
  Future<String?> refreshToken({String? refreshToken}) async {
    try {
      final rToken = refreshToken ?? _session.refreshToken;
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
