// lib/services/auth_service.dart

import '../models/user.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // POST /auth/login
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post('/auth/login', {
      'email': email.trim(),
      'password': password.trim(),
    });

    final token = data['accessToken'] as String;

    final refresh = data['refreshToken'] as String;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.instance.setToken(token);

    await UserSession().save(user: user, token: token, refreshToken: refresh);

    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // REGISTER
  // POST /auth/register
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> register({
    required String email,
    required String phone,
    required String password,
    required String fullName,
  }) async {
    final data = await ApiClient.instance.post('/auth/register', {
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password.trim(),
      'fullName': fullName.trim(),
    });

    final token = data['accessToken'] as String;

    final refresh = data['refreshToken'] as String;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    ApiClient.instance.setToken(token);

    await UserSession().save(user: user, token: token, refreshToken: refresh);

    return user;
  }

  // // ─────────────────────────────────────────────────────────────
  // // SEND OTP
  // // POST /auth/forgot-password
  // // ─────────────────────────────────────────────────────────────

  // static Future<void> sendOtp(String emailOrPhone) async {
  //   await ApiClient.post('/auth/forgot-password', {'contact': emailOrPhone});
  // }

  // // ─────────────────────────────────────────────────────────────
  // // VERIFY OTP
  // // POST /auth/verify-otp
  // // ─────────────────────────────────────────────────────────────

  // static Future<String> verifyOtp({
  //   required String emailOrPhone,
  //   required String otp,
  // }) async {
  //   final data = await ApiClient.post('/auth/verify-otp', {
  //     'contact': emailOrPhone,
  //     'otp': otp,
  //   });

  //   return data['reset_token'] as String;
  // }

  // // ─────────────────────────────────────────────────────────────
  // // RESET PASSWORD
  // // POST /auth/reset-password
  // // ─────────────────────────────────────────────────────────────

  // static Future<void> resetPassword({
  //   required String resetToken,
  //   required String newPassword,
  // }) async {
  //   await ApiClient.post('/auth/reset-password', {
  //     'reset_token': resetToken,
  //     'new_password': newPassword,
  //   });
  // }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // POST /auth/logout
  // ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/auth/logout', {});
    } catch (_) {
      // logout local dù API fail
    } finally {
      ApiClient.instance.clearToken();

      await UserSession().clear();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REFRESH TOKEN
  // POST /auth/refresh
  // ─────────────────────────────────────────────────────────────

  Future<void> refreshToken() async {
    final session = UserSession();

    final access = session.accessToken;
    final refresh = session.refreshToken;

    if (refresh == null || refresh.isEmpty) {
      throw ApiClient.instance.unauthorized('Không có refresh token');
    }

    // dùng plainDio để tránh loop interceptor
    final data = await ApiClient.instance.post('/auth/refresh', {
      'accessToken': access,
      'refreshToken': refresh,
    }, usePlainDio: true);

    final newToken = data['accessToken'] as String;

    ApiClient.instance.setToken(newToken);

    await session.updateAccessToken(newToken);

    await session.updateRefreshToken(data['refreshToken'] as String);
  }
}
