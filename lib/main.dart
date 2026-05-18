// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
// import 'package:go_router/go_router.dart';

import 'session/user_session.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.dark,
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
  final _appLinks        = AppLinks();
  StreamSubscription<Uri>? _linkSub;

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

  // ── Deep link handler ─────────────────────────────────────────
  //
  // Scheme: sportplus://payment/result?status=success&bookingId=88
  //                                 hoặc ?status=failed&bookingId=88
  //
  // Backend VNPay MobileDeepLinkUrl = "sportplus://payment/result"
  //
  // Khi user hoàn tất thanh toán trên trình duyệt VNPay, backend
  // redirect về deep link này. app_links bắt và xử lý tại đây.
  void _initDeepLinks() {
    // Xử lý link khi app đang chạy (foreground / background)
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {}, // bỏ qua lỗi parse
    );

    // Xử lý link khởi động app từ terminated state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    // Chỉ xử lý scheme sportplus://payment/result
    if (uri.scheme != 'sportplus') return;
    if (uri.host != 'payment') return;
    if (uri.path != '/result') return;

    final status    = uri.queryParameters['status']    ?? '';
    final bookingId = int.tryParse(
      uri.queryParameters['bookingId'] ?? '',
    );

    if (bookingId == null) return;

    final router = AppRouter.router;

    if (status == 'success') {
      // Navigate về booking detail để user xem trạng thái mới nhất
      // BookingDetailScreen sẽ gọi API và hiển thị Confirmed
      router.go('/booking_history/detail', extra: {'bookingId': bookingId});
    } else {
      // Thanh toán thất bại — về failure screen
      router.go(
        '/fields/failure',
        extra: {'error': 'Thanh toán không thành công. Vui lòng thử lại.'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:                    'Sport Plus',
      debugShowCheckedModeBanner: false,
      routerConfig:             AppRouter.router,
      theme:                    buildAppTheme(),
      themeMode:                ThemeMode.light,
    );
  }
}