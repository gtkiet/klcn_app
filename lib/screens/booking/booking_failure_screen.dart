// lib/screens/booking/booking_failure_screen.dart
//
// extra: { 'error'?: String, 'field'?: FieldModel, 'date'?: DateTime }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class BookingFailureScreen extends StatefulWidget {
  const BookingFailureScreen({super.key});

  @override
  State<BookingFailureScreen> createState() => _BookingFailureScreenState();
}

class _BookingFailureScreenState extends State<BookingFailureScreen>
    with SingleTickerProviderStateMixin {
  String? _errorMsg;

  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;
  late final Animation<double>   _fadeAnim;

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
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _shakeCtrl.forward();
        }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _errorMsg = extra?['error'] as String?;
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/fields'),
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

                // Shake icon
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

                const Text(
                  'Đặt sân không thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Rất tiếc, đã có lỗi xảy ra trong quá trình\nthanh toán hoặc sân vừa mới được đặt.\nVui lòng thử lại sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight, fontSize: 14.5, height: 1.65,
                  ),
                ),

                // Chi tiết lỗi từ server
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.badgeCancelBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.badgeCancelText.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.badgeCancelText, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(color: AppColors.badgeCancelText, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                SpPrimaryButton(
                  label: 'THỬ LẠI',
                  onTap: () => context.pop(),
                  trailingIcon: Icons.refresh_rounded,
                ),
                const SizedBox(height: 12),
                SpOutlineButton(
                  label: 'VỀ TRANG CHỦ',
                  icon: Icons.home_outlined,
                  onTap: () => context.go('/home'),
                  borderColor: AppColors.fieldBorder,
                  textColor: AppColors.textMid,
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

class _ErrorCircle extends StatelessWidget {
  const _ErrorCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.20),
            blurRadius: 24, spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.35),
                blurRadius: 16, offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text('!',
                style: TextStyle(
                  color: Colors.white, fontSize: 42,
                  fontWeight: FontWeight.w900, height: 1,
                )),
          ),
        ),
      ),
    );
  }
}