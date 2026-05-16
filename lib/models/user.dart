// lib/models/user.dart

// ── PROFILE MODEL ─────────────────────────────────────────────────
// Nested trong GET /api/profile response
class ProfileModel {
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? address;

  const ProfileModel({
    this.avatarUrl,
    this.dateOfBirth,
    this.address,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        avatarUrl: json['avatarUrl'] as String?,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'] as String)
            : null,
        address: json['address'] as String?,
      );

  ProfileModel copyWith({
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? address,
  }) =>
      ProfileModel(
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        address: address ?? this.address,
      );
}

// ── USER MODEL ────────────────────────────────────────────────────
// Dùng cho GET /api/profile (có nested profile{})
// và auth response (user{} phẳng, avatarUrl trực tiếp)
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

  // Chỉ có trong GET /api/profile — null với auth response
  final ProfileModel? profile;

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
    this.profile,
  });

  // ── Convenience getters ────────────────────────────────────────
  String? get avatarUrl    => profile?.avatarUrl;
  DateTime? get dateOfBirth => profile?.dateOfBirth;
  String? get address      => profile?.address;

  bool get isActive   => statusId == 1;
  bool get isAdmin    => roleId == 1;
  bool get isStaff    => roleId == 2;
  bool get isCustomer => roleId == 3;

  // ── Parse từ GET /api/profile (có nested profile{}) ───────────
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>?;
    return UserModel(
      userId:    json['userId']    as int,
      email:     json['email']     as String,
      phone:     json['phone']     as String,
      fullName:  json['fullName']  as String,
      role:      json['role']      as String,
      roleId:    json['roleId']    as int,
      status:    json['status']    as String,
      statusId:  json['statusId']  as int,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      profile:   profileJson != null ? ProfileModel.fromJson(profileJson) : null,
    );
  }

  // ── Parse từ auth response (user{} phẳng, avatarUrl trực tiếp) ─
  factory UserModel.fromAuthJson(Map<String, dynamic> json) => UserModel(
        userId:    json['userId']    as int,
        email:     json['email']     as String,
        phone:     json['phone']     as String,
        fullName:  json['fullName']  as String,
        role:      json['role']      as String,
        roleId:    json['roleId']    as int,
        status:    json['status']    as String,
        statusId:  json['statusId']  as int,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        profile:   json['avatarUrl'] != null
            ? ProfileModel(avatarUrl: json['avatarUrl'] as String?)
            : null,
      );

  UserModel copyWith({
    String? fullName,
    String? phone,
    ProfileModel? profile,
  }) =>
      UserModel(
        userId:    userId,
        email:     email,
        phone:     phone ?? this.phone,
        fullName:  fullName ?? this.fullName,
        role:      role,
        roleId:    roleId,
        status:    status,
        statusId:  statusId,
        createdAt: createdAt,
        profile:   profile ?? this.profile,
      );
}

// ── AUTH RESPONSE ─────────────────────────────────────────────────
// data{} của POST /api/auth/login và POST /api/auth/register
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
        accessToken:  json['accessToken']  as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt:    DateTime.parse(json['expiresAt'] as String),
        user:         UserModel.fromAuthJson(json['user'] as Map<String, dynamic>),
      );
}

// ── TOKEN RESPONSE ────────────────────────────────────────────────
// data{} của POST /api/auth/refresh-token
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
        accessToken:  json['accessToken']  as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt:    DateTime.parse(json['expiresAt'] as String),
      );
}