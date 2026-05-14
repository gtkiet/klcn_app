// lib/services/profile_service.dart

import 'package:dio/dio.dart';

import '../models/user.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _api = ApiClient.instance;
  final _session = UserSession.instance;

  // ─────────────────────────────────────────────────────────────
  // HELPER: prefix base URL cho avatar path từ server
  // Server trả "/Uploads/avatar/..." — ghép thành full URL
  // trước khi lưu vào session để mọi nơi đọc ra dùng được luôn.
  // ─────────────────────────────────────────────────────────────

  static String? _fullAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }

  /// Trả về UserModel với avatarUrl đã được prefix đầy đủ.
  static UserModel _withFullAvatar(UserModel user) {
    final raw = user.profile?.avatarUrl;
    final full = _fullAvatarUrl(raw);
    if (full == raw) return user;
    return user.copyWith(
      profile:
          user.profile?.copyWith(avatarUrl: full) ??
          ProfileModel(avatarUrl: full),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LẤY PROFILE
  // GET /api/profile
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final res = await _api.get('/api/profile');
    final user = _withFullAvatar(res.item(UserModel.fromJson));
    await _session.updateUser(user);
    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // CẬP NHẬT PROFILE
  // PUT /api/profile
  // Body: { fullName, phone, dateOfBirth?, address? }
  // dateOfBirth format: "YYYY-MM-DD"
  // ─────────────────────────────────────────────────────────────

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
    final user = _withFullAvatar(res.item(UserModel.fromJson));
    await _session.updateUser(user);
    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỔI MẬT KHẨU
  // PUT /api/profile/change-password
  // Body: { currentPassword, newPassword, confirmPassword }
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // CẬP NHẬT AVATAR
  // PUT /api/profile/avatar
  // Body: multipart/form-data  field name = "file"
  // Response data: String path "/Uploads/avatar/..."
  // ─────────────────────────────────────────────────────────────

  Future<String> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _api.postForm('/api/profile/avatar', formData);
    final rawPath = res.raw<String>();
    final fullUrl = _fullAvatarUrl(rawPath) ?? rawPath;

    await _session.updateAvatar(fullUrl);
    return fullUrl;
  }
}
