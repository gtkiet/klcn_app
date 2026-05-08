// lib/services/auth_service.dart
// Kết nối các API xác thực: đăng ký, đăng nhập, OTP, đặt lại mật khẩu
// Tương ứng SP: sp_HoldSlots (check user), bảng Users + RefreshTokens

import '../models/user.dart';
import 'api_client.dart';
import 'user_session.dart';

class AuthService {
  // ── ĐĂNG NHẬP ────────────────────────────────────────────────
  // POST /auth/login → { token, refresh_token, user }
  static Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/login', {
      'phone':    phone,
      'password': password,
    });
    final token   = data['token']         as String;
    final refresh = data['refresh_token'] as String;
    final user    = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.setToken(token);
    await UserSession.save(user: user, token: token, refreshToken: refresh);
    return user;
  }

  // ── ĐĂNG KÝ ──────────────────────────────────────────────────
  // POST /auth/register → { token, refresh_token, user }
  static Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/register', {
      'full_name': fullName,
      'phone':     phone,
      'email':     email,
      'password':  password,
    });
    final token   = data['token']         as String;
    final refresh = data['refresh_token'] as String;
    final user    = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.setToken(token);
    await UserSession.save(user: user, token: token, refreshToken: refresh);
    return user;
  }

  // ── GỬI OTP ──────────────────────────────────────────────────
  // POST /auth/forgot-password → { message }
  static Future<void> sendOtp(String emailOrPhone) async {
    await ApiClient.post('/auth/forgot-password', {
      'contact': emailOrPhone,
    });
  }

  // ── XÁC MINH OTP ─────────────────────────────────────────────
  // POST /auth/verify-otp → { reset_token }
  static Future<String> verifyOtp({
    required String emailOrPhone,
    required String otp,
  }) async {
    final data = await ApiClient.post('/auth/verify-otp', {
      'contact': emailOrPhone,
      'otp':     otp,
    });
    return data['reset_token'] as String;
  }

  // ── ĐẶT LẠI MẬT KHẨU ────────────────────────────────────────
  // POST /auth/reset-password → { message }
  static Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/reset-password', {
      'reset_token':  resetToken,
      'new_password': newPassword,
    });
  }

  // ── ĐỔI MẬT KHẨU (đã đăng nhập) ─────────────────────────────
  // POST /auth/change-password → { message }
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post('/auth/change-password', {
      'current_password': currentPassword,
      'new_password':     newPassword,
    });
  }

  // ── ĐĂNG XUẤT ────────────────────────────────────────────────
  // POST /auth/logout → { message }
  static Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Vẫn xóa session dù API lỗi
    } finally {
      ApiClient.clearToken();
      await UserSession.clear();
    }
  }

  // ── REFRESH TOKEN ─────────────────────────────────────────────
  // POST /auth/refresh → { token }
  static Future<void> refreshToken() async {
    final refresh = UserSession.refreshToken;
    if (refresh == null) throw const ApiException(401, 'Không có refresh token');
    final data = await ApiClient.post('/auth/refresh', {'refresh_token': refresh});
    final newToken = data['token'] as String;
    ApiClient.setToken(newToken);
    await UserSession.updateToken(newToken);
  }
}
