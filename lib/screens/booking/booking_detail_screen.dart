// lib/screens/booking/booking_detail_screen.dart
//
// extra: BookingSummary (từ history) hoặc BookingModel (từ success screen)
// Luôn gọi API để lấy full detail

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

String _fmtMoney(double amount) {
  final s = amount.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$bufđ';
}

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  int? _bookingId;
  BookingModel? _booking;

  bool _isLoading       = false;
  bool _isCancelling    = false;
  bool _isPayingMoMo    = false;
  String? _errorMsg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is BookingSummary) {
        _bookingId = extra.bookingId;
      } else if (extra is BookingModel) {
        _booking   = extra;
        _bookingId = extra.bookingId;
      }
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    if (_bookingId == null) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final detail = await BookingService.instance.getBookingDetail(_bookingId!);
      if (!mounted) return;
      setState(() { _booking = detail; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMsg = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _onPayMoMo() async {
    if (_bookingId == null) return;
    setState(() => _isPayingMoMo = true);
    try {
      await BookingService.instance.createMoMoPayment(_bookingId!);
      // TODO: mở URL MoMo qua url_launcher
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isPayingMoMo = false);
    }
  }

  Future<void> _onCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn có chắc muốn hủy đơn đặt sân này không?\nSẽ được hoàn tiền 100%.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không',
                style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đặt sân',
                style: TextStyle(
                    color: AppColors.badgeCancelText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await BookingService.instance.cancelBooking(bookingId: _bookingId!);
      if (!mounted) return;
      _showSnack('Đã hủy đơn đặt sân');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _onReview() {
    // TODO: push review screen khi có
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.errorRed : AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Chi tiết đơn đặt'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2)),
              ),
          ],
        ),
        bottomNavigationBar: _booking != null
            ? _ActionBar(
                booking:      _booking!,
                isPayingMoMo: _isPayingMoMo,
                isCancelling: _isCancelling,
                onPayMoMo:    _onPayMoMo,
                onCancel:     _onCancel,
                onReview:     _onReview,
                onRebook: () => context.go('/fields'),
              )
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _booking == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMsg != null && _booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(_errorMsg!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadDetail,
                child: const Text('Thử lại',
                    style: TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking;
    if (booking == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDetail,
      child: CustomScrollView(
        slivers: [
          // Hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 0,
              ),
              child: _HeroCard(booking: booking),
            ),
          ),

          // Status + booking ID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
              ),
              child: _StatusCard(booking: booking),
            ),
          ),

          // Slot details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
              ),
              child: _SlotCard(booking: booking),
            ),
          ),

          // Services
          if (booking.services.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
                ),
                child: _ServicesCard(booking: booking),
              ),
            ),

          // Payment summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
              ),
              child: _PaymentCard(booking: booking),
            ),
          ),

          // Deposit info
          if (booking.deposit != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
                ),
                child: _DepositCard(deposit: booking.deposit!),
              ),
            ),

          // Cancel reason
          if (booking.cancelReason != null && booking.cancelReason!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
                ),
                child: _CancelReasonCard(reason: booking.cancelReason!),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── HERO CARD ─────────────────────────────────
class _HeroCard extends StatelessWidget {
  final BookingModel booking;
  const _HeroCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              left: 14, bottom: 14, right: 14,
              child: Text(
                booking.primaryField,
                style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STATUS CARD ───────────────────────────────
class _StatusCard extends StatelessWidget {
  final BookingModel booking;
  const _StatusCard({required this.booking});

  ({String text, Color textColor, Color bgColor}) get _badge => switch (booking.statusId) {
    1 => (text: 'ĐÃ ĐẶT',    textColor: AppColors.badgeBookedText, bgColor: AppColors.badgeBookedBg),
    2 => (text: 'HOÀN THÀNH', textColor: AppColors.badgeDoneText,  bgColor: AppColors.badgeDoneBg),
    3 => (text: 'ĐÃ HỦY',    textColor: AppColors.badgeCancelText, bgColor: AppColors.badgeCancelBg),
    _ => (text: booking.status.toUpperCase(), textColor: AppColors.textMid, bgColor: AppColors.fieldBg),
  };

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
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
              Text('#${booking.bookingId}',
                  style: const TextStyle(
                    color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900,
                  )),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badge.bgColor, borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge.text,
                style: TextStyle(
                  color: badge.textColor, fontSize: 12, fontWeight: FontWeight.w800,
                )),
          ),
        ],
      ),
    );
  }
}

// ── SLOT CARD ─────────────────────────────────
class _SlotCard extends StatelessWidget {
  final BookingModel booking;
  const _SlotCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHI TIẾT SLOT',
              style: TextStyle(color: AppColors.textHint, fontSize: 10.5,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...booking.details.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryUltraLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_soccer_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fieldName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.textDark,
                          )),
                      Text(
                        '${d.displayDate}  •  ${d.displayTime}',
                        style: const TextStyle(color: AppColors.textMid, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(d.priceFmt,
                    style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14,
                    )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── SERVICES CARD ─────────────────────────────
class _ServicesCard extends StatelessWidget {
  final BookingModel booking;
  const _ServicesCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DỊCH VỤ ĐI KÈM',
              style: TextStyle(color: AppColors.textHint, fontSize: 10.5,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...booking.services.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.serviceName} ×${s.quantity}',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  ),
                ),
                Text(s.totalFmt,
                    style: const TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── PAYMENT CARD ──────────────────────────────
class _PaymentCard extends StatelessWidget {
  final BookingModel booking;
  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        children: [
          if (booking.discountAmount > 0) ...[
            _PayRow('Tiền sân + dịch vụ', _fmtMoney(booking.subTotal)),
            const SizedBox(height: 6),
            _PayRow('Giảm giá', '-${_fmtMoney(booking.discountAmount)}',
                valueColor: AppColors.badgeCancelText),
            const SizedBox(height: 6),
          ],
          if (booking.taxAmount > 0) ...[
            _PayRow('Thuế', _fmtMoney(booking.taxAmount)),
            const SizedBox(height: 6),
          ],
          const Divider(color: AppColors.fieldBorder),
          const SizedBox(height: 6),
          _PayRow('Tổng cộng', _fmtMoney(booking.totalAmount), isTotal: true),
          if (booking.promotionCode != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Mã: ${booking.promotionCode}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _PayRow(this.label, this.value, {this.isTotal = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: isTotal ? AppColors.textDark : AppColors.textMid,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            )),
        Text(value,
            style: TextStyle(
              color: valueColor ?? (isTotal ? AppColors.primary : AppColors.textDark),
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

// ── DEPOSIT CARD ──────────────────────────────
class _DepositCard extends StatelessWidget {
  final DepositModel deposit;
  const _DepositCard({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('THÔNG TIN ĐẶT CỌC',
                  style: TextStyle(color: AppColors.textHint, fontSize: 10.5,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deposit.isPaid ? AppColors.badgeBookedBg : AppColors.badgeCancelBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deposit.status,
                  style: TextStyle(
                    color: deposit.isPaid
                        ? AppColors.badgeBookedText : AppColors.badgeCancelText,
                    fontSize: 11, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  label: 'Cần đặt cọc',
                  value: _fmtMoney(deposit.requiredAmount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCell(
                  label: 'Đã thanh toán',
                  value: _fmtMoney(deposit.paidAmount),
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          if (!deposit.isPaid && deposit.minutesLeft > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.warningOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Còn ${deposit.minutesLeft} phút để thanh toán',
                    style: const TextStyle(
                        color: AppColors.warningOrange, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: AppColors.textHint, fontSize: 11,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textDark,
                fontWeight: FontWeight.w800, fontSize: 14,
              )),
        ],
      ),
    );
  }
}

// ── CANCEL REASON CARD ────────────────────────
class _CancelReasonCard extends StatelessWidget {
  final String reason;
  const _CancelReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeCancelBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.badgeCancelText.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LÝ DO HỦY',
              style: TextStyle(color: AppColors.badgeCancelText, fontSize: 10.5,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(reason,
              style: const TextStyle(color: AppColors.textMid, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

// ── ACTION BAR ────────────────────────────────
class _ActionBar extends StatelessWidget {
  final BookingModel booking;
  final bool isPayingMoMo;
  final bool isCancelling;
  final VoidCallback onPayMoMo;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final VoidCallback onRebook;

  const _ActionBar({
    required this.booking,
    required this.isPayingMoMo,
    required this.isCancelling,
    required this.onPayMoMo,
    required this.onCancel,
    required this.onReview,
    required this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12, offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH, vertical: 12),
          child: switch (booking.statusId) {
            1 => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    label: 'Thanh toán',
                    icon: Icons.account_balance_wallet_outlined,
                    isLoading: isPayingMoMo,
                    onTap: onPayMoMo,
                    color: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Hủy đặt',
                    icon: Icons.cancel_outlined,
                    isLoading: isCancelling,
                    onTap: onCancel,
                    color: AppColors.badgeCancelBg,
                    textColor: AppColors.badgeCancelText,
                    borderColor: const Color(0xFFFFCDD2),
                  ),
                ),
              ],
            ),
            2 => Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Đánh giá',
                    icon: Icons.star_outline_rounded,
                    onTap: onReview,
                    color: Colors.white,
                    textColor: AppColors.textDark,
                    borderColor: AppColors.fieldBorder,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Đặt lại',
                    icon: Icons.refresh_rounded,
                    onTap: onRebook,
                    color: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
            _ => _ActionBtn(
              label: 'Về trang chủ',
              icon: Icons.home_outlined,
              onTap: () => context.go('/home'),
              color: Colors.white,
              textColor: AppColors.textDark,
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
            ? Center(
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: textColor, strokeWidth: 2)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 17),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        color: textColor, fontSize: 14, fontWeight: FontWeight.w700,
                      )),
                ],
              ),
      ),
    );
  }
}