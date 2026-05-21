// lib/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../guards/auth_guard.dart';
import '../models/booking.dart';
import 'main_screen.dart';

import '../screens/splash/splash_screen.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';

import '../screens/home/home_screen.dart';

import '../screens/field/field_list_screen.dart';
import '../screens/field/field_detail_screen.dart';

import '../screens/booking/booking_confirmation_screen.dart';
import '../screens/booking/booking_success_screen.dart';
import '../screens/booking/booking_failure_screen.dart';
import '../screens/booking/booking_history_screen.dart';
import '../screens/booking/booking_detail_screen.dart';

import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/notification/notification_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: AuthGuard.instance,

    // ── REDIRECT ────────────────────────────────────────────────────────────
    redirect: (context, state) {
      final status = AuthGuard.instance.status;
      final location = state.uri.path;

      final isAuthRoute = location.startsWith('/auth');
      final isSplash = location == '/splash';

      // Deep link payment result — không redirect, để main.dart xử lý
      if (location == '/payment/result') return null;

      if (status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : '/auth/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplash) return '/home';
      }

      return null;
    },

    // ── ROUTES ──────────────────────────────────────────────────────────────
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),

      // ── Auth group ────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth',
        redirect: (_, state) =>
            state.uri.path == '/auth' ? '/auth/login' : null,
        routes: [
          GoRoute(path: 'login', builder: (_, _) => const LoginScreen()),
          GoRoute(path: 'register', builder: (_, _) => const RegisterScreen()),
          GoRoute(
            path: 'forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'otp-verification',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return OtpVerificationScreen(
                email: extra['email'] as String? ?? '',
              );
            },
          ),
          GoRoute(
            path: 'reset-password',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ResetPasswordScreen(
                resetToken: extra['resetToken'] as String? ?? '',
              );
            },
          ),
        ],
      ),

      // ── Field detail + Booking flow (ngoài shell — không có bottom nav) ──
      //
      // Lý do để ngoài StatefulShellRoute:
      //   • StatefulShellBranch chỉ navigate được trong branch của nó.
      //   • Booking flow cần full-screen stack, không có bottom nav.
      //   • extra được truyền qua context.push(..., extra: {...}) theo từng bước.
      //
      // Flow:
      //   /fields/detail          ← extra: FieldModel
      //     → /fields/confirm     ← extra: { field, date, slots }
      //       → /fields/success   ← extra: { booking, remainderMethod }
      //       → /fields/failure   ← extra: { error }
      GoRoute(
        path: '/fields/detail',
        builder: (_, _) => const FieldDetailScreen(),
      ),
      GoRoute(
        path: '/fields/confirm',
        builder: (_, _) => const BookingConfirmationScreen(),
      ),
      GoRoute(
        path: '/booking/success',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BookingSuccessScreen(
            key: state.pageKey,
            booking: extra['booking'] as BookingModel?,
          );
        },
      ),
      // Payment failure
      GoRoute(
        path: '/booking/failure',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return BookingFailureScreen(
            key: state.pageKey,
            errorMessage: extra['error'] as String?,
          );
        },
      ),

      // ── Booking detail (ngoài shell — push từ booking history hoặc deep link) ──
      //
      // extra: BookingSummary | BookingModel | { 'bookingId': int }
      GoRoute(
        path: '/booking_history/detail',
        builder: (_, _) => const BookingDetailScreen(),
      ),

      // ── Notifications (ngoài shell — push từ home bell icon) ─────────────────
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationScreen(),
      ),

      // ── Main shell — 4 tabs (có bottom nav) ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(shell: navigationShell),
        branches: [
          // Tab 0 — Trang chủ
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),

          // Tab 1 — Sân bóng
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fields',
                builder: (_, _) => const FieldListScreen(),
              ),
            ],
          ),

          // Tab 2 — Lịch sử đặt sân
          //   /booking_history            → BookingHistoryScreen
          //   Tap vào booking             → context.push('/booking_history/detail', extra: {'bookingId': id})
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/booking_history',
                builder: (_, _) => const BookingHistoryScreen(),
              ),
            ],
          ),

          // Tab 3 — Hồ sơ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit_profile',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change_password',
                    builder: (_, _) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    // ── ERROR PAGE ──────────────────────────────────────────────────────────
    //
    // Khi GoRouter không tìm thấy route (thường do nhận deep link
    // sportplus://payment/result?... trước app_links), hiển thị loading.
    // app_links sẽ gọi _handleUri() và navigate sang đúng màn hình ngay sau.
    errorBuilder: (context, state) {
      final path = state.uri.path;

      // Deep link payment → show loading, app_links sẽ navigate
      if (path == '/result') {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Các route lỗi khác → về home
      return Scaffold(
        body: Center(child: Text('Không tìm thấy trang: $path')),
      );
    },
  );
}