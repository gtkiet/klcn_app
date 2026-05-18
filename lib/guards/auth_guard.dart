// lib/guards/auth_guard.dart

import 'package:flutter/material.dart';

import 'package:klcn_app/session/user_session.dart';
import 'package:klcn_app/services/auth_service.dart';

class AuthGuard extends ChangeNotifier {
  AuthGuard._();

  static final AuthGuard instance = AuthGuard._();

  final UserSession _session = UserSession.instance;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  bool _initialized = false;
  bool _isInitializing = false;

  // ===================== INIT GUARD =====================
  Future<void> init() async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;
    try {
      final results = await Future.wait([
        tryAutoLogin(),
        Future.delayed(const Duration(milliseconds: 2000)),
      ]);
      final isLoggedIn = results[0] as bool;
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

  // ===================== TRY AUTO LOGIN =====================
  Future<bool> tryAutoLogin() async {
    try {
      final accessToken = _session.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) return true;

      final refreshToken = _session.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final newAccess = await AuthService.instance.refreshToken();
        return newAccess != null;
      }
      return false;
    } catch (_) {
      await _session.clear();
      return false;
    }
  }

  // ===================== LOGOUT =====================
  Future<void> logout() async {
    await AuthService.instance.logout();
    setUnauthenticated(); // notify GoRouter → redirect về /auth/login
  }

  // ===================== SET STATUS =====================
  void _setStatus(AuthStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  void setAuthenticated() => _setStatus(AuthStatus.authenticated);
  void setUnauthenticated() => _setStatus(AuthStatus.unauthenticated);
}

enum AuthStatus { unknown, authenticated, unauthenticated }
