// lib/core/storage/user_session.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:klcn_app/models/user.dart';

abstract class _K {
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
  static const userId = 'userId';
  static const accountId = 'accountId';
  static const username = 'username';
  static const email = 'email';
  static const fullName = 'fullName';
  static const role = 'role';
  static const anhDaiDienUrl = 'anhDaiDienUrl';
}

class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  final _storage = const FlutterSecureStorage();

  // ── Reactive field ────────────────────────────────────────────────────────
  //
  // Chỉ avatar cần reactive vì có chức năng đổi ảnh từ ProfileScreen.
  // Các field khác đọc thẳng (sync) sau khi load().

  /// Lắng nghe thay đổi avatar:
  ///   ValueListenableBuilder(
  ///     valueListenable: UserSession.instance.anhDaiDienUrlNotifier,
  ///     builder: (context, url, _) => ...,
  ///   )
  final anhDaiDienUrlNotifier = ValueNotifier<String?>(null);

  String? get anhDaiDienUrl => anhDaiDienUrlNotifier.value;

  // ── Các field sync (đọc sau khi load()) ──────────────────────────────────

  String? accessToken;
  String? refreshToken;
  String? userId;
  String? accountId;
  String? username;
  String? email;
  String? fullName;
  String? role;

  bool get isLoggedIn => accessToken?.isNotEmpty == true;

  // ── Khởi động app ─────────────────────────────────────────────────────────

  /// Gọi một lần trong main() trước runApp().
  Future<void> load() async {
    final values = await Future.wait([
      _storage.read(key: _K.accessToken), // [0]
      _storage.read(key: _K.refreshToken), // [1]
      _storage.read(key: _K.userId), // [2]
      _storage.read(key: _K.accountId), // [3]
      _storage.read(key: _K.username), // [4]
      _storage.read(key: _K.email), // [5]
      _storage.read(key: _K.fullName), // [6]
      _storage.read(key: _K.role), // [7]
      _storage.read(key: _K.anhDaiDienUrl), // [8]
    ]);

    accessToken = values[0];
    refreshToken = values[1];
    userId = values[2];
    accountId = values[3];
    username = values[4];
    email = values[5];
    fullName = values[6];
    role = values[7];

    // Gán thẳng vào .value — không trigger notify vì chưa có widget lắng nghe
    anhDaiDienUrlNotifier.value = values[8];
  }

  // ── Đăng nhập ─────────────────────────────────────────────────────────────

  Future<void> save(UserModel user) async {
    userId = user.userId.toString();
    email = user.email;
    fullName = user.fullName;
    role = user.role.name;

    anhDaiDienUrlNotifier.value = user.avatarUrl;

    await Future.wait([
      _storage.write(key: _K.userId, value: user.userId.toString()),
      _storage.write(key: _K.email, value: user.email),
      _storage.write(key: _K.fullName, value: user.fullName),
      _storage.write(key: _K.role, value: user.role.name),
      _storage.write(key: _K.anhDaiDienUrl, value: user.avatarUrl),
    ]);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _K.accessToken, value: accessToken),
      _storage.write(key: _K.refreshToken, value: refreshToken),
    ]);
  }

  // ── Đổi avatar ────────────────────────────────────────────────────────────
  //
  // Gọi từ ProfileScreen sau khi upload thành công:
  //   await UserSession.instance.updateAvatar(newUrl);
  //   → HomeScreen và mọi widget đang lắng nghe tự rebuild

  Future<void> updateAvatar(String newUrl) async {
    anhDaiDienUrlNotifier.value = newUrl;
    await _storage.write(key: _K.anhDaiDienUrl, value: newUrl);
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────────

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    userId = null;
    accountId = null;
    username = null;
    email = null;
    fullName = null;
    role = null;

    anhDaiDienUrlNotifier.value = null;

    await _storage.deleteAll();
  }
}
