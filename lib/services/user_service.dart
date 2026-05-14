// lib/services/user_service.dart

import 'package:dio/dio.dart';

import '../models/user.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _api     = ApiClient.instance;
  final _session = UserSession.instance;

  // ─────────────────────────────────────────────────────────────
  // LẤY PROFILE
  // GET /api/profile
  // Response: { success, data: { userId, fullName, email, phone,
  //             role, roleId, status, statusId, createdAt,
  //             profile: { avatarUrl, dateOfBirth, address } } }
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final res  = await _api.get('/api/profile');
    final user = res.item(UserModel.fromJson);
    await _session.updateUser(user);
    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // CẬP NHẬT PROFILE
  // PUT /api/profile
  // Body: { fullName, phone, dateOfBirth?, address? }
  // Response: same as GET /api/profile
  // ─────────────────────────────────────────────────────────────

  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
    String? dateOfBirth, // "YYYY-MM-DD"
    String? address,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'phone':    phone.trim(),
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'dateOfBirth': dateOfBirth,
      if (address != null && address.isNotEmpty)
        'address': address.trim(),
    };

    final res  = await _api.put('/api/profile', body: body);
    final user = res.item(UserModel.fromJson);
    await _session.updateUser(user);
    return user;
  }

  // ─────────────────────────────────────────────────────────────
  // ĐỔI MẬT KHẨU
  // PUT /api/profile/change-password
  // Body: { currentPassword, newPassword, confirmPassword }
  // Response: { success, message, data: string }
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
        'newPassword':     newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CẬP NHẬT AVATAR
  // PUT /api/profile/avatar
  // Body: multipart/form-data  field name = "file"
  // Response: { success, message, data: string (url) }
  // ─────────────────────────────────────────────────────────────

  Future<String> updateAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _api.postForm('/api/profile/avatar', formData);

    // data là String (URL ảnh mới)
    final newUrl = res.raw<String>();
    await _session.updateAvatar(newUrl);
    return newUrl;
  }
}