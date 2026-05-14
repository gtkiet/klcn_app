// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'session/user_session.dart';
// import 'guards/auth_guard.dart';
import 'navigation/app_router.dart';

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

  // await AuthGuard.instance.init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sport Plus',

      debugShowCheckedModeBanner: false,

      routerConfig: AppRouter.router,

      // ── Apply the design system theme ──────────────────────────────────────
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
    );
  }
}
