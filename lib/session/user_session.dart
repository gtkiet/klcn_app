// lib/session/user_session.dart

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
  static const dateOfBirth = 'dateOfBirth';
  static const address = 'address';
}

class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions());

  // ── Reactive fields (rebuild widgets khi thay đổi) ────────────────────
  final avatarUrlNotifier = ValueNotifier<String?>(null);
  String? get avatarUrl => avatarUrlNotifier.value;

  // ── Sync fields (đọc sau khi load()) ─────────────────────────────────
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
  String? dateOfBirth;
  String? address;

  bool get isLoggedIn => accessToken?.isNotEmpty == true;

  // ── Khởi động app ─────────────────────────────────────────────────────

  /// Gọi một lần trong main() trước runApp().
  Future<void> load() async {
    final values = await Future.wait([
      _storage.read(key: _K.accessToken), // 0
      _storage.read(key: _K.refreshToken), // 1
      _storage.read(key: _K.expiresAt), // 2
      _storage.read(key: _K.userId), // 3
      _storage.read(key: _K.fullName), // 4
      _storage.read(key: _K.email), // 5
      _storage.read(key: _K.phone), // 6
      _storage.read(key: _K.role), // 7
      _storage.read(key: _K.roleId), // 8
      _storage.read(key: _K.status), // 9
      _storage.read(key: _K.statusId), // 10
      _storage.read(key: _K.avatarUrl), // 11
      _storage.read(key: _K.createdAt), // 12
      _storage.read(key: _K.dateOfBirth), // 13
      _storage.read(key: _K.address), // 14
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
    dateOfBirth = values[13];
    address = values[14];

    // Gán trực tiếp — chưa có widget lắng nghe ở thời điểm này
    avatarUrlNotifier.value = values[11];
  }

  // ── Đăng nhập (AuthResponse từ login / register) ───────────────────────

  Future<void> save(AuthResponse auth) async {
    final user = auth.user;

    accessToken = auth.accessToken;
    refreshToken = auth.refreshToken;
    expiresAt = auth.expiresAt.toIso8601String();
    userId = user.userId.toString();
    fullName = user.fullName;
    email = user.email;
    phone = user.phone;
    role = user.role;
    roleId = user.roleId.toString();
    status = user.status;
    statusId = user.statusId.toString();
    createdAt = user.createdAt.toIso8601String();
    dateOfBirth = user.dateOfBirth?.toIso8601String();
    address = user.address;

    avatarUrlNotifier.value = user.avatarUrl;

    await Future.wait([
      _storage.write(key: _K.accessToken, value: accessToken),
      _storage.write(key: _K.refreshToken, value: refreshToken),
      _storage.write(key: _K.expiresAt, value: expiresAt),
      _storage.write(key: _K.userId, value: userId),
      _storage.write(key: _K.fullName, value: fullName),
      _storage.write(key: _K.email, value: email),
      _storage.write(key: _K.phone, value: phone),
      _storage.write(key: _K.role, value: role),
      _storage.write(key: _K.roleId, value: roleId),
      _storage.write(key: _K.status, value: status),
      _storage.write(key: _K.statusId, value: statusId),
      _storage.write(key: _K.avatarUrl, value: avatarUrlNotifier.value),
      _storage.write(key: _K.createdAt, value: createdAt),
      _storage.write(key: _K.dateOfBirth, value: dateOfBirth),
      _storage.write(key: _K.address, value: address),
    ]);
  }

  // ── Cập nhật profile (từ GET/PUT /api/profile) ────────────────────────

  Future<void> updateUser(UserModel user) async {
    fullName = user.fullName;
    phone = user.phone;
    email = user.email;
    dateOfBirth = user.dateOfBirth?.toIso8601String();
    address = user.address;

    avatarUrlNotifier.value = user.avatarUrl;

    await Future.wait([
      _storage.write(key: _K.fullName, value: fullName),
      _storage.write(key: _K.phone, value: phone),
      _storage.write(key: _K.email, value: email),
      _storage.write(key: _K.avatarUrl, value: avatarUrlNotifier.value),
      _storage.write(key: _K.dateOfBirth, value: dateOfBirth),
      _storage.write(key: _K.address, value: address),
    ]);
  }

  // ── Refresh token ─────────────────────────────────────────────────────

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

  // ── Đổi avatar ────────────────────────────────────────────────────────

  Future<void> updateAvatar(String newUrl) async {
    avatarUrlNotifier.value = newUrl;
    await _storage.write(key: _K.avatarUrl, value: newUrl);
  }

  // ── Build UserModel từ session (dùng khi cần model cục bộ) ───────────

  UserModel? toUserModel() {
    if (userId == null) return null;
    return UserModel(
      userId: int.tryParse(userId ?? '') ?? 0,
      email: email ?? '',
      phone: phone ?? '',
      fullName: fullName ?? '',
      role: role ?? '',
      roleId: int.tryParse(roleId ?? '') ?? 0,
      status: status ?? '',
      statusId: int.tryParse(statusId ?? '') ?? 0,
      createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
      profile: ProfileModel(
        avatarUrl: avatarUrl,
        dateOfBirth: dateOfBirth != null
            ? DateTime.tryParse(dateOfBirth!)
            : null,
        address: address,
      ),
    );
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────

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
    dateOfBirth = null;
    address = null;

    avatarUrlNotifier.value = null;

    await _storage.deleteAll();
  }
}
