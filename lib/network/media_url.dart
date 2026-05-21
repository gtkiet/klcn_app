// lib/network/media_url.dart
// ─────────────────────────────────────────────────────────────────────────────
// Helper: chuẩn hoá URL media trả về từ server.
//
// Server trả path tương đối "/Uploads/avatar/..."
// → ghép với baseUrl thành full URL trước khi lưu session / hiển thị UI.
//
// Dùng extension để gọi trực tiếp trên String? và các model,
// không cần class hay singleton.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:klcn_app/models/user.dart';
import 'package:klcn_app/network/api_client.dart';

// ── String? extension ────────────────────────────────────────────────────────

extension MediaUrlX on String? {
  /// Trả về full URL nếu là path tương đối, giữ nguyên nếu đã là http.
  /// Trả về null nếu rỗng.
  String? get toFullMediaUrl {
    final path = this;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiClient.baseUrl}$path';
  }
}

// ── UserModel extension ───────────────────────────────────────────────────────

extension UserModelMediaX on UserModel {
  /// Trả về bản sao với avatarUrl đã được prefix đầy đủ.
  /// Nếu không cần thay đổi, trả về chính object gốc (không tạo object mới).
  UserModel get withFullAvatarUrl {
    final raw = profile?.avatarUrl;
    final full = raw.toFullMediaUrl;
    if (full == raw) return this;
    return copyWith(
      profile:
          profile?.copyWith(avatarUrl: full) ?? ProfileModel(avatarUrl: full),
    );
  }
}

// ── AuthResponse extension ────────────────────────────────────────────────────

extension AuthResponseMediaX on AuthResponse {
  /// Trả về bản sao với avatarUrl trong user đã được prefix đầy đủ.
  AuthResponse get withFullAvatarUrl {
    final patchedUser = user.withFullAvatarUrl;
    if (identical(patchedUser, user)) return this;
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      user: patchedUser,
    );
  }
}
