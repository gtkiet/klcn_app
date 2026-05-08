// lib/screens/booking/booking_failure_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class BookingFailureScreen extends StatefulWidget {
  // TODO: Thêm params khi tích hợp: stadiumName, date, timeSlot, totalPrice, errorReason
  const BookingFailureScreen({super.key});

  @override
  State<BookingFailureScreen> createState() => _BookingFailureScreenState();
}

class _BookingFailureScreenState extends State<BookingFailureScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),    weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _fadeAnim = CurvedAnimation(
        parent: _shakeCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Future.delayed(const Duration(milliseconds: 200), () => _shakeCtrl.forward()));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onRetry()   => Navigator.pushReplacementNamed(context, '/booking_confirm');
  void _onSupport() => Navigator.pushNamed(context, '/support');
  void _onClose()   => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onClose,
          ),
          title: const Text('Trạng thái đặt sân'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 36),

                // Error circle (shake animation)
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: FadeTransition(
                      opacity: _fadeAnim.drive(Tween(begin: 0.0, end: 1.0)),
                      child: child,
                    ),
                  ),
                  child: const Center(child: _ErrorCircle()),
                ),
                const SizedBox(height: 28),

                // Headline
                const Text(
                  'Đặt sân không thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Rất tiếc, đã có lỗi xảy ra trong quá trình\nthanh toán hoặc sân vừa mới được đặt.\nVui lòng thử lại sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14.5,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 28),

                // Detail card
                _FailureDetailCard(),
                const SizedBox(height: 28),

                SpPrimaryButton(label: 'THỬ LẠI NGAY', onTap: _onRetry),
                const SizedBox(height: 12),
                SpOutlineButton(
                  label: 'LIÊN HỆ HỖ TRỢ',
                  icon: Icons.headset_mic_outlined,
                  onTap: _onSupport,
                  borderColor: AppColors.primary,
                  textColor: AppColors.primary,
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

// ── ERROR CIRCLE ──────────────────────────────
class _ErrorCircle extends StatelessWidget {
  const _ErrorCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.20),
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
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text('!',
                style: TextStyle(
                    color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1)),
          ),
        ),
      ),
    );
  }
}

// ── FAILURE DETAIL CARD ───────────────────────
class _FailureDetailCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('CHI TIẾT SÂN',
                      style: TextStyle(color: AppColors.textHint, fontSize: 10.5,
                          fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  SizedBox(height: 5),
                  Text('Arena Santiago',
                      style: TextStyle(color: AppColors.infoBlue, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.badgeCancelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('THẤT BẠI',
                    style: TextStyle(color: AppColors.badgeCancelText, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date + Time
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày đặt',
                  value: '20/10/2026',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCell(
                  icon: Icons.access_time_outlined,
                  label: 'Khung giờ',
                  value: '18:00 - 19:00',
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dashed divider
          SizedBox(height: 1, child: CustomPaint(painter: SpDashPainter())),
          const SizedBox(height: 14),

          // Total
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền', style: TextStyle(color: AppColors.textMid, fontSize: 15)),
              Text('520.000đ',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.textMid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
