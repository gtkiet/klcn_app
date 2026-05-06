// lib/screens/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MODELS + DATA ─────────────────────────────
enum BookingStatus { booked, completed, cancelled }

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

const _allBookings = [
  _BookingRecord(
    code: '#AS-9821', stadiumName: 'Sân Arena Santiago',
    address: 'Quận 7, TP. Hồ Chí Minh', date: '20/10/2026',
    timeRange: '18:00 - 19:00', amount: '450.000đ', status: BookingStatus.booked,
  ),
  _BookingRecord(
    code: '#PN-4412', stadiumName: 'Sân cỏ nhân tạo Phú Nhuận',
    address: 'Phú Nhuận, TP. Hồ Chí Minh', date: '15/10/2026',
    timeRange: '17:00 - 18:30', amount: '520.000đ', status: BookingStatus.completed,
  ),
  _BookingRecord(
    code: '#DY-2201', stadiumName: 'Sân bóng Đại học Y Dược',
    address: 'Quận 5, TP. Hồ Chí Minh', date: '12/10/2026',
    timeRange: '19:00 - 20:00', amount: '320.000đ', status: BookingStatus.cancelled,
  ),
  _BookingRecord(
    code: '#GF-1105', stadiumName: 'Green Field Bình Thạnh',
    address: 'Bình Thạnh, TP. Hồ Chí Minh', date: '08/10/2026',
    timeRange: '16:00 - 17:30', amount: '390.000đ', status: BookingStatus.completed,
  ),
];

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
  int _currentNav  = 2;

  List<_BookingRecord> get _filtered {
    switch (_selectedTab) {
      case 1: return _allBookings.where((b) => b.status == BookingStatus.booked).toList();
      case 2: return _allBookings.where((b) => b.status == BookingStatus.completed).toList();
      case 3: return _allBookings.where((b) => b.status == BookingStatus.cancelled).toList();
      default: return _allBookings;
    }
  }

  void _onNavTap(int i) {
    setState(() => _currentNav = i);
    switch (i) {
      case 0: Navigator.pushReplacementNamed(context, '/home'); break;
      case 1: Navigator.pushReplacementNamed(context, '/fields'); break;
      case 3: Navigator.pushNamed(context, '/profile'); break;
    }
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
          title: const Text('Lịch sử đặt sân'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            // Tab chips
            _TabChipRow(
              tabs: _tabs,
              selectedIndex: _selectedTab,
              onTap: (i) => setState(() => _selectedTab = i),
            ),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          await Future.delayed(const Duration(seconds: 1)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 100),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _BookingCard(
                          record: _filtered[i],
                          onDetail: () => Navigator.pushNamed(context, '/booking_detail'),
                          onRebook: () => Navigator.pushNamed(context, '/booking_confirm'),
                          onReview: () {},
                          onCancelReason: () {},
                        ),
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: _FilterFab(
          onTap: () => Navigator.pushNamed(context, '/filter-sheet'),
        ),
        bottomNavigationBar: SpBottomNav(currentIndex: _currentNav, onTap: _onNavTap),
      ),
    );
  }
}

// ── TAB CHIP ROW ──────────────────────────────
class _TabChipRow extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _TabChipRow({required this.tabs, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPage,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final sel = selectedIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.fieldBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── BOOKING CARD ──────────────────────────────
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

  (String, Color, Color) get _badgeCfg => switch (record.status) {
    BookingStatus.booked    => ('ĐÃ ĐẶT',    AppColors.badgeBookedText, AppColors.badgeBookedBg),
    BookingStatus.completed => ('HOÀN THÀNH', AppColors.badgeDoneText,  AppColors.badgeDoneBg),
    BookingStatus.cancelled => ('ĐÃ HỦY',    AppColors.badgeCancelText, AppColors.badgeCancelBg),
  };

  Color get _codeColor => switch (record.status) {
    BookingStatus.booked    => AppColors.primary,
    BookingStatus.completed => AppColors.textDark,
    BookingStatus.cancelled => AppColors.badgeCancelText,
  };

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeTextColor, badgeBgColor) = _badgeCfg;

    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MÃ ĐẶT SÂN',
                      style: TextStyle(color: AppColors.textHint, fontSize: 10,
                          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  const SizedBox(height: 3),
                  Text(record.code,
                      style: TextStyle(color: _codeColor, fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
              SpStatusBadge(
                label: badgeText,
                textColor: badgeTextColor,
                bgColor: badgeBgColor,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stadium row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: record.status == BookingStatus.cancelled
                      ? AppColors.fieldBg
                      : AppColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_soccer,
                    color: record.status == BookingStatus.cancelled
                        ? AppColors.textLight
                        : AppColors.primary,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.stadiumName,
                        style: TextStyle(
                            color: record.status == BookingStatus.cancelled
                                ? AppColors.textMid
                                : AppColors.textDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(record.address,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info box (time + payment)
          _InfoBox(record: record),
          const SizedBox(height: 14),

          // Action buttons
          _ActionButtons(
            record: record,
            onDetail: onDetail,
            onRebook: onRebook,
            onReview: onReview,
            onCancelReason: onCancelReason,
          ),
        ],
      ),
    );
  }
}

// ── INFO BOX ──────────────────────────────────
class _InfoBox extends StatelessWidget {
  final _BookingRecord record;
  const _InfoBox({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Time column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THỜI GIAN',
                        style: TextStyle(color: AppColors.textHint, fontSize: 9.5,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMid),
                        const SizedBox(width: 5),
                        Text(record.date,
                            style: const TextStyle(color: AppColors.textDark,
                                fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(record.timeRange,
                          style: const TextStyle(color: AppColors.textMid, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ),

            VerticalDivider(width: 1, color: AppColors.fieldBorder, indent: 8, endIndent: 8),

            // Payment column
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

class _PaymentColumn extends StatelessWidget {
  final _BookingRecord record;
  const _PaymentColumn({required this.record});

  @override
  Widget build(BuildContext context) {
    switch (record.status) {
      case BookingStatus.booked:
        return _payCol('THANH TOÁN', record.amount, AppColors.primary, 'Chưa thanh toán', AppColors.textLight);
      case BookingStatus.completed:
        return _payCol('THANH TOÁN', record.amount, AppColors.textDark, 'Đã thanh toán', AppColors.primaryLight);
      case BookingStatus.cancelled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOÀN TIỀN',
                style: TextStyle(color: AppColors.textHint, fontSize: 9.5,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(record.amount,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 14, fontWeight: FontWeight.w800,
                    decoration: TextDecoration.lineThrough)),
            const SizedBox(height: 3),
            const Text('Hoàn tiền 100%',
                style: TextStyle(color: AppColors.badgeCancelText, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        );
    }
  }

  Widget _payCol(String label, String amount, Color amtColor, String sub, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 9.5,
                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text(amount, style: TextStyle(color: amtColor, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(color: subColor, fontSize: 12)),
      ],
    );
  }
}

// ── ACTION BUTTONS ────────────────────────────
class _ActionButtons extends StatelessWidget {
  final _BookingRecord record;
  final VoidCallback onDetail, onRebook, onReview, onCancelReason;

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
      case BookingStatus.booked:
        return Row(
          children: [
            Expanded(child: _PrimaryBtn(label: 'Chi tiết', onTap: onDetail)),
            const SizedBox(width: 10),
            _MoreBtn(),
          ],
        );
      case BookingStatus.completed:
        return Row(
          children: [
            Expanded(child: _OutlineBtn(label: 'Đặt lại', onTap: onRebook)),
            const SizedBox(width: 10),
            Expanded(child: _OutlineBtn(label: 'Đánh giá', onTap: onReview)),
          ],
        );
      case BookingStatus.cancelled:
        return SizedBox(
          width: double.infinity,
          child: _OutlineBtn(label: 'Xem lý do hủy', onTap: onCancelReason),
        );
    }
  }
}

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
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.fieldBorder, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: AppColors.textMid, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _MoreBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: const Icon(Icons.more_horiz, color: AppColors.textMid, size: 20),
    );
  }
}

// ── FILTER FAB ────────────────────────────────
class _FilterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: AppShadow.btn,
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined,
              size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Không có lịch sử đặt sân',
              style: TextStyle(color: AppColors.textLight, fontSize: 15)),
        ],
      ),
    );
  }
}
