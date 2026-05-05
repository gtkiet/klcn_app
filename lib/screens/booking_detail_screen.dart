// lib/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import BookingService, PaymentService khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS  (consistent với toàn bộ app)
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  // static const primaryLight     = Color(0xFF4CAF50);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;

  // AppBar
  // static const appBarTitle = Color(0xFF1A1A1A);

  // Status colours
  static const statusBookedBg = Color(0xFFE8F5E9);
  static const statusBookedTxt = Color(0xFF2E7D32);
  static const statusDoneBg = Color(0xFFF5F5F5);
  static const statusDoneTxt = Color(0xFF757575);
  static const statusCancelBg = Color(0xFFFFEBEE);
  static const statusCancelTxt = Color(0xFFE53935);

  // Hero card
  // static const heroBg           = Color(0xFF1B5E20);
  static const heroBadgeBg = Color(0xFF2E7D32);

  // Info cells
  static const cellBg = Color(0xFFF7F8F6);
  static const cellBorder = Color(0xFFE4E7E4);
  static const cellLabelColor = Color(0xFF999999);

  // Section divider
  // static const sectionDivider   = Color(0xFFF0F2EF);
  static const dashedColor = Color(0xFFD4D9D4);

  // Addon chip
  static const addonBg = Color(0xFFE8F5E9);
  static const addonText = Color(0xFF2E7D32);

  // Price
  static const priceGreen = Color(0xFF2E7D32);
  static const priceRed = Color(0xFFE53935);
  static const priceGray = Color(0xFF9E9E9E);

  // Timeline
  static const timelineDot = Color(0xFF2E7D32);
  static const timelineLine = Color(0xFFD0D4D0);
  static const timelineDotGray = Color(0xFFBBBBBB);

  // Buttons
  static const btnPrimary = Color(0xFF2E7D32);
  static const btnDanger = Color(0xFFFFEBEE);
  static const btnDangerText = Color(0xFFE53935);
  static const btnDangerBorder = Color(0xFFFFCDD2);
  static const btnOutline = Color(0xFFE0E3E0);
  // static const btnOutlineTxt    = Color(0xFF444444);

  // Text
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
  // static const stadiumBlue      = Color(0xFF1565C0);
  // static const white            = Colors.white;
}

abstract class _S {
  static const double pagePadH = 16.0;
  static const double cardRadius = 16.0;
  static const double heroHeight = 180.0;
  static const double btnRadius = 12.0;
  static const double btnHeight = 50.0;
}

// ─────────────────────────────────────────────
//  BOOKING STATUS ENUM
// ─────────────────────────────────────────────
enum _BookingStatus { booked, completed, cancelled }

// ─────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────
const _mockStatus = _BookingStatus.booked;

class _TimelineEvent {
  final String time;
  final String label;
  final String desc;
  final bool done;
  const _TimelineEvent(this.time, this.label, this.desc, {this.done = false});
}

final _timeline = [
  _TimelineEvent(
    '20/10 08:12',
    'Đặt sân thành công',
    'Đơn đặt #AS-9821 đã được xác nhận',
    done: true,
  ),
  _TimelineEvent(
    '20/10 08:13',
    'Chờ thanh toán',
    'Vui lòng thanh toán trước khi đến sân',
    done: true,
  ),
  _TimelineEvent(
    '20/10 18:00',
    'Đến sân',
    'Xuất trình mã đặt sân tại quầy check-in',
  ),
  _TimelineEvent('20/10 19:00', 'Hoàn thành', 'Kết thúc khung giờ thi đấu'),
];

// ─────────────────────────────────────────────
//  BOOKING DETAIL SCREEN
// ─────────────────────────────────────────────
class BookingDetailScreen extends StatefulWidget {
  // TODO: Thêm params khi tích hợp:
  // final String bookingId;
  // final _BookingStatus status;
  const BookingDetailScreen({super.key});

  @override
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _status = _mockStatus;
  bool _isLoadingPay = false;
  final bool _isLoadingCancel = false;

  void _onPay() {
    setState(() => _isLoadingPay = true);
    // TODO: PaymentService.pay(bookingId) → navigate('/payment')
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoadingPay = false);
      Navigator.pushNamed(context, '/payment');
    });
  }

  void _onReview() => Navigator.pushNamed(context, '/review');
  void _onRebook() => Navigator.pushNamed(context, '/rebook');
  void _onSupport() => Navigator.pushNamed(context, '/support');

  void _onCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bạn có chắc muốn hủy đơn đặt sân này không?\nSẽ được hoàn tiền 100%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: _C.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: BookingService.cancel(bookingId)
              Navigator.pushNamed(context, '/cancel-booking');
            },
            child: const Text(
              'Hủy đặt sân',
              style: TextStyle(color: _C.priceRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
        appBar: _DetailAppBar(status: _status),

        // ── Bottom action bar ──────────────────
        bottomNavigationBar: _ActionBar(
          status: _status,
          isLoadingPay: _isLoadingPay,
          isLoadingCancel: _isLoadingCancel,
          onPay: _onPay,
          onReview: _onReview,
          onRebook: _onRebook,
          onCancel: _onCancel,
          onSupport: _onSupport,
        ),

        body: CustomScrollView(
          slivers: [
            // 1. Hero stadium image
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  16,
                  _S.pagePadH,
                  0,
                ),
                child: _HeroCard(),
              ),
            ),

            // 2. Booking code + status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
                child: _BookingCodeRow(status: _status),
              ),
            ),

            // 3. Detail info card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
                child: _DetailInfoCard(),
              ),
            ),

            // 4. Add-ons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
                child: _AddonsCard(),
              ),
            ),

            // 5. Payment summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
                child: _PaymentSummaryCard(status: _status),
              ),
            ),

            // 6. Timeline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
                child: _TimelineCard(),
              ),
            ),

            // 7. Support row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _S.pagePadH,
                  14,
                  _S.pagePadH,
                  0,
                ),
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

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final _BookingStatus status;
  const _DetailAppBar({required this.status});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _C.primary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Chi tiết đơn đặt',
        style: TextStyle(
          color: _C.primary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        // Share / more options
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              // TODO: Share.share(bookingDetails)
            },
            child: const Icon(
              Icons.ios_share_outlined,
              color: _C.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  HERO CARD  (stadium image)
// ─────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_S.cardRadius),
      child: SizedBox(
        height: _S.heroHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder image
            // TODO: Image.network(stadium.imageUrl, fit: BoxFit.cover)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white12,
                  size: 64,
                ),
              ),
            ),
            // Bottom gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Text overlay
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _C.heroBadgeBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'SÂN CAO CẤP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Arena Santiago',
                    // TODO: widget.stadiumName
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: const [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Phú Nhuận, TP.HCM',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
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

// ─────────────────────────────────────────────
//  BOOKING CODE + STATUS ROW
// ─────────────────────────────────────────────
class _BookingCodeRow extends StatelessWidget {
  final _BookingStatus status;
  const _BookingCodeRow({required this.status});

  (String, Color, Color) get _badgeCfg => switch (status) {
    _BookingStatus.booked => ('ĐÃ ĐẶT', _C.statusBookedTxt, _C.statusBookedBg),
    _BookingStatus.completed => (
      'HOÀN THÀNH',
      _C.statusDoneTxt,
      _C.statusDoneBg,
    ),
    _BookingStatus.cancelled => (
      'ĐÃ HỦY',
      _C.statusCancelTxt,
      _C.statusCancelBg,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (label, txtColor, bgColor) = _badgeCfg;
    final codeColor = status == _BookingStatus.cancelled
        ? _C.priceRed
        : status == _BookingStatus.completed
        ? _C.textDark
        : _C.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _shadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MÃ ĐẶT SÂN',
                style: TextStyle(
                  color: _C.cellLabelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#AS-9821',
                // TODO: widget.bookingCode
                style: TextStyle(
                  color: codeColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL INFO CARD  (4-cell 2×2 grid)
// ─────────────────────────────────────────────
class _DetailInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: _C.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'THÔNG TIN ĐẶT SÂN',
                style: TextStyle(
                  color: _C.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2×2 grid
          Row(
            children: [
              Expanded(
                child: _InfoCell(label: 'NGÀY', value: '20/10/2026'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCell(label: 'KHUNG GIỜ', value: '18:00 – 19:00'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoCell(label: 'THỜI LƯỢNG', value: '1 giờ'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCell(
                  label: 'PHƯƠNG THỨC',
                  value: 'Online',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
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
        color: _C.cellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.cellBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _C.cellLabelColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: _C.primary),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: const TextStyle(
                  color: _C.textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ADD-ONS CARD
// ─────────────────────────────────────────────
class _AddonsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_shopping_cart_outlined,
                color: _C.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'DỊCH VỤ ĐI KÈM',
                style: TextStyle(
                  color: _C.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AddonChip(
                icon: Icons.water_drop_outlined,
                label: 'Nước uống × 1',
                price: '20.000đ',
              ),
              _AddonChip(
                icon: Icons.sports_soccer,
                label: 'Thuê bóng × 1',
                price: '50.000đ',
              ),
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

  const _AddonChip({
    required this.icon,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.addonBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _C.addonText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            price,
            style: const TextStyle(
              color: _C.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PAYMENT SUMMARY CARD
// ─────────────────────────────────────────────
class _PaymentSummaryCard extends StatelessWidget {
  final _BookingStatus status;
  const _PaymentSummaryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == _BookingStatus.completed;
    final isCancelled = status == _BookingStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: _C.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'THANH TOÁN',
                style: TextStyle(
                  color: _C.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Payment status tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? _C.statusCancelBg
                      : isPaid
                      ? _C.statusBookedBg
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCancelled
                      ? 'Đã hoàn tiền'
                      : isPaid
                      ? 'Đã thanh toán'
                      : 'Chưa thanh toán',
                  style: TextStyle(
                    color: isCancelled
                        ? _C.statusCancelTxt
                        : isPaid
                        ? _C.statusBookedTxt
                        : const Color(0xFFF57F17),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _PriceRow(label: 'Tiền thuê sân', value: '450.000đ'),
          const SizedBox(height: 8),
          _PriceRow(label: 'Dịch vụ đi kèm', value: '70.000đ'),
          const SizedBox(height: 14),

          // Dashed divider
          SizedBox(height: 1, child: CustomPaint(painter: _DashPainter())),

          const SizedBox(height: 14),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  color: _C.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '520.000đ',
                    style: TextStyle(
                      color: isCancelled ? _C.priceGray : _C.priceGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const Text(
                    'Đã bao gồm VAT',
                    style: TextStyle(color: _C.textLight, fontSize: 10),
                  ),
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
        Text(
          label,
          style: const TextStyle(color: _C.textLight, fontSize: 13.5),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _C.textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TIMELINE CARD
// ─────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_outlined, color: _C.primary, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TIẾN TRÌNH ĐẶT SÂN',
                style: TextStyle(
                  color: _C.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._timeline.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == _timeline.length - 1;
            return _TimelineItem(event: item, isLast: isLast);
          }),
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
        // Dot + line column
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.done ? _C.timelineDot : _C.timelineDotGray,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: event.done ? _C.timelineDot : _C.timelineDotGray,
                    width: 2,
                  ),
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
                      ? _C.timelineDot.withValues(alpha: 0.3)
                      : _C.timelineLine,
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: TextStyle(
                    color: event.done ? _C.textDark : _C.textLight,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.desc,
                  style: TextStyle(
                    color: event.done ? _C.textMid : _C.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.time,
                  style: const TextStyle(color: _C.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SUPPORT ROW
// ─────────────────────────────────────────────
class _SupportRow extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(_S.cardRadius),
          boxShadow: _shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                color: _C.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần hỗ trợ về đơn đặt này?',
                    style: TextStyle(
                      color: _C.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Liên hệ hỗ trợ 24/7',
                    style: TextStyle(color: _C.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _C.textLight, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACTION BAR  (varies by status)
// ─────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final _BookingStatus status;
  final bool isLoadingPay;
  final bool isLoadingCancel;
  final VoidCallback onPay;
  final VoidCallback onReview;
  final VoidCallback onRebook;
  final VoidCallback onCancel;
  final VoidCallback onSupport;

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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _S.pagePadH,
            vertical: 12,
          ),
          child: switch (status) {
            // ── BOOKED: Pay + Cancel ──────────
            _BookingStatus.booked => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    label: 'Thanh toán',
                    icon: Icons.payment_outlined,
                    isLoading: isLoadingPay,
                    onTap: onPay,
                    color: _C.btnPrimary,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Hủy đặt',
                    icon: Icons.cancel_outlined,
                    isLoading: isLoadingCancel,
                    onTap: onCancel,
                    color: _C.btnDanger,
                    textColor: _C.btnDangerText,
                    borderColor: _C.btnDangerBorder,
                  ),
                ),
              ],
            ),

            // ── COMPLETED: Review + Rebook ────
            _BookingStatus.completed => Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Đánh giá',
                    icon: Icons.star_outline_rounded,
                    onTap: onReview,
                    color: Colors.white,
                    textColor: _C.textDark,
                    borderColor: _C.btnOutline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Đặt lại',
                    icon: Icons.refresh_rounded,
                    onTap: onRebook,
                    color: _C.btnPrimary,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),

            // ── CANCELLED: Support only ───────
            _BookingStatus.cancelled => _ActionBtn(
              label: 'Liên hệ hỗ trợ',
              icon: Icons.headset_mic_outlined,
              onTap: onSupport,
              color: Colors.white,
              textColor: _C.textDark,
              borderColor: _C.btnOutline,
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
        height: _S.btnHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: color == _C.btnPrimary
              ? [
                  BoxShadow(
                    color: _C.btnPrimary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHED LINE
// ─────────────────────────────────────────────
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.dashedColor
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  SHARED CARD SHADOW
// ─────────────────────────────────────────────
const _shadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
];
