// lib/core/guards/auth_guard.dart

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../session/user_session.dart';

class AuthGuard extends ChangeNotifier {
  AuthGuard._();

  static final AuthGuard instance = AuthGuard._();

  final UserSession _session = UserSession();

  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;

  bool _initialized = false;

  bool _isInitializing = false;

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized || _isInitializing) {
      return;
    }

    _isInitializing = true;

    try {
      final isLoggedIn = await tryAutoLogin();

      _setStatus(
        isLoggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _initialized = true;
      _isInitializing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO LOGIN
  // ─────────────────────────────────────────────────────────────

  Future<bool> tryAutoLogin() async {
    try {
      // Load session từ secure storage
      final loaded = await _session.load();

      if (!loaded) {
        return false;
      }

      // Có access token
      final accessToken = _session.token;

      if (accessToken != null && accessToken.isNotEmpty) {
        return true;
      }

      // Có refresh token thì refresh
      final refreshToken = _session.refreshToken;

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await AuthService.refreshToken();

        return true;
      }

      return false;
    } catch (_) {
      await _session.clear();

      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.logout();

    _setStatus(AuthStatus.unauthenticated);
  }

  // ─────────────────────────────────────────────────────────────
  // STATUS
  // ─────────────────────────────────────────────────────────────

  void _setStatus(AuthStatus status) {
    if (_status == status) {
      return;
    }

    _status = status;

    notifyListeners();
  }

  void setAuthenticated() {
    _setStatus(AuthStatus.authenticated);
  }
}

enum AuthStatus { unknown, authenticated, unauthenticated }
