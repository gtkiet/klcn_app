// lib/screens/splash_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinnerCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _fadeAnim;
  // late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _spinnerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _fadeCtrl.forward();
    _scaleCtrl.forward();

    // TODO: Thay bằng logic auth check thật
    // _navigateAfterDelay();
  }

  @override
  void dispose() {
    _spinnerCtrl.dispose();
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Decorative circles
          _DecorativeCircle(
            top: -size.width * 0.18,
            left: -size.width * 0.18,
            diameter: size.width * 0.72,
          ),
          _DecorativeCircle(
            bottom: size.height * 0.08,
            right: -size.width * 0.22,
            diameter: size.width * 0.60,
          ),

          // Content
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand logo card (animated)
                  // ScaleTransition(
                  //   scale: _scaleAnim,
                  //   child: _SplashLogoCard(size: size),
                  // ),
                  // const SizedBox(height: 28),

                  // App name
                  Text(
                    'SportPlus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.085,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _SpacedLabel('SÂN CHƠI CHIẾN THUẬT'),
                  const SizedBox(height: 28),
                  _Spinner(controller: _spinnerCtrl),
                  const SizedBox(height: 16),
                  const _SpacedLabel('MẠNG LƯỚI THỂ THAO CHUYÊN NGHIỆP'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: const Icon(Icons.arrow_forward, color: AppColors.primary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// // ── LOGO CARD ─────────────────────────────────
// class _SplashLogoCard extends StatelessWidget {
//   final Size size;
//   const _SplashLogoCard({required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 130,
//       height: 130,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.20),
//             blurRadius: 24,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.sports_soccer, color: AppColors.primary, size: 52),
//           const SizedBox(height: 6),
//           RichText(
//             text: const TextSpan(
//               children: [
//                 TextSpan(
//                   text: 'SPORT',
//                   style: TextStyle(
//                     color: AppColors.primary,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 0.8,
//                   ),
//                 ),
//                 TextSpan(
//                   text: 'PLUS',
//                   style: TextStyle(
//                     color: AppColors.primaryLight,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 0.8,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ── SPACED LABEL ──────────────────────────────
class _SpacedLabel extends StatelessWidget {
  final String text;
  const _SpacedLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 3.0,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── SPINNER ───────────────────────────────────
class _Spinner extends StatelessWidget {
  final AnimationController controller;
  const _Spinner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Transform.rotate(
        angle: controller.value * 2 * math.pi,
        child: SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(painter: _SpinnerPainter()),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── DECORATIVE CIRCLE ─────────────────────────
class _DecorativeCircle extends StatelessWidget {
  final double diameter;
  final double? top, left, bottom, right;

  const _DecorativeCircle({
    required this.diameter,
    this.top, this.left, this.bottom, this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF388E3C).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
