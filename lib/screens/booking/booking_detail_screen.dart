// lib/screens/booking/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MODELS + DATA ─────────────────────────────
enum _BookingStatus { booked, completed, cancelled }

class _TimelineEvent {
  final String time;
  final String label;
  final String desc;
  final bool done;
  const _TimelineEvent(this.time, this.label, this.desc, {this.done = false});
}

const _mockStatus = _BookingStatus.booked;

final _timeline = [
  const _TimelineEvent('20/10 08:12', 'Đặt sân thành công',  'Đơn đặt #AS-9821 đã được xác nhận', done: true),
  const _TimelineEvent('20/10 08:13', 'Chờ thanh toán',      'Vui lòng thanh toán trước khi đến sân', done: true),
  const _TimelineEvent('20/10 18:00', 'Đến sân',             'Xuất trình mã đặt sân tại quầy check-in'),
  const _TimelineEvent('20/10 19:00', 'Hoàn thành',          'Kết thúc khung giờ thi đấu'),
];

// ─────────────────────────────────────────────
//  BOOKING DETAIL SCREEN
// ─────────────────────────────────────────────
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _status = _mockStatus;
  bool _isLoadingPay    = false;
  bool isLoadingCancel = false;

  void _onPay() {
    setState(() => _isLoadingPay = true);
    // TODO: PaymentService.pay(bookingId)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoadingPay = false);
      Navigator.pushNamed(context, '/payment');
    });
  }

  void _onReview()  => Navigator.pushNamed(context, '/review');
  void _onRebook()  => Navigator.pushNamed(context, '/booking_confirm');
  void _onSupport() => Navigator.pushNamed(context, '/support');

  void _onCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn hủy đơn đặt sân này không?\nSẽ được hoàn tiền 100%.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: BookingService.cancel(bookingId)
            },
            child: const Text('Hủy đặt sân',
                style: TextStyle(color: AppColors.badgeCancelText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Chi tiết đơn đặt'),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () {}, // TODO: Share.share(bookingDetails)
            ),
          ],
        ),
        bottomNavigationBar: _ActionBar(
          status: _status,
          isLoadingPay: _isLoadingPay,
          isLoadingCancel: isLoadingCancel,
          onPay: _onPay,
          onReview: _onReview,
          onRebook: _onRebook,
          onCancel: _onCancel,
          onSupport: _onSupport,
        ),
        body: CustomScrollView(
          slivers: [
            // Hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 0),
                child: _HeroCard(),
              ),
            ),

            // Booking code + status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _BookingCodeRow(status: _status),
              ),
            ),

            // Detail info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _DetailInfoCard(),
              ),
            ),

            // Add-ons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _AddonsCard(),
              ),
            ),

            // Payment summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _PaymentSummaryCard(status: _status),
              ),
            ),

            // Timeline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _TimelineCard(),
              ),
            ),

            // Support
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0),
                child: _SupportRow(onTap: _onSupport),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── HERO CARD ─────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(Icons.sports_soccer, color: Colors.white12, size: 64),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                    stops: const [0.4, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                    child: const Text('SÂN CAO CẤP',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),
                  const Text('Arena Santiago',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                      SizedBox(width: 3),
                      Text('Phú Nhuận, TP.HCM',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BOOKING CODE ROW ──────────────────────────
class _BookingCodeRow extends StatelessWidget {
  final _BookingStatus status;
  const _BookingCodeRow({required this.status});

  (String, Color, Color) get _badge => switch (status) {
    _BookingStatus.booked    => ('ĐÃ ĐẶT',    AppColors.badgeBookedText, AppColors.badgeBookedBg),
    _BookingStatus.completed => ('HOÀN THÀNH', AppColors.badgeDoneText,  AppColors.badgeDoneBg),
    _BookingStatus.cancelled => ('ĐÃ HỦY',    AppColors.badgeCancelText, AppColors.badgeCancelBg),
  };

  Color get _codeColor => switch (status) {
    _BookingStatus.booked    => AppColors.primary,
    _BookingStatus.completed => AppColors.textDark,
    _BookingStatus.cancelled => AppColors.badgeCancelText,
  };

  @override
  Widget build(BuildContext context) {
    final (label, txtColor, bgColor) = _badge;
    return SpCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MÃ ĐẶT SÂN',
                  style: TextStyle(color: AppColors.textHint, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text('#AS-9821',
                  style: TextStyle(color: _codeColor, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            ],
          ),
          SpStatusBadge(label: label, textColor: txtColor, bgColor: bgColor),
        ],
      ),
    );
  }
}

// ── DETAIL INFO CARD ──────────────────────────
class _DetailInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text('THÔNG TIN ĐẶT SÂN',
                  style: TextStyle(color: AppColors.primary, fontSize: 11.5,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoCell(label: 'NGÀY', value: '20/10/2026')),
              const SizedBox(width: 10),
              Expanded(child: _InfoCell(label: 'KHUNG GIỜ', value: '18:00 – 19:00')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoCell(label: 'THỜI LƯỢNG', value: '1 giờ')),
              const SizedBox(width: 10),
              Expanded(child: _InfoCell(label: 'PHƯƠNG THỨC', value: 'Online',
                  icon: Icons.account_balance_wallet_outlined)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  const _InfoCell({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 9.5,
                  fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ADD-ONS CARD ──────────────────────────────
class _AddonsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add_shopping_cart_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text('DỊCH VỤ ĐI KÈM',
                  style: TextStyle(color: AppColors.primary, fontSize: 11.5,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AddonChip(icon: Icons.water_drop_outlined, label: 'Nước uống × 1', price: '20.000đ'),
              _AddonChip(icon: Icons.sports_soccer,       label: 'Thuê bóng × 1', price: '50.000đ'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddonChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  const _AddonChip({required this.icon, required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(price, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── PAYMENT SUMMARY ───────────────────────────
class _PaymentSummaryCard extends StatelessWidget {
  final _BookingStatus status;
  const _PaymentSummaryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid      = status == _BookingStatus.completed;
    final isCancelled = status == _BookingStatus.cancelled;

    return SpCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              const Text('THANH TOÁN',
                  style: TextStyle(color: AppColors.primary, fontSize: 11.5,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const Spacer(),
              SpStatusBadge(
                label: isCancelled ? 'Đã hoàn tiền' : isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                textColor: isCancelled ? AppColors.badgeCancelText
                    : isPaid ? AppColors.badgeBookedText : const Color(0xFFF57F17),
                bgColor: isCancelled ? AppColors.badgeCancelBg
                    : isPaid ? AppColors.badgeBookedBg : const Color(0xFFFFF8E1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PriceRow(label: 'Tiền thuê sân',  value: '450.000đ'),
          const SizedBox(height: 8),
          _PriceRow(label: 'Dịch vụ đi kèm', value: '70.000đ'),
          const SizedBox(height: 14),
          SizedBox(height: 1, child: CustomPaint(painter: SpDashPainter())),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Tổng cộng',
                  style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w700)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('520.000đ',
                      style: TextStyle(
                          color: isCancelled ? AppColors.textHint : AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          decoration: isCancelled ? TextDecoration.lineThrough : null)),
                  const Text('Đã bao gồm VAT',
                      style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13.5)),
        Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── TIMELINE CARD ─────────────────────────────
class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text('TIẾN TRÌNH ĐẶT SÂN',
                  style: TextStyle(color: AppColors.primary, fontSize: 11.5,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 16),
          ..._timeline.asMap().entries.map((e) =>
              _TimelineItem(event: e.value, isLast: e.key == _timeline.length - 1)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.done ? AppColors.primary : AppColors.textHint,
                  shape: BoxShape.circle,
                ),
                child: event.done
                    ? const Icon(Icons.check, color: Colors.white, size: 7)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 44,
                  color: event.done
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.fieldBorder,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.label,
                    style: TextStyle(
                        color: event.done ? AppColors.textDark : AppColors.textLight,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(event.desc,
                    style: TextStyle(
                        color: event.done ? AppColors.textMid : AppColors.textLight,
                        fontSize: 12)),
                const SizedBox(height: 3),
                Text(event.time,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── SUPPORT ROW ───────────────────────────────
class _SupportRow extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SpCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryUltraLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.headset_mic_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cần hỗ trợ về đơn đặt này?',
                      style: TextStyle(color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Liên hệ hỗ trợ 24/7',
                      style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── ACTION BAR ────────────────────────────────
class _ActionBar extends StatelessWidget {
  final _BookingStatus status;
  final bool isLoadingPay, isLoadingCancel;
  final VoidCallback onPay, onReview, onRebook, onCancel, onSupport;

  const _ActionBar({
    required this.status,
    required this.isLoadingPay,
    required this.isLoadingCancel,
    required this.onPay,
    required this.onReview,
    required this.onRebook,
    required this.onCancel,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH, vertical: 12),
          child: switch (status) {
            _BookingStatus.booked => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ActionBtn(label: 'Thanh toán', icon: Icons.payment_outlined,
                      isLoading: isLoadingPay, onTap: onPay,
                      color: AppColors.primary, textColor: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(label: 'Hủy đặt', icon: Icons.cancel_outlined,
                      isLoading: isLoadingCancel, onTap: onCancel,
                      color: AppColors.badgeCancelBg, textColor: AppColors.badgeCancelText,
                      borderColor: const Color(0xFFFFCDD2)),
                ),
              ],
            ),
            _BookingStatus.completed => Row(
              children: [
                Expanded(
                  child: _ActionBtn(label: 'Đánh giá', icon: Icons.star_outline_rounded,
                      onTap: onReview, color: Colors.white, textColor: AppColors.textDark,
                      borderColor: AppColors.fieldBorder),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(label: 'Đặt lại', icon: Icons.refresh_rounded,
                      onTap: onRebook, color: AppColors.primary, textColor: Colors.white),
                ),
              ],
            ),
            _BookingStatus.cancelled => _ActionBtn(
              label: 'Liên hệ hỗ trợ', icon: Icons.headset_mic_outlined,
              onTap: onSupport, color: Colors.white, textColor: AppColors.textDark,
              borderColor: AppColors.fieldBorder,
            ),
          },
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.isLoading = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
          boxShadow: color == AppColors.primary ? AppShadow.btn : [],
        ),
        child: isLoading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: textColor, strokeWidth: 2)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 17),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
