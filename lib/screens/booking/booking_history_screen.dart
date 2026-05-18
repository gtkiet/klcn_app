// lib/screens/booking/booking_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// Tab filter — statusId null = Tất cả (API không truyền statusId)
// Mỗi tab truyền thẳng statusId lên API, không cần filter client-side
class _Tab {
  final String label;
  final int?   statusId;
  const _Tab(this.label, this.statusId);
}

const _tabs = [
  _Tab('Tất cả',       null),
  _Tab('Chờ đặt cọc',  5),   // PendingDeposit
  _Tab('Đã xác nhận',  2),   // Confirmed
  _Tab('Hoàn thành',   4),   // Completed
  _Tab('Đã hủy',       3),   // Cancelled
];

const _kPageSize = 10;

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _scrollCtrl = ScrollController();
  int _selectedTab  = 0;

  List<BookingSummary> _items     = [];
  bool _isLoading                 = false;
  bool _isLoadingMore             = false;
  bool _hasNextPage               = false;
  int  _currentPage               = 1;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final tab = _tabs[_selectedTab];

    if (reset) {
      setState(() {
        _isLoading   = true;
        _errorMsg    = null;
        _currentPage = 1;
        _items       = [];
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await BookingService.instance.getMyBookings(
        statusId: tab.statusId,
        page:     reset ? 1 : _currentPage,
        pageSize: _kPageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = result.items;
        } else {
          _items.addAll(result.items);
        }
        _hasNextPage   = result.hasNextPage;
        _currentPage   = result.page + 1;
        _isLoading     = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg      = e.toString();
        _isLoading     = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _load();
    }
  }

  void _onTabSelect(int i) {
    if (_selectedTab == i) return;
    setState(() => _selectedTab = i);
    _load(reset: true);
  }

  void _onTapDetail(BookingSummary booking) {
    context.push('/booking_history/detail', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(title: const Text('Lịch sử đặt sân')),
        body: Column(
          children: [
            // Tab chips
            _TabChipRow(
              tabs:          _tabs,
              selectedIndex: _selectedTab,
              onTap:         _onTabSelect,
            ),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMsg != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(_errorMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _load(reset: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Thử lại',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 64, color: AppColors.textLight.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Không có lịch sử đặt sân',
                style: TextStyle(color: AppColors.textLight, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 24,
        ),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2.5,
              )),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BookingCard(
              booking: _items[i],
              onDetail: () => _onTapDetail(_items[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── TAB CHIP ROW ──────────────────────────────
class _TabChipRow extends StatelessWidget {
  final List<_Tab> tabs;
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
                  color:  sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.fieldBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  tabs[i].label,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textDark,
                    fontSize: 13.5, fontWeight: FontWeight.w600,
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
  final BookingSummary booking;
  final VoidCallback onDetail;

  const _BookingCard({required this.booking, required this.onDetail});

  ({String text, Color textColor, Color bgColor}) get _badge => switch (booking.statusId) {
    2 => (text: 'ĐÃ XÁC NHẬN',   textColor: AppColors.badgeBookedText,  bgColor: AppColors.badgeBookedBg),
    3 => (text: 'ĐÃ HỦY',        textColor: AppColors.badgeCancelText,  bgColor: AppColors.badgeCancelBg),
    4 => (text: 'HOÀN THÀNH',    textColor: AppColors.badgeDoneText,    bgColor: AppColors.badgeDoneBg),
    5 => (text: 'CHỜ THANH TOÁN', textColor: AppColors.warningOrange,   bgColor: const Color(0xFFFFF3E0)),
    _ => (text: booking.status.toUpperCase(), textColor: AppColors.textMid, bgColor: AppColors.fieldBg),
  };

  @override
  Widget build(BuildContext context) {
    final badge = _badge;

    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: booking ID + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MÃ ĐẶT SÂN',
                      style: TextStyle(color: AppColors.textHint, fontSize: 9.5,
                          fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(
                    '#${booking.bookingId}',
                    style: TextStyle(
                      // color: booking.isBooked ? AppColors.primary : AppColors.textDark,
                      fontSize: 18, fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badge.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge.text,
                    style: TextStyle(color: badge.textColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 12),

          // Field name
          Row(
            children: [
              const Icon(Icons.sports_soccer, size: 15, color: AppColors.textLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.fieldName,
                  style: const TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Text(
                  '${booking.slotCount} slot',
                  style: const TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date + time + amount
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('THỜI GIAN',
                          style: TextStyle(color: AppColors.textHint, fontSize: 9.5,
                              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.textMid),
                          const SizedBox(width: 5),
                          Text(booking.displayDate,
                              style: const TextStyle(
                                color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Text(booking.earliestSlotTime,
                            style: const TextStyle(color: AppColors.textMid, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 1, color: AppColors.fieldBorder, indent: 4, endIndent: 4),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.isCancelled ? 'HOÀN TIỀN' : 'THANH TOÁN',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 9.5,
                              fontWeight: FontWeight.w700, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          booking.totalAmountFmt,
                          style: TextStyle(
                            color: booking.isCancelled ? AppColors.textHint : AppColors.textDark,
                            fontSize: 14, fontWeight: FontWeight.w800,
                            decoration: booking.isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Text(
                        //   booking.isBooked    ? 'Chưa thanh toán'
                        //   : booking.isCompleted ? 'Đã thanh toán'
                        //   : 'Hoàn tiền 100%',
                        //   style: TextStyle(
                        //     color: booking.isBooked    ? AppColors.textLight
                        //          : booking.isCompleted ? AppColors.primaryLight
                        //          : AppColors.badgeCancelText,
                        //     fontSize: 12,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Chi tiết',
                  icon: Icons.receipt_long_outlined,
                  onTap: onDetail,
                  primary: true,
                ),
              ),
              if (booking.isCompleted) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Đánh giá',
                    icon: Icons.star_outline_rounded,
                    onTap: () => context.push('/booking_history/detail', extra: booking),
                    primary: false,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: primary ? null : Border.all(color: AppColors.fieldBorder, width: 1.5),
          boxShadow: primary ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 8, offset: const Offset(0, 3)),
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary ? Colors.white : AppColors.textMid, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: primary ? Colors.white : AppColors.textMid,
                  fontSize: 13.5, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}