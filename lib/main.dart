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
        await _safeNavigate(() {
          router.go(
            '/booking/failure',
            extra: {'error': 'Thanh toán không thành công. Vui lòng thử lại.'},
          );
        });
        return;
      }

      // ===================================================
      // PAYMENT SUCCESS
      // Gọi API song song với việc chờ router sẵn sàng
      // ===================================================

      BookingModel? booking;

      try {
        booking = await BookingService.instance.getBookingDetail(bookingId);
      } catch (_) {
        // Nếu API fail vẫn fallback được
      }

      await _safeNavigate(() {
        if (booking != null) {
          router.go('/booking/success', extra: {'booking': booking});
        } else {
          router.go('/booking_history/detail', extra: {'bookingId': bookingId});
        }
      });
    } catch (_) {
      // ===================================================
      // UNEXPECTED ERROR
      // ===================================================

      final router = AppRouter.router;

      await _safeNavigate(() {
        router.go(
          '/booking/failure',
          extra: {'error': 'Có lỗi xảy ra khi xử lý thanh toán.'},
        );
      });
    } finally {
      // Delay nhỏ tránh duplicate event
      await Future.delayed(const Duration(milliseconds: 300));

      _handlingDeepLink = false;
    }
  }

  // =========================================================
  // SAFE NAVIGATE
  //
  // Đảm bảo router đã mount và không còn ở /payment/result
  // trước khi navigate. Retry tối đa 20 lần (2 giây).
  //
  // Vấn đề: deep link đến khi app cold start → GoRouter chưa
  // mount xong → addPostFrameCallback bắn vào frame của
  // error page hoặc /payment/result → navigate không có hiệu lực.
  // =========================================================

  Future<void> _safeNavigate(VoidCallback navigate) async {
    // Chờ frame hiện tại render xong
    await Future.microtask(() {});

    for (int i = 0; i < 20; i++) {
      final location = AppRouter.router.routerDelegate.currentConfiguration
          .uri
          .path;

      // Router đã settle ở một route stable → navigate được rồi.
      // /splash cũng được chấp nhận vì onException redirect về đó
      // khi nhận deep link payment mà route chưa ready.
      final isReady = location == '/payment/result' ||
          location == '/splash' ||
          location == '/home' ||
          location == '/auth/login' ||
          location == '/booking/success' ||
          location == '/booking/failure';

      if (isReady) {
        navigate();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Fallback: gọi luôn dù chưa chắc ready
    navigate();
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