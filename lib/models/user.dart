// lib/models/user.dart
// Ánh xạ bảng Users + Profiles trong SportPlusDB

// ── ENUMS (khớp lookup tables) ──────────────────────────────────
enum UserRole { admin, staff, customer }

enum UserStatus { active, locked }

// ── USER MODEL ──────────────────────────────────────────────────
class UserModel {
  final int userId;
  final String email;
  final String phone;
  final String fullName;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Từ bảng Profiles (join)
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? address;

  const UserModel({
    required this.userId,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.dateOfBirth,
    this.address,
  });

  bool get isActive   => status == UserStatus.active;
  bool get isAdmin    => role == UserRole.admin;
  bool get isStaff    => role == UserRole.staff;
  bool get isCustomer => role == UserRole.customer;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId:      json['UserId']    as int,
      email:       json['Email']     as String,
      phone:       json['Phone']     as String,
      fullName:    json['FullName']  as String,
      role:        UserRole.values[(json['RoleId'] as int) - 1],
      status:      UserStatus.values[(json['StatusId'] as int) - 1],
      createdAt:   DateTime.parse(json['CreatedAt'] as String),
      updatedAt:   DateTime.parse(json['UpdatedAt'] as String),
      avatarUrl:   json['AvatarUrl']   as String?,
      dateOfBirth: json['DateOfBirth'] != null
          ? DateTime.parse(json['DateOfBirth'] as String)
          : null,
      address:     json['Address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'UserId':      userId,
    'Email':       email,
    'Phone':       phone,
    'FullName':    fullName,
    'RoleId':      role.index + 1,
    'StatusId':    status.index + 1,
    'CreatedAt':   createdAt.toIso8601String(),
    'UpdatedAt':   updatedAt.toIso8601String(),
    'AvatarUrl':   avatarUrl,
    'DateOfBirth': dateOfBirth?.toIso8601String(),
    'Address':     address,
  };

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? address,
    UserStatus? status,
  }) {
    return UserModel(
      userId:      userId,
      email:       email      ?? this.email,
      phone:       phone      ?? this.phone,
      fullName:    fullName   ?? this.fullName,
      role:        role,
      status:      status     ?? this.status,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
      avatarUrl:   avatarUrl  ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address:     address    ?? this.address,
    );
  }
}
