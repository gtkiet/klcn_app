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
    this.avatarUrl,
    this.dateOfBirth,
    this.address,
  });

  bool get isActive => status == UserStatus.active;
  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isCustomer => role == UserRole.customer;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: UserRole.values[(json['roleId'] as int) - 1],
      status: UserStatus.values[(json['statusId'] as int) - 1],
      createdAt: DateTime.parse(json['createdAt'] as String),
      // updatedAt:   DateTime.parse(json['updatedAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'roleId': role.index + 1,
    'statusId': status.index + 1,
    'createdAt': createdAt.toIso8601String(),
    // 'updatedAt':   updatedAt.toIso8601String(),
    'avatarUrl': avatarUrl,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'address': address,
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
      userId: userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role,
      status: status ?? this.status,
      createdAt: createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
    );
  }
}
