// lib/core/storage/user_session.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:klcn_app/models/user.dart';

abstract class _K {
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
  static const expiresAt = 'expiresAt';
  static const userId = 'userId';
  static const fullName = 'fullName';
  static const email = 'email';
  static const phone = 'phone';
  static const role = 'role';
  static const roleId = 'roleId';
  static const status = 'status';
  static const statusId = 'statusId';
  static const avatarUrl = 'avatarUrl';
  static const createdAt = 'createdAt';
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
  ///     valueListenable: UserSession.instance.avatarUrlNotifier,
  ///     builder: (context, url, _) => ...,
  ///   )
  final avatarUrlNotifier = ValueNotifier<String?>(null);

  String? get avatarUrl => avatarUrlNotifier.value;

  // ── Các field sync (đọc sau khi load()) ──────────────────────────────────

  String? accessToken;
  String? refreshToken;
  String? expiresAt;
  String? userId;
  String? fullName;
  String? email;
  String? phone;
  String? role;
  String? roleId;
  String? status;
  String? statusId;
  String? createdAt;

  bool get isLoggedIn => accessToken?.isNotEmpty == true;

  // ── Khởi động app ─────────────────────────────────────────────────────────

  /// Gọi một lần trong main() trước runApp().
  Future<void> load() async {
    final values = await Future.wait([
      _storage.read(key: _K.accessToken),
      _storage.read(key: _K.refreshToken),
      _storage.read(key: _K.expiresAt),
      _storage.read(key: _K.userId),
      _storage.read(key: _K.fullName),
      _storage.read(key: _K.email),
      _storage.read(key: _K.phone),
      _storage.read(key: _K.role),
      _storage.read(key: _K.roleId),
      _storage.read(key: _K.status),
      _storage.read(key: _K.statusId),
      _storage.read(key: _K.avatarUrl),
      _storage.read(key: _K.createdAt),
    ]);

    accessToken = values[0];
    refreshToken = values[1];
    expiresAt = values[2];
    userId = values[3];
    fullName = values[4];
    email = values[5];
    phone = values[6];
    role = values[7];
    roleId = values[8];
    status = values[9];
    statusId = values[10];
    createdAt = values[12];

    // Gán thẳng vào .value — không trigger notify vì chưa có widget lắng nghe
    avatarUrlNotifier.value = values[11];
  }

  // ── Đăng nhập ─────────────────────────────────────────────────────────────

  Future<void> save(AuthResponse auth) async {
    accessToken = auth.accessToken;
    refreshToken = auth.refreshToken;
    expiresAt = auth.expiresAt.toIso8601String();
    var user = auth.user;
    userId = user.userId.toString();
    fullName = user.fullName;
    email = user.email;
    phone = user.phone;
    role = user.role;
    roleId = user.roleId.toString();
    status = user.status;
    statusId = user.statusId.toString();
    createdAt = user.createdAt.toIso8601String();

    avatarUrlNotifier.value = user.avatarUrl;

    await Future.wait([
      _storage.write(key: _K.accessToken, value: accessToken),
      _storage.write(key: _K.refreshToken, value: refreshToken),
      _storage.write(key: _K.expiresAt, value: expiresAt),
      _storage.write(key: _K.userId, value:userId),
      _storage.write(key: _K.fullName, value: fullName),
      _storage.write(key: _K.email, value: email),
      _storage.write(key: _K.phone, value: phone),
      _storage.write(key: _K.role, value: role),
      _storage.write(key: _K.roleId, value: roleId),
      _storage.write(key: _K.status, value: status),
      _storage.write(key: _K.statusId, value: statusId),
      _storage.write(key: _K.avatarUrl, value: avatarUrlNotifier.value),
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
    avatarUrlNotifier.value = newUrl;
    await _storage.write(key: _K.avatarUrl, value: newUrl);
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────────

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    expiresAt = null;
    userId = null;
    fullName = null;
    email = null;
    phone = null;
    role = null;
    roleId = null;
    status = null;
    statusId = null;
    createdAt = null;

    avatarUrlNotifier.value = null;

    await _storage.deleteAll();
  }
}
