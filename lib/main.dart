// lib/main.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/booking.dart';
import 'navigation/app_router.dart';
import 'services/booking_service.dart';
import 'session/user_session.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await UserSession.instance.load();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSub;

  bool _handlingDeepLink = false;

  @override
  void initState() {
    super.initState();

    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();

    super.dispose();
  }

  // =========================================================
  // DEEP LINK
  //
  // sportplus://payment/result
  //
  // Example:
  //
  // sportplus://payment/result
  //      ?status=success
  //      &bookingId=88
  //
  // Backend flow:
  //
  // VNPay
  //   -> ReturnUrl backend
  //   -> verify checksum
  //   -> update database
  //   -> redirect deep link
  //
  // =========================================================

  void _initDeepLinks() {
    // App đang mở
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleUri(uri);
    }, onError: (_) {});

    // App cold start
    _handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();

      if (uri != null) {
        await _handleUri(uri);
      }
    } catch (_) {}
  }

  Future<void> _handleUri(Uri uri) async {
    // Tránh duplicate callback
    if (_handlingDeepLink) return;

    // =====================================================
    // VALIDATE URI
    // =====================================================

    if (uri.scheme != 'sportplus') return;

    if (uri.host != 'payment') return;

    if (uri.path != '/result') return;

    final status = uri.queryParameters['status'] ?? '';

    final bookingId = int.tryParse(uri.queryParameters['bookingId'] ?? '');

    if (bookingId == null) return;

    _handlingDeepLink = true;

    try {
      final router = AppRouter.router;

      // ===================================================
      // PAYMENT FAILED
      // ===================================================

      if (status != 'success') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go(
            '/booking/failure',
            extra: {'error': 'Thanh toán không thành công. Vui lòng thử lại.'},
          );
        });

        return;
      }

      // ===================================================
      // PAYMENT SUCCESS
      // ===================================================

      BookingModel? booking;

      try {
        // ===============================================
        // CALL API GET BOOKING DETAIL
        // ===============================================

        booking = await BookingService.instance.getBookingDetail(bookingId);
      } catch (_) {
        // Nếu API fail vẫn fallback được
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ===============================================
        // SUCCESS SCREEN
        // ===============================================

        if (booking != null) {
          router.go('/booking/success', extra: {'booking': booking});

          return;
        }

        // ===============================================
        // FALLBACK
        // ===============================================

        router.go('/booking_history/detail', extra: {'bookingId': bookingId});
      });
    } catch (_) {
      // ===================================================
      // UNEXPECTED ERROR
      // ===================================================

      final router = AppRouter.router;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(
          '/booking/failure',
          extra: {'error': 'Có lỗi xảy ra khi xử lý thanh toán.'},
        );
      });
    } finally {
      // Delay nhỏ tránh duplicate event
      await Future.delayed(const Duration(milliseconds: 500));

      _handlingDeepLink = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sport Plus',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
    );
  }
}
