// lib/services/profile_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:klcn_app/guards/auth_guard.dart';
import 'package:klcn_app/models/user.dart';
import 'package:klcn_app/network/api_client.dart';
import 'package:klcn_app/network/media_url.dart';
import 'package:klcn_app/session/user_session.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _api = ApiClient.instance;
  final _session = UserSession.instance;

  // ── CACHE & REACTIVE ───────────────────────────────────────────

  /// Trả về UserModel từ session cache — không gọi API.
  /// Dùng để hiển thị ngay khi màn hình mở, trước khi [getProfile()] xong.
  UserModel? getCachedUser() => _session.toUserModel();

  /// Notifier avatar — widget dùng [ValueListenableBuilder] để cập nhật real-time.
  ValueNotifier<String?> get avatarUrlNotifier => _session.avatarUrlNotifier;

  // ── LOGOUT ─────────────────────────────────────────────────────

  /// Đăng xuất: gọi API logout, clear session, GoRouter redirect về /auth/login.
  Future<void> logout() => AuthGuard.instance.logout();

  // ── GET PROFILE ────────────────────────────────────────────────
  /// GET /api/profile
  /// Trả về UserModel (có nested profile{})
  Future<UserModel> getProfile() async {
    final res = await _api.get('/api/profile');
    final user = res.item(UserModel.fromJson).withFullAvatarUrl;
    await _session.updateUser(user);
    return user;
  }

  // ── UPDATE PROFILE ─────────────────────────────────────────────
  /// PUT /api/profile
  /// Body: { fullName, phone, dateOfBirth?, address? }
  /// dateOfBirth format: "YYYY-MM-DD"
  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      if (dateOfBirth != null)
        'dateOfBirth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-'
            '${dateOfBirth.month.toString().padLeft(2, '0')}-'
            '${dateOfBirth.day.toString().padLeft(2, '0')}',
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    };

    final res = await _api.put('/api/profile', body: body);
    final user = res.item(UserModel.fromJson).withFullAvatarUrl;
    await _session.updateUser(user);
    return user;
  }

  // ── CHANGE PASSWORD ────────────────────────────────────────────
  /// PUT /api/profile/change-password
  /// Body: { currentPassword, newPassword, confirmPassword }
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.put(
      '/api/profile/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  // ── UPDATE AVATAR ──────────────────────────────────────────────
  /// PUT /api/profile/avatar
  /// Body: multipart/form-data, field name = "file"
  /// Response data: String — relative path "/Uploads/avatar/..."
  Future<void> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _api.putForm('/api/profile/avatar', formData);
    final rawUrl = res.raw<String>();
    final fullUrl = rawUrl.toFullMediaUrl ?? rawUrl;

    await _session.updateAvatar(fullUrl);
  }
}
