// lib/screens/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import BookingHistoryService, ReviewService khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  // static const primaryLight     = Color(0xFF4CAF50);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;
  // static const appBarTitle = Color(0xFF1A1A1A);

  // Status badges
  static const badgeBooked = Color(0xFF2E7D32); // "ĐÃ ĐẶT"
  static const badgeDone = Color(0xFF757575); // "HOÀN THÀNH"
  static const badgeCancelled = Color(0xFFE53935); // "ĐÃ HỦY"
  static const badgeBookedBg = Color(0xFFE8F5E9);
  static const badgeDoneBg = Color(0xFFF5F5F5);
  static const badgeCancelledBg = Color(0xFFFFEBEE);

  // Info box
  static const infoBg = Color(0xFFF7F8F6);
  static const infoBorder = Color(0xFFE0E3E0);

  // Booking code
  static const codeBooked = Color(0xFF2E7D32);
  static const codeDone = Color(0xFF1A1A1A);
  static const codeCancelled = Color(0xFFE53935);

  // Payment
  static const pricePaid = Color(0xFF1A1A1A);
  static const priceUnpaid = Color(0xFF2E7D32);
  static const priceRefund = Color(0xFF9E9E9E); // strikethrough
  static const paidLabel = Color(0xFF43A047);
  static const unpaidLabel = Color(0xFF757575);
  static const refundLabel = Color(0xFFE53935);

  // Buttons
  static const btnPrimary = Color(0xFF2E7D32);
  static const btnOutline = Color(0xFFE0E3E0);
  static const btnOutlineTxt = Color(0xFF444444);
  static const btnMoreBg = Color(0xFFF0F2EF);

  // Text
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
  static const textLabel = Color(0xFF999999);

  // Tab chips
  static const chipActiveBg = Color(0xFF2E7D32);
  static const chipActiveTxt = Colors.white;
  static const chipInactiveBg = Colors.white;
  static const chipInactiveTxt = Color(0xFF444444);
  static const chipBorder = Color(0xFFD5D8D5);

  // Nav
  static const navUnselected = Color(0xFF9E9E9E);
  // static const white            = Colors.white;
}

abstract class _S {
  static const double pagePadH = 16.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 50.0;
  static const double btnRadius = 10.0;
  static const double fabSize = 52.0;
}

// ─────────────────────────────────────────────
//  BOOKING STATUS ENUM
// ─────────────────────────────────────────────
enum BookingStatus { booked, completed, cancelled }

// ─────────────────────────────────────────────
//  MOCK DATA MODEL
// ─────────────────────────────────────────────
class _BookingRecord {
  final String code;
  final String stadiumName;
  final String address;
  final String date;
  final String timeRange;
  final String amount;
  final BookingStatus status;

  const _BookingRecord({
    required this.code,
    required this.stadiumName,
    required this.address,
    required this.date,
    required this.timeRange,
    required this.amount,
    required this.status,
  });
}

final _allBookings = [
  const _BookingRecord(
    code: '#AS-9821',
    stadiumName: 'Sân Arena Santiago',
    address: 'Quận 7, TP. Hồ Chí Minh',
    date: '20/10/2026',
    timeRange: '18:00 - 19:00',
    amount: '450.000đ',
    status: BookingStatus.booked,
  ),
  const _BookingRecord(
    code: '#PN-4412',
    stadiumName: 'Sân cỏ nhân tạo Phú Nhuận',
    address: 'Phú Nhuận, TP. Hồ Chí Minh',
    date: '15/10/2026',
    timeRange: '17:00 - 18:30',
    amount: '520.000đ',
    status: BookingStatus.completed,
  ),
  const _BookingRecord(
    code: '#DY-2201',
    stadiumName: 'Sân bóng Đại học Y Dược',
    address: 'Quận 5, TP. Hồ Chí Minh',
    date: '12/10/2026',
    timeRange: '19:00 - 20:00',
    amount: '320.000đ',
    status: BookingStatus.cancelled,
  ),
  const _BookingRecord(
    code: '#GF-1105',
    stadiumName: 'Green Field Bình Thạnh',
    address: 'Bình Thạnh, TP. Hồ Chí Minh',
    date: '08/10/2026',
    timeRange: '16:00 - 17:30',
    amount: '390.000đ',
    status: BookingStatus.completed,
  ),
];

// Filter tabs definition
const _tabs = ['Tất cả', 'Đã đặt', 'Hoàn thành', 'Đã hủy'];

// ─────────────────────────────────────────────
//  BOOKING HISTORY SCREEN
// ─────────────────────────────────────────────
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  int _selectedTab = 0;
  int _currentNav = 2; // "LỊCH SỬ" active

  // Filtered bookings based on selected tab
  List<_BookingRecord> get _filtered {
    switch (_selectedTab) {
      case 1:
        return _allBookings
            .where((b) => b.status == BookingStatus.booked)
            .toList();
      case 2:
        return _allBookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      case 3:
        return _allBookings
            .where((b) => b.status == BookingStatus.cancelled)
            .toList();
      default:
        return _allBookings;
    }
  }

  void _onTabTap(int i) => setState(() => _selectedTab = i);

  void _onNavTap(int i) {
    setState(() => _currentNav = i);
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/fields');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        break;
    }
  }

  void _onFilterFab() {
    // TODO: showModalBottomSheet với FilterSheet (date range, status, sort)
    Navigator.pushNamed(context, '/filter-sheet');
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

        // ── AppBar ──────────────────────────────
        appBar: _HistoryAppBar(),

        // ── Body ────────────────────────────────
        body: Column(
          children: [
            // ── Tab chips (sticky) ──────────────
            _TabChipRow(
              tabs: _tabs,
              selectedIndex: _selectedTab,
              onTap: _onTabTap,
            ),

            // ── Booking list ────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: _C.primary,
                      // TODO: Gọi lại BookingHistoryService.fetch()
                      onRefresh: () async =>
                          await Future.delayed(const Duration(seconds: 1)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          _S.pagePadH,
                          16,
                          _S.pagePadH,
                          100,
                        ),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _BookingCard(
                          record: _filtered[i],
                          onDetail: () =>
                              Navigator.pushNamed(context, '/booking_detail'),
                          onRebook: () =>
                              Navigator.pushNamed(context, '/booking_rebook'),
                          onReview: () =>
                              Navigator.pushNamed(context, '/booking_review'),
                          onCancelReason: () =>
                              Navigator.pushNamed(context, '/booking_cancel'),
                        ),
                      ),
                    ),
            ),
          ],
        ),

        // ── FAB filter ──────────────────────────
        floatingActionButton: _FilterFab(onTap: _onFilterFab),

        // ── Bottom Nav ──────────────────────────
        bottomNavigationBar: _BottomNav(tab: _currentNav, onTap: _onNavTap),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.arrow_back, color: _C.primary, size: 24),
        ),
      ),
      title: const Text(
        'Lịch sử đặt sân',
        style: TextStyle(
          color: _C.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Icon(Icons.search, color: _C.primary, size: 24),
          // TODO: onTap → search within history
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TAB CHIP ROW
// ─────────────────────────────────────────────
class _TabChipRow extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _TabChipRow({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bgPage,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _S.pagePadH),
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = selectedIndex == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _C.chipActiveBg : _C.chipInactiveBg,
                      borderRadius: BorderRadius.circular(_S.chipRadius),
                      border: Border.all(
                        color: sel ? _C.chipActiveBg : _C.chipBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: sel ? _C.chipActiveTxt : _C.chipInactiveTxt,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOOKING CARD  — renders differently per status
// ─────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final _BookingRecord record;
  final VoidCallback onDetail;
  final VoidCallback onRebook;
  final VoidCallback onReview;
  final VoidCallback onCancelReason;

  const _BookingCard({
    required this.record,
    required this.onDetail,
    required this.onRebook,
    required this.onReview,
    required this.onCancelReason,
  });

  // ── Status badge config ───────────────────
  (String, Color, Color) get _badgeConfig {
    switch (record.status) {
      case BookingStatus.booked:
        return ('ĐÃ ĐẶT', _C.badgeBooked, _C.badgeBookedBg);
      case BookingStatus.completed:
        return ('HOÀN THÀNH', _C.badgeDone, _C.badgeDoneBg);
      case BookingStatus.cancelled:
        return ('ĐÃ HỦY', _C.badgeCancelled, _C.badgeCancelledBg);
    }
  }

  Color get _codeColor {
    switch (record.status) {
      case BookingStatus.booked:
        return _C.codeBooked;
      case BookingStatus.completed:
        return _C.codeDone;
      case BookingStatus.cancelled:
        return _C.codeCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeTextColor, badgeBgColor) = _badgeConfig;

    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            // ── Row 1: booking code + status badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÃ ĐẶT SÂN',
                      style: TextStyle(
                        color: _C.textLabel,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.code,
                      style: TextStyle(
                        color: _codeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                _StatusBadge(
                  label: badgeText,
                  textColor: badgeTextColor,
                  bgColor: badgeBgColor,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Stadium row ──────────────────────
            _StadiumRow(record: record),

            const SizedBox(height: 14),

            // ── Info box (time + payment) ────────
            _InfoBox(record: record),

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────
            _ActionButtons(
              record: record,
              onDetail: onDetail,
              onRebook: onRebook,
              onReview: onReview,
              onCancelReason: onCancelReason,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STADIUM ROW  (icon + name + address)
// ─────────────────────────────────────────────
class _StadiumRow extends StatelessWidget {
  final _BookingRecord record;
  const _StadiumRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCancelled = record.status == BookingStatus.cancelled;
    final iconBg = isCancelled
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFE8F5E9);
    final iconColor = isCancelled ? _C.textLight : _C.primary;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCancelled ? Icons.sports_soccer : Icons.sports_soccer,
            color: iconColor,
            size: 24,
            // TODO: Thay bằng Image.network(stadium.thumbnailUrl)
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.stadiumName,
                style: TextStyle(
                  color: isCancelled ? _C.textMid : _C.textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: _C.textLight,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      record.address,
                      style: const TextStyle(color: _C.textLight, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  INFO BOX  (2-column: time | payment)
// ─────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final _BookingRecord record;
  const _InfoBox({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.infoBorder, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Time column ─────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THỜI GIAN',
                      style: TextStyle(
                        color: _C.textLabel,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: _C.textMid,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          record.date,
                          style: const TextStyle(
                            color: _C.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(
                        record.timeRange,
                        style: const TextStyle(
                          color: _C.textMid,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical divider
            VerticalDivider(
              width: 1,
              color: _C.infoBorder,
              indent: 8,
              endIndent: 8,
            ),

            // ── Payment column ───────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _PaymentColumn(record: record),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PAYMENT COLUMN  (varies by status)
// ─────────────────────────────────────────────
class _PaymentColumn extends StatelessWidget {
  final _BookingRecord record;
  const _PaymentColumn({required this.record});

  @override
  Widget build(BuildContext context) {
    switch (record.status) {
      case BookingStatus.booked:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THANH TOÁN',
              style: TextStyle(
                color: _C.textLabel,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.amount,
              style: const TextStyle(
                color: _C.priceUnpaid,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Chưa thanh toán',
              style: TextStyle(color: _C.unpaidLabel, fontSize: 12),
            ),
          ],
        );

      case BookingStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THANH TOÁN',
              style: TextStyle(
                color: _C.textLabel,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.amount,
              style: const TextStyle(
                color: _C.pricePaid,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Đã thanh toán',
              style: TextStyle(
                color: _C.paidLabel,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case BookingStatus.cancelled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOÀN TIỀN',
              style: TextStyle(
                color: _C.textLabel,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            // Strikethrough price
            Text(
              record.amount,
              style: TextStyle(
                color: _C.priceRefund,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.lineThrough,
                decorationColor: _C.priceRefund,
                decorationThickness: 1.5,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Hoàn tiền 100%',
              style: TextStyle(
                color: _C.refundLabel,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────
//  ACTION BUTTONS  (varies by status)
// ─────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final _BookingRecord record;
  final VoidCallback onDetail;
  final VoidCallback onRebook;
  final VoidCallback onReview;
  final VoidCallback onCancelReason;

  const _ActionButtons({
    required this.record,
    required this.onDetail,
    required this.onRebook,
    required this.onReview,
    required this.onCancelReason,
  });

  @override
  Widget build(BuildContext context) {
    switch (record.status) {
      // ── BOOKED: Chi tiết + ··· ──────────────
      case BookingStatus.booked:
        return Row(
          children: [
            Expanded(
              child: _PrimaryBtn(label: 'Chi tiết', onTap: onDetail),
            ),
            const SizedBox(width: 10),
            _MoreBtn(),
          ],
        );

      // ── COMPLETED: Đặt lại + Đánh giá ───────
      case BookingStatus.completed:
        return Row(
          children: [
            Expanded(
              child: _OutlineBtn(label: 'Đặt lại sân này', onTap: onRebook),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineBtn(label: 'Đánh giá', onTap: onReview),
            ),
          ],
        );

      // ── CANCELLED: Xem lý do hủy ────────────
      case BookingStatus.cancelled:
        return _OutlineBtn(
          label: 'Xem lý do hủy',
          onTap: onCancelReason,
          fullWidth: true,
        );
    }
  }
}

// ── Button helpers ─────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _C.btnPrimary,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          boxShadow: [
            BoxShadow(
              color: _C.btnPrimary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          border: Border.all(color: _C.btnOutline, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _C.btnOutlineTxt,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _MoreBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _C.btnMoreBg,
        borderRadius: BorderRadius.circular(_S.btnRadius),
        border: Border.all(color: _C.btnOutline, width: 1),
      ),
      child: const Icon(Icons.more_horiz, color: _C.textMid, size: 20),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: _C.textLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có lịch sử đặt sân',
            style: TextStyle(
              color: _C.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FILTER FAB
// ─────────────────────────────────────────────
class _FilterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _S.fabSize,
        height: _S.fabSize,
        decoration: BoxDecoration(
          color: _C.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAVIGATION BAR
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.tab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: tab,
      onTap: onTap,
      selectedItemColor: _C.primary,
      unselectedItemColor: _C.navUnselected,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
