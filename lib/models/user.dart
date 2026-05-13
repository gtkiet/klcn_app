// lib/models/user.dart

// enum UserRole { admin, staff, customer }

// enum UserStatus { active, locked }

class UserModel {
  final int userId;
  final String email;
  final String phone;
  final String fullName;
  final String role;
  final int roleId;
  final String status;
  final int statusId;
  final DateTime createdAt;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? address;

  const UserModel({
    required this.userId,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.roleId,
    required this.status,
    required this.statusId,
    required this.createdAt,
    this.avatarUrl,
    this.dateOfBirth,
    this.address,
  });

  bool get isActive => statusId == 1;
  bool get isAdmin => roleId == 1;
  bool get isStaff => roleId == 2;
  bool get isCustomer => roleId == 3;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      roleId: json['roleId'] as int,
      status: json['status'] as String,
      statusId: json['statusId'] as int,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      address: json['address'] as String?,
    );
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? address,
  }) => UserModel(
    userId: userId,
    email: email,
    phone: phone ?? this.phone,
    fullName: fullName ?? this.fullName,
    role: role,
    roleId: roleId,
    status: status,
    statusId: statusId,
    createdAt: createdAt,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    address: address ?? this.address,
  );
}

/// Bọc toàn bộ data{} của login/register
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}

/// Bọc data{} của refresh-token (chỉ có tokens)
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}
