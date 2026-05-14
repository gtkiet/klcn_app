// lib/services/profile_service.dart

import 'package:dio/dio.dart';

import '../models/user.dart';
import '../network/api_client.dart';
import '../network/media_url.dart';
import '../session/user_session.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _api = ApiClient.instance;
  final _session = UserSession.instance;

  // ─────────────────────────────────────────────────────────────
  // LẤY PROFILE
  // GET /api/profile
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final res = await _api.get('/api/profile');
    final user = res.item(UserModel.fromJson).withFullAvatarUrl;
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
    final user = res.item(UserModel.fromJson).withFullAvatarUrl;
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

    final res = await _api.putForm('/api/profile/avatar', formData);
    final fullUrl = res.raw<String>().toFullMediaUrl ?? res.raw<String>();

    await _session.updateAvatar(fullUrl);
    return fullUrl;
  }
}