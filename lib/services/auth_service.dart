// lib/services/auth_service.dart

import '../models/user.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

class AuthService {
  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // POST /auth/login
  // ─────────────────────────────────────────────────────────────

  static Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/login', {
      'phone': phone,
      'password': password,
    });

    final token = data['token'] as String;

    final refresh = data['refresh_token'] as String;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.setToken(token);

    await UserSession().save(user: user, token: token, refreshToken: refresh);

    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // REGISTER
  // POST /auth/register
  // ─────────────────────────────────────────────────────────────

  static Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/register', {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password': password,
    });

    final token = data['token'] as String;

    final refresh = data['refresh_token'] as String;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.setToken(token);

    await UserSession().save(user: user, token: token, refreshToken: refresh);

    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // SEND OTP
  // POST /auth/forgot-password
  // ─────────────────────────────────────────────────────────────

  static Future<void> sendOtp(String emailOrPhone) async {
    await ApiClient.post('/auth/forgot-password', {'contact': emailOrPhone});
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFY OTP
  // POST /auth/verify-otp
  // ─────────────────────────────────────────────────────────────

  static Future<String> verifyOtp({
    required String emailOrPhone,
    required String otp,
  }) async {
    final data = await ApiClient.post('/auth/verify-otp', {
      'contact': emailOrPhone,
      'otp': otp,
    });

    return data['reset_token'] as String;
  }

  // ─────────────────────────────────────────────────────────────
  // RESET PASSWORD
  // POST /auth/reset-password
  // ─────────────────────────────────────────────────────────────

  static Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/reset-password', {
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CHANGE PASSWORD
  // POST /auth/change-password
  // ─────────────────────────────────────────────────────────────

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // POST /auth/logout
  // ─────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // logout local dù API fail
    } finally {
      ApiClient.clearToken();

      await UserSession().clear();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH TOKEN
  // POST /auth/refresh
  // ─────────────────────────────────────────────────────────────

  static Future<void> refreshToken() async {
    final session = UserSession();

    final refresh = session.refreshToken;

    if (refresh == null || refresh.isEmpty) {
      throw ApiClient.unauthorized('Không có refresh token');
    }

    // dùng plainDio để tránh loop interceptor
    final data = await ApiClient.post('/auth/refresh', {
      'refresh_token': refresh,
    }, usePlainDio: true);

    final newToken = data['token'] as String;

    ApiClient.setToken(newToken);

    await session.updateToken(newToken);

    // backend trả refresh token mới
    if (data['refresh_token'] != null) {
      await session.updateRefreshToken(data['refresh_token'] as String);
    }
  }
}
