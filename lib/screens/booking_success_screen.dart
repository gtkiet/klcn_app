// lib/screens/booking_success_screen.dart

// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Nhận bookingId, stadiumName, date, timeSlot, totalPrice từ BookingConfirmationScreen

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  // static const primary = Color(0xFF2E7D32);
  // static const primaryLight = Color(0xFF4CAF50);
  static const bgPage = Color(0xFFF2F5F0);

  // Success circle
  static const circleOuter = Color(0xFFDCEADC); // pale green ring
  static const circleInner = Color(0xFF2E7D32); // solid green

  // Soccer icon (top, muted)
  static const soccerMuted = Color(0xFFCDD8CD);

  // Card
  static const cardBg = Colors.white;
  static const cardRadius = 18.0;
  static const dashedColor = Color(0xFFD4D9D4);

  // Labels / values
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
  static const textCellLabel = Color(0xFF9E9E9E);
  static const priceGreen = Color(0xFF2E7D32);
  static const headlineGreen = Color(0xFF2E7D32);
  static const supportLink = Color(0xFF2E7D32);

  // Buttons
  static const btnPrimary = Color(0xFF2E7D32);
  static const btnOutlineBg = Colors.white;
  static const btnOutlineBdr = Color(0xFFD0D5D0);

  // static const white = Colors.white;
}

abstract class _S {
  static const double pagePadH = 24.0;
  static const double btnRadius = 14.0;
  static const double btnHeight = 54.0;
}

// ─────────────────────────────────────────────
//  BOOKING SUCCESS SCREEN
// ─────────────────────────────────────────────
class BookingSuccessScreen extends StatefulWidget {
  // TODO: Tambahkan parameter ini saat integrasi:
  // final String stadiumName;
  // final String bookingCode;
  // final String date;
  // final String timeSlot;
  // final String totalPrice;
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  // Entry animation
  late final AnimationController _ctrl;
  late final Animation<double> _scaleFade; // for check circle
  late final Animation<double> _slideUp; // for card + buttons

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _slideUp = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onGoHome() {
    // TODO: context.go('/home') với go_router (clear stack)
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _onViewHistory() {
    // TODO: context.go('/history') với go_router
    Navigator.pushNamedAndRemoveUntil(context, '/booking_history', (route) => false);
  }

  void _onSupport() {
    // TODO: context.push('/support')
    Navigator.pushNamed(context, '/support');
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bgPage,
        // No AppBar — full success page
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: _S.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // ── Muted soccer icon ──────────
                Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 36,
                    color: _C.soccerMuted,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Animated success circle ────
                ScaleTransition(
                  scale: _scaleFade,
                  child: const Center(child: _SuccessCircle()),
                ),

                const SizedBox(height: 28),

                // ── Headline + subtitle ────────
                AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, 24 * (1 - _slideUp.value)),
                    child: Opacity(
                      opacity: _slideUp.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Đặt sân thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _C.headlineGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          // TODO: GoogleFonts.nunito(...)
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cảm ơn bạn đã sử dụng Sport Plus',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _C.textLight, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Booking receipt card ───────
                AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, 32 * (1 - _slideUp.value)),
                    child: Opacity(
                      opacity: _slideUp.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: const _ReceiptCard(),
                ),

                const SizedBox(height: 28),

                // ── Buttons ───────────────────
                AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, 40 * (1 - _slideUp.value)),
                    child: Opacity(
                      opacity: _slideUp.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Primary: Về trang chủ
                      _PrimaryButton(label: 'VỀ TRANG CHỦ', onTap: _onGoHome),

                      const SizedBox(height: 12),

                      // Outline: Xem lịch sử
                      _OutlineButton(
                        icon: Icons.history_rounded,
                        label: 'XEM LỊCH SỬ ĐẶT SÂN',
                        onTap: _onViewHistory,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Support footer ─────────────
                AnimatedBuilder(
                  animation: _slideUp,
                  builder: (_, child) => Opacity(
                    opacity: _slideUp.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: _onSupport,
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Cần hỗ trợ? ',
                              style: TextStyle(
                                color: _C.textLight,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Liên hệ ngay',
                              style: TextStyle(
                                color: _C.supportLink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUCCESS CIRCLE  (outer pale ring + inner green + check)
// ─────────────────────────────────────────────
class _SuccessCircle extends StatelessWidget {
  const _SuccessCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        color: _C.circleOuter,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: _C.circleInner,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x402E7D32),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RECEIPT CARD
// ─────────────────────────────────────────────
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Stadium row ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                // Stadium icon tile
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE0E3E0),
                      width: 1,
                    ),
                  ),
                  // TODO: Thay bằng Image.network(stadium.thumbnailUrl)
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Color(0xFF9E9E9E),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TÊN SÂN',
                      style: TextStyle(
                        color: _C.textCellLabel,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Arena Santiago',
                      // TODO: widget.stadiumName
                      style: TextStyle(
                        color: _C.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thin divider
          const Divider(height: 1, color: Color(0xFFF0F2EF)),

          // ── Date + time row ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                // NGÀY
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'NGÀY',
                        style: TextStyle(
                          color: _C.textCellLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '20/10/2026',
                        // TODO: widget.date
                        style: TextStyle(
                          color: _C.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // KHUNG GIỜ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'KHUNG GIỜ',
                        style: TextStyle(
                          color: _C.textCellLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '18:00 - 19:00',
                        // TODO: widget.timeSlot
                        style: TextStyle(
                          color: _C.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Dashed divider ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 1,
              child: CustomPaint(painter: _DashPainter()),
            ),
          ),

          // ── Total row ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  'Tổng tiền',
                  style: TextStyle(color: _C.textMid, fontSize: 15),
                ),
                Text(
                  '520.000đ',
                  // TODO: widget.totalPrice
                  style: TextStyle(
                    color: _C.priceGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHED LINE PAINTER
// ─────────────────────────────────────────────
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.dashedColor
      ..strokeWidth = 1;
    const dashW = 6.0, gapW = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────
//  PRIMARY BUTTON
// ─────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _S.btnHeight,
        decoration: BoxDecoration(
          color: _C.btnPrimary,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          boxShadow: [
            BoxShadow(
              color: _C.btnPrimary.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OUTLINE BUTTON
// ─────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _S.btnHeight,
        decoration: BoxDecoration(
          color: _C.btnOutlineBg,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          border: Border.all(color: _C.btnOutlineBdr, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.textMid, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _C.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
