// lib/services/user_session.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

class _SessionKeys {
  static const user = 'user';

  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
}

class UserSession {
  UserSession._internal();

  static final UserSession _instance = UserSession._internal();

  factory UserSession() => _instance;

  // Secure storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache memory
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  UserModel? get currentUser => _user;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  bool get isLoggedIn =>
      _user != null && _accessToken != null && _accessToken!.isNotEmpty;

  bool get isAdmin => _user?.isAdmin ?? false;

  bool get isStaff => _user?.isStaff ?? false;

  bool get isCustomer => _user?.isCustomer ?? false;

  // ─────────────────────────────────────────────────────────────
  // Save full session
  // ─────────────────────────────────────────────────────────────

  Future<void> save({
    required UserModel user,
    required String token,
    required String refreshToken,
  }) async {
    _user = user;
    _accessToken = token;
    _refreshToken = refreshToken;

    await Future.wait([
      _storage.write(key: _SessionKeys.user, value: jsonEncode(user.toJson())),

      _storage.write(key: _SessionKeys.accessToken, value: token),

      _storage.write(key: _SessionKeys.refreshToken, value: refreshToken),
    ]);
  }

  // ─────────────────────────────────────────────────────────────
  // Load session khi app start
  // ─────────────────────────────────────────────────────────────

  Future<bool> load() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _SessionKeys.user),
        _storage.read(key: _SessionKeys.accessToken),
        _storage.read(key: _SessionKeys.refreshToken),
      ]);

      final userJson = results[0];
      final accessToken = results[1];
      final refreshToken = results[2];

      if (userJson == null || accessToken == null || accessToken.isEmpty) {
        return false;
      }

      _user = UserModel.fromJson(jsonDecode(userJson));

      _accessToken = accessToken;
      _refreshToken = refreshToken;

      return true;
    } catch (e) {
      await clear();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Update access token
  // ─────────────────────────────────────────────────────────────

  Future<void> updateAccessToken(String newAccessToken) async {
    _accessToken = newAccessToken;

    await _storage.write(key: _SessionKeys.accessToken, value: newAccessToken);
  }

  // ─────────────────────────────────────────────────────────────
  // Update refresh token
  // ─────────────────────────────────────────────────────────────

  Future<void> updateRefreshToken(String newRefreshToken) async {
    _refreshToken = newRefreshToken;

    await _storage.write(
      key: _SessionKeys.refreshToken,
      value: newRefreshToken,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Update user profile
  // ─────────────────────────────────────────────────────────────

  Future<void> updateUser(UserModel user) async {
    _user = user;

    await _storage.write(
      key: _SessionKeys.user,
      value: jsonEncode(user.toJson()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Clear session / logout
  // ─────────────────────────────────────────────────────────────

  Future<void> clear() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;

    await Future.wait([
      _storage.delete(key: _SessionKeys.user),
      _storage.delete(key: _SessionKeys.accessToken),
      _storage.delete(key: _SessionKeys.refreshToken),
    ]);
  }

  // ─────────────────────────────────────────────────────────────
  // Check session
  // ─────────────────────────────────────────────────────────────

  Future<bool> hasSession() async {
    final token = await _storage.read(key: _SessionKeys.accessToken);

    return token != null && token.isNotEmpty;
  }
}
