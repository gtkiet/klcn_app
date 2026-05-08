// lib/core/navigation/app_navigation.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigation {
  static StatefulNavigationShell? _shell;
  static GoRouter? _router;

  static void setShell(StatefulNavigationShell shell) => _shell = shell;
  static void setRouter(GoRouter router) => _router = router; // ← thêm

  static void goTab(int index, {bool reset = true}) {
    _shell?.goBranch(index, initialLocation: reset);
  }

  static void goHome() => goTab(0);
  static void goNotification() => goTab(1);
  static void goTienIch() => goTab(2);
  static void goResidence() => goTab(3);
  static void goProfile() => goTab(4);

  /// Chuyển tab rồi push subroute — mượt, đúng tab highlight
  static void goTienIchDichVu() => _goTabThenPush(2, '/tien-ich/dich-vu');
  static void goTienIchSuaChua() => _goTabThenPush(2, '/tien-ich/sua-chua');
  static void goTienIchThiCong() => _goTabThenPush(2, '/tien-ich/thi-cong');

  static void _goTabThenPush(int tabIndex, String route) {
    // 1. Reset branch về root trước
    _shell?.goBranch(tabIndex, initialLocation: true);
    // 2. Push subroute sau 1 frame (đợi branch mount xong)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router?.push(route);
    });
  }
}
