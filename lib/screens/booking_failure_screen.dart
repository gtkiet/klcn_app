// lib/screens/booking_failure_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Nhận bookingId, stadiumName, date, timeSlot, totalPrice, errorReason từ params

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  // Brand
  static const primary        = Color(0xFF2E7D32);
  static const logoBg         = Color(0xFF1565C0);   // blue SportPlus logo card

  // Background
  static const bgPage         = Color(0xFFF2F5F0);

  // Error icon circle
  static const circleOuter    = Colors.white;
  static const circleInner    = Color(0xFFE53935);   // red
  static const circleShadow   = Color(0x1FE53935);

  // Text
  static const textDark       = Color(0xFF1A1A1A);
  static const textMid        = Color(0xFF555555);
  static const textLight      = Color(0xFF888888);
  static const headlineBlack  = Color(0xFF1A1A1A);
  static const stadiumBlue    = Color(0xFF1565C0);   // stadium name blue

  // Failure card
  static const cardBg         = Color(0xFFF7F8F6);
  static const cardBorder     = Color(0xFFE4E7E4);
  static const cellBg         = Colors.white;
  static const cellBorder     = Color(0xFFE8EBE8);
  static const labelGray      = Color(0xFF9E9E9E);
  static const dashedColor    = Color(0xFFD4D9D4);

  // "THẤT BẠI" badge
  static const badgeBg        = Color(0xFFFFEBEE);
  static const badgeText      = Color(0xFFE53935);

  // Price
  static const priceRed       = Color(0xFFE53935);

  // Buttons
  static const btnPrimary     = Color(0xFF2E7D32);
  static const btnOutlineBdr  = Color(0xFF2E7D32);
  static const btnOutlineTxt  = Color(0xFF2E7D32);

  // AppBar
  // static const appBarTitle    = Color(0xFF1A1A1A);
  // static const closeBtnColor  = Color(0xFF555555);

  // static const white          = Colors.white;
}

abstract class _S {
  static const double pagePadH  = 20.0;
  static const double cardRadius = 16.0;
  static const double cellRadius = 12.0;
  static const double btnRadius  = 14.0;
  static const double btnHeight  = 54.0;
}

// ─────────────────────────────────────────────
//  BOOKING FAILURE SCREEN
// ─────────────────────────────────────────────
class BookingFailureScreen extends StatefulWidget {
  // TODO: Thêm params khi tích hợp:
  // final String stadiumName;
  // final String date;
  // final String timeSlot;
  // final String totalPrice;
  // final String errorReason;
  const BookingFailureScreen({super.key});

  @override
  State<BookingFailureScreen> createState() =>
      _BookingFailureScreenState();
}

class _BookingFailureScreenState extends State<BookingFailureScreen>
    with SingleTickerProviderStateMixin {

  // Shake animation for error circle
  late final AnimationController _shakeCtrl;
  late final Animation<double>    _shakeAnim;
  late final Animation<double>    _fadeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Horizontal shake: 0 → -12 → 12 → -8 → 8 → 0
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0),    weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),     weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeCtrl,
      curve: Curves.easeInOut,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _shakeCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // Start after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200),
          () => _shakeCtrl.forward());
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onClose() {
    // TODO: context.pop() với go_router, hoặc context.go('/home')
    // Navigator.maybePop(context);
    Navigator.pop(context);
  }

  void _onRetry() {
    // TODO: context.go('/booking-confirm') với bookingParams
    // hoặc context.pop() nếu muốn quay về màn hình trước
    Navigator.pushReplacementNamed(context, '/booking_confirm');
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
        appBar: _FailureAppBar(onClose: _onClose),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: _S.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── SportPlus logo card ─────────
                const Center(child: _SportPlusLogoCard()),

                const SizedBox(height: 28),

                // ── Error icon circle (shake) ───
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim.drive(
                        Tween(begin: 0.0, end: 1.0)),
                    child: const Center(child: _ErrorCircle()),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Headline ────────────────────
                const Text(
                  'Đặt sân không thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _C.headlineBlack,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    // TODO: GoogleFonts.nunito(...)
                  ),
                ),

                const SizedBox(height: 12),

                // ── Subtitle ────────────────────
                const Text(
                  'Rất tiếc, đã có lỗi xảy ra trong quá trình\n'
                  'thanh toán hoặc sân vừa mới được đặt.\n'
                  'Vui lòng thử lại sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _C.textLight,
                    fontSize: 14.5,
                    height: 1.65,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Failure detail card ─────────
                _FailureDetailCard(),

                const SizedBox(height: 28),

                // ── "THỬ LẠI NGAY" button ───────
                _PrimaryButton(
                  label: 'THỬ LẠI NGAY',
                  onTap: _onRetry,
                ),

                const SizedBox(height: 12),

                // ── "LIÊN HỆ HỖ TRỢ" button ────
                _OutlineButton(
                  label: 'LIÊN HỆ HỖ TRỢ',
                  onTap: _onSupport,
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR  ("Booking Status" + X close)
// ─────────────────────────────────────────────
class _FailureAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onClose;
  const _FailureAppBar({required this.onClose});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: _C.primary),
        onPressed: onClose,
      ),
      title: const Text(
        'Booking Status',
        style: TextStyle(
          color: _C.primary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      titleSpacing: 0,
    );
  }
}

// ─────────────────────────────────────────────
//  SPORT PLUS LOGO CARD  (blue square)
// ─────────────────────────────────────────────
class _SportPlusLogoCard extends StatelessWidget {
  const _SportPlusLogoCard();

  @override
  Widget build(BuildContext context) {
    // TODO: Thay bằng Image.asset('assets/images/sportplus_logo.png')
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _C.logoBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _C.logoBg.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer,
              color: Colors.white70, size: 20),
          const SizedBox(height: 2),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'SPORT\n',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'PLUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ERROR CIRCLE  (white outer + red inner + "!")
// ─────────────────────────────────────────────
class _ErrorCircle extends StatelessWidget {
  const _ErrorCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: _C.circleOuter,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _C.circleShadow,
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _C.circleInner,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _C.circleInner.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FAILURE DETAIL CARD
// ─────────────────────────────────────────────
class _FailureDetailCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header: label + "THẤT BẠI" badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'CHI TIẾT SÂN',
                      style: TextStyle(
                        color: _C.labelGray,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Arena Santiago',
                      // TODO: widget.stadiumName
                      style: TextStyle(
                        color: _C.stadiumBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // "THẤT BẠI" badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'THẤT BẠI',
                    style: TextStyle(
                      color: _C.badgeText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Date + Time cells ──────────────
            Row(
              children: [
                // Ngày đặt cell
                Expanded(
                  child: _InfoCell(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ngày đặt',
                    value: '20/10/2026',
                    // TODO: widget.date
                  ),
                ),
                const SizedBox(width: 10),
                // Khung giờ cell
                Expanded(
                  child: _InfoCell(
                    icon: Icons.access_time_outlined,
                    label: 'Khung giờ',
                    value: '18:00 - 19:00',
                    // TODO: widget.timeSlot
                    iconColor: _C.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Dashed divider ─────────────────
            SizedBox(
              height: 1,
              child: CustomPaint(painter: _DashPainter()),
            ),

            const SizedBox(height: 14),

            // ── Total row ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Tổng tiền',
                  style: TextStyle(
                    color: _C.textMid,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '520.000đ',
                  // TODO: widget.totalPrice
                  style: TextStyle(
                    color: _C.priceRed,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INFO CELL  (white card with icon + label + value)
// ─────────────────────────────────────────────
class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    iconColor;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = const Color(0xFF555555),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _C.cellBg,
        borderRadius: BorderRadius.circular(_S.cellRadius),
        border: Border.all(color: _C.cellBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: _C.labelGray,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: _C.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
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
      ..strokeWidth = 1.0;
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
//  PRIMARY BUTTON  ("THỬ LẠI NGAY")
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
              color: _C.btnPrimary.withValues(alpha: 0.28),
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
//  OUTLINE BUTTON  ("LIÊN HỆ HỖ TRỢ")
// ─────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _S.btnHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          border: Border.all(
              color: _C.btnOutlineBdr, width: 1.8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _C.btnOutlineTxt,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}