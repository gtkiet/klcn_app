// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/field_list_screen.dart';
import 'screens/field_detail_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/booking_success_screen.dart';
import 'screens/booking_failure_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SportPlusApp());
}

class SportPlusApp extends StatelessWidget {
  const SportPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Plus',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/otp_verification': (context) => const OtpVerificationScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/fields': (context) => const FieldListScreen(),
        '/field_detail': (context) => const FieldDetailScreen(),
        '/booking_confirm': (context) => const BookingConfirmationScreen(),
        '/booking_success': (context) => const BookingSuccessScreen(),
        '/booking_failure': (context) => const BookingFailureScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(),
        '/booking_detail': (context) => const BookingDetailScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}
