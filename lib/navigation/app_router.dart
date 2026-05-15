// lib/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../guards/auth_guard.dart';
import 'main_screen.dart';

import '../screens/splash/splash_screen.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';

import '../screens/home/home_screen.dart';

import '../screens/field/field_list_screen.dart';
// import '../screens/field/field_detail_screen.dart';
// import '../screens/booking/booking_confirmation_screen.dart';
// import '../screens/booking/booking_success_screen.dart';
// import '../screens/booking/booking_failure_screen.dart';

import '../screens/booking/booking_history_screen.dart';
import '../screens/booking/booking_detail_screen.dart';

import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: AuthGuard.instance,

    /// ================= REDIRECT =================
    redirect: (context, state) {
      final status = AuthGuard.instance.status;
      final location = state.uri.path;
      debugPrint('REDIRECT: status=$status, location=$location');

      final isAuthRoute = location.startsWith('/auth');

      final isSplash = location == '/splash';

      if (status == AuthStatus.unknown) {
        return isSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        if (isAuthRoute) return null;
        return '/auth/login';
        // return isAuthRoute ? null : '/auth/login';
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplash) return '/home';
      }

      return null;
    },

    /// ================= ROUTES =================
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),

      GoRoute(
        path: '/auth',
        redirect: (_, state) {
          // Chỉ redirect khi path chính xác là /auth, không redirect subpath
          if (state.uri.path == '/auth') return '/auth/login';
          return null; // ← các subpath tự xử lý
        },
        routes: [
          GoRoute(path: 'login', builder: (_, _) => const LoginScreen()),
          GoRoute(path: 'register', builder: (_, _) => const RegisterScreen()),
          GoRoute(
            path: 'forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'otp-verification',
            builder: (_, _) => const OtpVerificationScreen(),
          ),
          GoRoute(
            path: 'reset-password',
            builder: (_, _) => const ResetPasswordScreen(),
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fields',
                builder: (_, _) => const FieldListScreen(),
                // routes: [
                //   GoRoute(
                //     path: 'detail',
                //     builder: (_, _) => const FieldDetailScreen(),
                //   ),
                //   GoRoute(
                //     path: 'booking_confirm',
                //     builder: (_, _) => const BookingConfirmationScreen(),
                //     routes: [
                //       GoRoute(
                //         path: 'booking_success',
                //         builder: (_, _) => const BookingSuccessScreen(),
                //       ),
                //       GoRoute(
                //         path: 'booking_failure',
                //         builder: (_, _) => const BookingFailureScreen(),
                //       ),
                //     ],
                //   ),
                // ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/booking_history',
                builder: (_, _) => const BookingHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, _) => const BookingDetailScreen(),
                  ),
                ],
              ),
            ],
          ),
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

    /// ================= ERROR =================
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Không tìm thấy: ${state.uri}'))),
  );
}
