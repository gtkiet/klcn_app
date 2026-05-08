// lib/screens/booking/booking_success_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class BookingSuccessScreen extends StatefulWidget {
  // TODO: Thêm params khi tích hợp: stadiumName, bookingCode, date, timeSlot, totalPrice
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _slideAnim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onGoHome()    => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  void _onViewHistory() => Navigator.pushNamedAndRemoveUntil(context, '/booking_history', (_) => false);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),

                // Success circle (animated)
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const Center(child: _SuccessCircle()),
                ),
                const SizedBox(height: 28),

                // Headline
                _SlideUp(
                  animation: _slideAnim,
                  child: Column(
                    children: [
                      const Text(
                        'Đặt sân thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cảm ơn bạn đã sử dụng Sport Plus',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Receipt card
                _SlideUp(animation: _slideAnim, child: const _ReceiptCard()),
                const SizedBox(height: 28),

                // Buttons
                _SlideUp(
                  animation: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SpPrimaryButton(
                        label: 'VỀ TRANG CHỦ',
                        onTap: _onGoHome,
                        trailingIcon: Icons.home_outlined,
                      ),
                      const SizedBox(height: 12),
                      SpOutlineButton(
                        label: 'XEM LỊCH SỬ ĐẶT SÂN',
                        icon: Icons.history_rounded,
                        onTap: _onViewHistory,
                      ),
                    ],
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

// ── SLIDE UP ANIMATION WRAPPER ────────────────
class _SlideUp extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _SlideUp({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) => Transform.translate(
        offset: Offset(0, 28 * (1 - animation.value)),
        child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: c),
      ),
      child: child,
    );
  }
}

// ── SUCCESS CIRCLE ────────────────────────────
class _SuccessCircle extends StatelessWidget {
  const _SuccessCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        color: AppColors.primaryUltraLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}

// ── RECEIPT CARD ──────────────────────────────
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Stadium row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryUltraLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: const Icon(Icons.sports_soccer, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('TÊN SÂN',
                        style: TextStyle(color: AppColors.textHint, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    SizedBox(height: 4),
                    Text('Arena Santiago',
                        style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.fieldBorder),

          // Date + time
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ReceiptInfo(label: 'NGÀY', value: '20/10/2026'),
                ),
                Expanded(
                  child: _ReceiptInfo(label: 'KHUNG GIỜ', value: '18:00 - 19:00'),
                ),
              ],
            ),
          ),

          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 1, child: CustomPaint(painter: SpDashPainter())),
          ),

          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Tổng tiền', style: TextStyle(color: AppColors.textMid, fontSize: 15)),
                Text('520.000đ',
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptInfo extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
