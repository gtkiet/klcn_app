// lib/services/user_session.dart
// Lưu trữ session người dùng cục bộ (SharedPreferences)
// Thực tế dùng flutter_secure_storage cho token

// import 'dart:convert';
import '../models/user.dart';

// TODO: Thay Map giả lập bằng SharedPreferences hoặc flutter_secure_storage
// import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static UserModel? _user;
  static String?    _token;
  static String?    _refreshToken;

  // ── Getters ──────────────────────────────────────────────────
  static UserModel? get currentUser   => _user;
  static String?    get token         => _token;
  static String?    get refreshToken  => _refreshToken;
  static bool       get isLoggedIn    => _user != null && _token != null;
  static bool       get isAdmin       => _user?.isAdmin ?? false;
  static bool       get isStaff       => _user?.isStaff ?? false;
  static bool       get isCustomer    => _user?.isCustomer ?? false;

  // ── Lưu session sau đăng nhập ────────────────────────────────
  static Future<void> save({
    required UserModel user,
    required String token,
    required String refreshToken,
  }) async {
    _user         = user;
    _token        = token;
    _refreshToken = refreshToken;

    // TODO: Thay bằng SharedPreferences thực:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('user',          jsonEncode(user.toJson()));
    // await prefs.setString('token',         token);
    // await prefs.setString('refresh_token', refreshToken);
  }

  // ── Load session khi khởi động app ───────────────────────────
  static Future<bool> load() async {
    // TODO: Thay bằng SharedPreferences thực:
    // final prefs = await SharedPreferences.getInstance();
    // final userJson = prefs.getString('user');
    // _token        = prefs.getString('token');
    // _refreshToken = prefs.getString('refresh_token');
    // if (userJson != null && _token != null) {
    //   _user = UserModel.fromJson(jsonDecode(userJson));
    //   ApiClient.setToken(_token!);
    //   return true;
    // }
    return false; // Chưa có session
  }

  // ── Cập nhật token mới (sau refresh) ─────────────────────────
  static Future<void> updateToken(String newToken) async {
    _token = newToken;
    // TODO: prefs.setString('token', newToken);
  }

  // ── Cập nhật thông tin user (sau edit profile) ────────────────
  static Future<void> updateUser(UserModel user) async {
    _user = user;
    // TODO: prefs.setString('user', jsonEncode(user.toJson()));
  }

  // ── Xóa session (đăng xuất) ──────────────────────────────────
  static Future<void> clear() async {
    _user         = null;
    _token        = null;
    _refreshToken = null;
    // TODO: prefs.clear();
  }
}
