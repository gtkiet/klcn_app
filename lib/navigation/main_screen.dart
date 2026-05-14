// lib/navigation/main_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'app_navigation.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainScreen({super.key, required this.shell});

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    AppNavigation.setShell(shell);
    // AppNavigation.setRouter(GoRouter.of(context));
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navUnselected,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Sân bóng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
